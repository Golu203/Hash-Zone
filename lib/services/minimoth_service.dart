import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Service for MiniMoth Two-Factor Authentication (WhatsApp / SMS OTP)
/// Exclusively protects the HashZone Admin Panel.
class MinMothService {
  static final MinMothService _instance = MinMothService._internal();
  factory MinMothService() => _instance;
  MinMothService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // MiniMoth API Key provided for HashZone admin authentication
  static const String apiKey =
      'mm_live_e70009ba3e8e44f9fd5bef678e7e6c14194f1a23d4562c2f45a021f7387ff7875809491ef47b6b89ea2f57e60f5f8779';

  // Production Vercel serverless relay URL (contains Access-Control-Allow-Origin: *)
  static const String serverlessRelayUrl =
      'https://www.hashzone.co.in/api/minimoth-otp';

  // Default hardcoded 2FA numbers specified by the store owner
  static const List<String> defaultAuthorizedPhones = [
    '+919884875578',
    '+917676475904',
  ];

  DocumentReference<Map<String, dynamic>> get _settingsDoc =>
      _db.collection('adminSettings').doc('auth2fa');

  /// Formats a phone number for UI display showing only first 3 and last 3 digits
  /// Example: "+919884875578" -> "+91 988*****578"
  static String maskPhoneNumber(String rawPhone) {
    final clean = rawPhone.replaceAll(RegExp(r'[^\d+]'), '');
    if (clean.length < 8) return clean;

    if (clean.startsWith('+91')) {
      final national = clean.substring(3);
      if (national.length >= 6) {
        final start = national.substring(0, 3);
        final end = national.substring(national.length - 3);
        return '+91 $start*****$end';
      }
    } else if (clean.length >= 8) {
      final start = clean.substring(0, 3);
      final end = clean.substring(clean.length - 3);
      return '$start*****$end';
    }
    return clean;
  }

  /// Normalizes phone number into E.164 format (+91XXXXXXXXXX)
  static String normalizePhone(String rawPhone) {
    final digits = rawPhone.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.length == 10) {
      return '+91$digits';
    } else if (digits.length == 12 && digits.startsWith('91')) {
      return '+$digits';
    }
    return rawPhone.startsWith('+') ? rawPhone : '+$digits';
  }

  /// Retrieves the list of authorized admin 2FA phone numbers from Firestore.
  /// Falls back to the default list if not yet configured.
  Future<List<String>> getAuthorizedPhones() async {
    try {
      final doc = await _settingsDoc.get();
      if (doc.exists && doc.data() != null) {
        final list = List<String>.from(doc.data()!['phones'] ?? []);
        if (list.isNotEmpty) {
          return list;
        }
      }
    } catch (e) {
      debugPrint('[MinMothService] Could not fetch remote 2FA phones: $e');
    }
    return List<String>.from(defaultAuthorizedPhones);
  }

  /// Adds an authorized 2FA phone number to Firestore
  Future<void> addAuthorizedPhone(String newPhone) async {
    final normalized = normalizePhone(newPhone);
    final current = await getAuthorizedPhones();
    if (!current.contains(normalized)) {
      current.add(normalized);
      await _settingsDoc.set({
        'phones': current,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }

  /// Removes an authorized 2FA phone number from Firestore
  Future<void> removeAuthorizedPhone(String phoneToRemove) async {
    final normalized = normalizePhone(phoneToRemove);
    final current = await getAuthorizedPhones();
    if (current.length <= 1) {
      throw Exception('At least one authorized phone number must remain configured.');
    }
    current.remove(normalized);
    await _settingsDoc.set({
      'phones': current,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Sends an OTP via MiniMoth (WhatsApp first with SMS fallback)
  /// Dispatches via the serverless relay to prevent browser CORS fetch failures.
  Future<String> sendOtp(String phone) async {
    final normalized = normalizePhone(phone);

    // List of candidate endpoints in priority order:
    // 1. Production serverless relay (always has Access-Control-Allow-Origin: *)
    // 2. Relative API path (if accessed on the same domain)
    // 3. Direct MiniMoth API (for native mobile/desktop or if direct access is enabled)
    final candidateEndpoints = <_EndpointConfig>[
      _EndpointConfig(
        url: Uri.parse(serverlessRelayUrl),
        isRelay: true,
      ),
      if (kIsWeb)
        _EndpointConfig(
          url: Uri.parse('/api/minimoth-otp'),
          isRelay: true,
        ),
      _EndpointConfig(
        url: Uri.parse('https://api.minimoth.dev/v1/otp/send'),
        isRelay: false,
      ),
    ];

    String? lastError;
    for (final config in candidateEndpoints) {
      try {
        final headers = <String, String>{
          'Content-Type': 'application/json',
        };
        final Map<String, dynamic> body;

        if (config.isRelay) {
          body = {
            'action': 'send',
            'phone': normalized,
          };
        } else {
          headers['X-Api-Key'] = apiKey;
          body = {
            'phone': normalized,
          };
        }

        final response = await http
            .post(
              config.url,
              headers: headers,
              body: jsonEncode(body),
            )
            .timeout(const Duration(seconds: 15));

        if (response.statusCode == 200 || response.statusCode == 201) {
          final data = jsonDecode(response.body);
          return data['otp_id']?.toString() ?? 'sent';
        } else {
          try {
            final errJson = jsonDecode(response.body);
            lastError = errJson['message'] ??
                errJson['error'] ??
                'Service error: ${response.statusCode}';
          } catch (_) {
            lastError = 'Service responded with status ${response.statusCode}';
          }
          if (response.statusCode < 500) {
            throw Exception(lastError);
          }
        }
      } catch (e) {
        if (e is Exception &&
            !e.toString().contains('Failed to fetch') &&
            !e.toString().contains('ClientException')) {
          rethrow;
        }
        lastError = e.toString().replaceAll('Exception: ', '');
        debugPrint('[MinMothService] sendOtp failed on ${config.url}: $e');
      }
    }

    throw Exception(lastError ?? 'Failed to send verification code. Please try again.');
  }

  /// Verifies an OTP code via MiniMoth
  Future<bool> verifyOtp({
    required String phone,
    required String code,
  }) async {
    final normalized = normalizePhone(phone);
    final cleanCode = code.trim();

    final candidateEndpoints = <_EndpointConfig>[
      _EndpointConfig(
        url: Uri.parse(serverlessRelayUrl),
        isRelay: true,
      ),
      if (kIsWeb)
        _EndpointConfig(
          url: Uri.parse('/api/minimoth-otp'),
          isRelay: true,
        ),
      _EndpointConfig(
        url: Uri.parse('https://api.minimoth.dev/v1/otp/verify'),
        isRelay: false,
      ),
    ];

    String? lastError;
    for (final config in candidateEndpoints) {
      try {
        final headers = <String, String>{
          'Content-Type': 'application/json',
        };
        final Map<String, dynamic> body;

        if (config.isRelay) {
          body = {
            'action': 'verify',
            'phone': normalized,
            'code': cleanCode,
            'otp': cleanCode,
          };
        } else {
          headers['X-Api-Key'] = apiKey;
          body = {
            'phone': normalized,
            'code': cleanCode,
            'otp': cleanCode,
          };
        }

        final response = await http
            .post(
              config.url,
              headers: headers,
              body: jsonEncode(body),
            )
            .timeout(const Duration(seconds: 15));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          return data['valid'] == true ||
              data['access_token'] != null ||
              (data['message']?.toString().toLowerCase().contains('verified') ?? false);
        } else {
          try {
            final errJson = jsonDecode(response.body);
            lastError = errJson['message'] ??
                errJson['error'] ??
                'Incorrect security code.';
          } catch (_) {
            lastError = 'Verification failed (${response.statusCode})';
          }
          throw Exception(lastError);
        }
      } catch (e) {
        if (e is Exception &&
            !e.toString().contains('Failed to fetch') &&
            !e.toString().contains('ClientException')) {
          rethrow;
        }
        lastError = e.toString().replaceAll('Exception: ', '');
        debugPrint('[MinMothService] verifyOtp failed on ${config.url}: $e');
      }
    }

    throw Exception(lastError ?? 'Invalid or expired verification code.');
  }
}

class _EndpointConfig {
  final Uri url;
  final bool isRelay;

  const _EndpointConfig({
    required this.url,
    required this.isRelay,
  });
}
