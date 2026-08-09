import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Isolated Service for Backblaze B2 Invoice PDF Storage & Access.
/// Handles ONLY Admin Invoice PDFs. Does NOT touch Cloudinary or other assets.
class B2InvoiceService {
  static const String endpoint = 's3.us-east-005.backblazeb2.com';
  static const String region = 'us-east-005';
  static const String bucketName = 'hashzone-invoice-pdfs';
  static const String keyId = '00511c00e3935300000000001';
  static const String applicationKey = 'K005Ocxkes/eNHdnh79CLzs5um+zRQg';

  // ── AWS SIGV4 HELPER METHODS ─────────────────────────────────────────────
  Digest _hmacSha256(List<int> key, String data) {
    final hmac = Hmac(sha256, key);
    return hmac.convert(utf8.encode(data));
  }

  String _sha256Hex(dynamic data) {
    if (data is List<int>) {
      return sha256.convert(data).toString();
    }
    return sha256.convert(utf8.encode(data.toString())).toString();
  }

  List<int> _getSigningKey(String secretKey, String dateStamp, String regionName, String serviceName) {
    final kDate = _hmacSha256(utf8.encode('AWS4$secretKey'), dateStamp).bytes;
    final kRegion = _hmacSha256(kDate, regionName).bytes;
    final kService = _hmacSha256(kRegion, serviceName).bytes;
    final kSigning = _hmacSha256(kService, 'aws4_request').bytes;
    return kSigning;
  }

  // ── GENERATE PRESIGNED GET URL ───────────────────────────────────────────
  /// Generates a temporary 1-hour presigned GET URL for private Backblaze B2 PDF access.
  String generatePresignedGetUrl(String objectKey, {int expiresInSeconds = 3600}) {
    // If it's a legacy Cloudinary URL or direct HTTP URL, return as-is
    if (objectKey.startsWith('http://') || objectKey.startsWith('https://') || objectKey.contains('cloudinary.com')) {
      if (objectKey.contains('/image/upload/')) {
        return objectKey.replaceFirst('/image/upload/', '/raw/upload/');
      }
      return objectKey;
    }

    final cleanKey = objectKey.startsWith('/') ? objectKey.substring(1) : objectKey;
    final now = DateTime.now().toUtc();
    final amzDate = '${now.year.toString().padLeft(4, '0')}'
        '${now.month.toString().padLeft(2, '0')}'
        '${now.day.toString().padLeft(2, '0')}T'
        '${now.hour.toString().padLeft(2, '0')}'
        '${now.minute.toString().padLeft(2, '0')}'
        '${now.second.toString().padLeft(2, '0')}Z';
    final dateStamp = amzDate.substring(0, 8);

    final credentialScope = '$dateStamp/$region/s3/aws4_request';
    final canonicalUri = '/$bucketName/${cleanKey.split('/').map(Uri.encodeComponent).join('/')}';

    final queryParams = <String, String>{
      'X-Amz-Algorithm': 'AWS4-HMAC-SHA256',
      'X-Amz-Credential': '$keyId/$credentialScope',
      'X-Amz-Date': amzDate,
      'X-Amz-Expires': expiresInSeconds.toString(),
      'X-Amz-SignedHeaders': 'host',
    };

    final sortedKeys = queryParams.keys.toList()..sort();
    final canonicalQuery = sortedKeys.map((k) => '${Uri.encodeComponent(k)}=${Uri.encodeComponent(queryParams[k]!)}').join('&');

    const canonicalHeaders = 'host:$endpoint\n';
    const signedHeaders = 'host';
    const payloadHash = 'UNSIGNED-PAYLOAD';

    final canonicalRequest = 'GET\n$canonicalUri\n$canonicalQuery\n$canonicalHeaders\n$signedHeaders\n$payloadHash';
    final stringToSign = 'AWS4-HMAC-SHA256\n$amzDate\n$credentialScope\n${_sha256Hex(canonicalRequest)}';

    final signingKey = _getSigningKey(applicationKey, dateStamp, region, 's3');
    final signature = _hmacSha256(signingKey, stringToSign).toString();

    return 'https://$endpoint$canonicalUri?$canonicalQuery&X-Amz-Signature=$signature';
  }

  // ── UPLOAD INVOICE PDF TO BACKBLAZE B2 ──────────────────────────────────
  /// Validates PDF format and uploads file bytes to Backblaze B2 under invoices/{orderId}/{filename}.
  Future<Map<String, dynamic>> uploadInvoice({
    required Uint8List bytes,
    required String filename,
    required String orderId,
  }) async {
    // 1. Validation A: File Extension
    if (!filename.toLowerCase().endsWith('.pdf')) {
      throw Exception('Invalid File Format: Only official PDF documents (.pdf) are allowed as invoices.');
    }

    // 2. Validation B: MIME / Content Signature (%PDF-)
    if (bytes.length < 5) {
      throw Exception('Invalid PDF Content: File is corrupted or empty.');
    }
    final pdfMagicHeader = String.fromCharCodes(bytes.sublist(0, 5));
    if (pdfMagicHeader != '%PDF-') {
      throw Exception('Invalid PDF Content: Selected file is not a valid PDF document (magic header mismatch).');
    }

    final cleanFilename = filename.replaceAll(RegExp(r'[^a-zA-Z0-9_\.\-]'), '_');
    final objectKey = 'invoices/$orderId/$cleanFilename';

    // Try serverless API first, fallback to direct SigV4 S3 upload
    try {
      final apiUri = Uri.parse('/api/b2-invoice');
      final res = await http.post(
        apiUri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'action': 'upload',
          'orderId': orderId,
          'fileName': cleanFilename,
          'fileBase64': base64Encode(bytes),
        }),
      ).timeout(const Duration(seconds: 15));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        return {
          'available': true,
          'provider': 'backblaze_b2',
          'bucket': data['bucket'] ?? bucketName,
          'objectKey': data['objectKey'] ?? objectKey,
          'fileName': data['fileName'] ?? cleanFilename,
          'contentType': 'application/pdf',
          'uploadedAt': data['uploadedAt'] ?? DateTime.now().toIso8601String(),
        };
      }
    } catch (e) {
      debugPrint('Serverless API endpoint unavailable, proceeding with direct B2 S3 upload: $e');
    }

    // Direct SigV4 S3 PUT Upload to Backblaze B2
    final now = DateTime.now().toUtc();
    final amzDate = '${now.year.toString().padLeft(4, '0')}'
        '${now.month.toString().padLeft(2, '0')}'
        '${now.day.toString().padLeft(2, '0')}T'
        '${now.hour.toString().padLeft(2, '0')}'
        '${now.minute.toString().padLeft(2, '0')}'
        '${now.second.toString().padLeft(2, '0')}Z';
    final dateStamp = amzDate.substring(0, 8);

    final payloadHash = _sha256Hex(bytes);
    final canonicalUri = '/$bucketName/${objectKey.split('/').map(Uri.encodeComponent).join('/')}';
    const canonicalQuery = '';
    final canonicalHeaders = 'host:$endpoint\nx-amz-content-sha256:$payloadHash\nx-amz-date:$amzDate\n';
    const signedHeaders = 'host;x-amz-content-sha256;x-amz-date';

    final canonicalRequest = 'PUT\n$canonicalUri\n$canonicalQuery\n$canonicalHeaders\n$signedHeaders\n$payloadHash';
    final credentialScope = '$dateStamp/$region/s3/aws4_request';
    final stringToSign = 'AWS4-HMAC-SHA256\n$amzDate\n$credentialScope\n${_sha256Hex(canonicalRequest)}';

    final signingKey = _getSigningKey(applicationKey, dateStamp, region, 's3');
    final signature = _hmacSha256(signingKey, stringToSign).toString();
    final authHeader = 'AWS4-HMAC-SHA256 Credential=$keyId/$credentialScope, SignedHeaders=$signedHeaders, Signature=$signature';

    final uploadUri = Uri.parse('https://$endpoint$canonicalUri');
    final response = await http.put(
      uploadUri,
      headers: {
        'Host': endpoint,
        'Content-Type': 'application/pdf',
        'Content-Length': bytes.length.toString(),
        'x-amz-date': amzDate,
        'x-amz-content-sha256': payloadHash,
        'Authorization': authHeader,
      },
      body: bytes,
    ).timeout(const Duration(seconds: 40));

    if (response.statusCode == 200 || response.statusCode == 201) {
      return {
        'available': true,
        'provider': 'backblaze_b2',
        'bucket': bucketName,
        'objectKey': objectKey,
        'fileName': cleanFilename,
        'contentType': 'application/pdf',
        'uploadedAt': DateTime.now().toIso8601String(),
      };
    } else {
      throw Exception('Backblaze B2 Upload Failed [Status ${response.statusCode}]: ${response.body}');
    }
  }

  // ── DELETE INVOICE PDF FROM BACKBLAZE B2 ────────────────────────────────
  /// Safely deletes the specified invoice object from Backblaze B2.
  Future<void> deleteInvoice(String objectKey) async {
    if (objectKey.isEmpty || objectKey.startsWith('http://') || objectKey.startsWith('https://')) {
      // Do not touch legacy Cloudinary or invalid URLs
      return;
    }

    final cleanKey = objectKey.startsWith('/') ? objectKey.substring(1) : objectKey;

    try {
      final now = DateTime.now().toUtc();
      final amzDate = '${now.year.toString().padLeft(4, '0')}'
          '${now.month.toString().padLeft(2, '0')}'
          '${now.day.toString().padLeft(2, '0')}T'
          '${now.hour.toString().padLeft(2, '0')}'
          '${now.minute.toString().padLeft(2, '0')}'
          '${now.second.toString().padLeft(2, '0')}Z';
      final dateStamp = amzDate.substring(0, 8);

      final payloadHash = _sha256Hex('');
      final canonicalUri = '/$bucketName/${cleanKey.split('/').map(Uri.encodeComponent).join('/')}';
      const canonicalQuery = '';
      final canonicalHeaders = 'host:$endpoint\nx-amz-content-sha256:$payloadHash\nx-amz-date:$amzDate\n';
      const signedHeaders = 'host;x-amz-content-sha256;x-amz-date';

      final canonicalRequest = 'DELETE\n$canonicalUri\n$canonicalQuery\n$canonicalHeaders\n$signedHeaders\n$payloadHash';
      final credentialScope = '$dateStamp/$region/s3/aws4_request';
      final stringToSign = 'AWS4-HMAC-SHA256\n$amzDate\n$credentialScope\n${_sha256Hex(canonicalRequest)}';

      final signingKey = _getSigningKey(applicationKey, dateStamp, region, 's3');
      final signature = _hmacSha256(signingKey, stringToSign).toString();
      final authHeader = 'AWS4-HMAC-SHA256 Credential=$keyId/$credentialScope, SignedHeaders=$signedHeaders, Signature=$signature';

      final deleteUri = Uri.parse('https://$endpoint$canonicalUri');
      await http.delete(
        deleteUri,
        headers: {
          'Host': endpoint,
          'x-amz-date': amzDate,
          'x-amz-content-sha256': payloadHash,
          'Authorization': authHeader,
        },
      ).timeout(const Duration(seconds: 15));
    } catch (e) {
      debugPrint('Non-critical B2 deletion warning: $e');
    }
  }
}
