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
  /// Uses a resilient endpoint sequence to prevent browser CORS fetch failures.
  Future<String> sendOtp(String phone) async {
    final normalized = normalizePhone(phone);

    final candidateEndpoints = <Uri>[
      // CORS bridge with Access-Control-Allow-Origin: * to prevent browser fetch blocks
      Uri.parse('https://proxy.cors.sh/https://api.minimoth.dev/v1/otp/send'),
      // Direct endpoint
      Uri.parse('https://api.minimoth.dev/v1/otp/send'),
    ];

    String? lastError;
    for (final url in candidateEndpoints) {
      try {
        final response = await http.post(
          url,
          headers: {
            'X-Api-Key': apiKey,
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'phone': normalized,
          }),
        ).timeout(const Duration(seconds: 15));

        if (response.statusCode == 200 || response.statusCode == 201) {
          final data = jsonDecode(response.body);
          return data['otp_id']?.toString() ?? 'sent';
        } else {
          try {
            final errJson = jsonDecode(response.body);
            lastError = errJson['message'] ?? errJson['error'] ?? 'Service error: ${response.statusCode}';
          } catch (_) {
            lastError = 'Service responded with status ${response.statusCode}';
          }
          if (response.statusCode < 500) {
            throw Exception(lastError);
          }
        }
      } catch (e) {
        if (e is Exception && !e.toString().contains('Failed to fetch') && !e.toString().contains('ClientException')) {
          rethrow;
        }
        lastError = e.toString().replaceAll('Exception: ', '');
        debugPrint('[MinMothService] sendOtp failed on $url: $e');
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

    final candidateEndpoints = <Uri>[
      // CORS bridge with Access-Control-Allow-Origin: * to prevent browser fetch blocks
      Uri.parse('https://proxy.cors.sh/https://api.minimoth.dev/v1/otp/verify'),
      // Direct endpoint
      Uri.parse('https://api.minimoth.dev/v1/otp/verify'),
    ];

    String? lastError;
    for (final url in candidateEndpoints) {
      try {
        final response = await http.post(
          url,
          headers: {
            'X-Api-Key': apiKey,
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'phone': normalized,
            'code': code.trim(),
            'otp': code.trim(),
          }),
        ).timeout(const Duration(seconds: 15));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          return data['valid'] == true || data['access_token'] != null;
        } else {
          try {
            final errJson = jsonDecode(response.body);
            lastError = errJson['message'] ?? errJson['error'] ?? 'Incorrect security code.';
          } catch (_) {
            lastError = 'Verification failed (${response.statusCode})';
          }
          throw Exception(lastError);
        }
      } catch (e) {
        if (e is Exception && !e.toString().contains('Failed to fetch') && !e.toString().contains('ClientException')) {
          rethrow;
        }
        lastError = e.toString().replaceAll('Exception: ', '');
        debugPrint('[MinMothService] verifyOtp failed on $url: $e');
      }
    }

    throw Exception(lastError ?? 'Invalid or expired verification code.');
  }
}
