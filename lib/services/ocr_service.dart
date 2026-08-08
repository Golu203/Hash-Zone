// ─── OcrService ─────────────────────────────────────────────────────────────
// Browser-side OCR Validation Service using Tesseract.js via Modern JS Interop.
// NO paid APIs. NO AI APIs. NO server OCR.

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'developer_testing_service.dart';
import 'dart:js_interop';
import 'package:cloud_firestore/cloud_firestore.dart';

@JS('performOcrOnImage')
external void _performOcrOnImage(JSString base64Url, JSFunction callback);

class OcrValidationResult {
  final bool isValid;
  final String? errorMessage;
  final String? extractedText;
  final List<String> detectedKeywords;

  const OcrValidationResult({
    required this.isValid,
    this.errorMessage,
    this.extractedText,
    this.detectedKeywords = const [],
  });
}

class OcrService {
  static const List<String> defaultKeywords = [
    'TRANSACTION REFERENCE',
    'REFERENCE NUMBER',
    'BANK REFERENCE',
    'UTR',
    'TRANSACTION SUCCESSFUL',
    'TRANSFER COMPLETED',
    'SUCCESS',
    'COMPLETED',
    'AMOUNT',
    'BANK',
    'DATE',
    'TIME',
    'NEFT',
    'RTGS',
    'IMPS',
    'TRANSFER',
    'HASH ZONE',
  ];

  static const List<String> allowedExtensions = ['jpg', 'jpeg', 'png', 'webp'];
  static const int maxFileSizeBytes = 10 * 1024 * 1024; // 10 MB

  /// Validates a screenshot file and UTR string using browser-side Tesseract.js
  static Future<OcrValidationResult> validateScreenshot({
    required Uint8List bytes,
    required String filename,
    required String enteredUtr,
    List<String> customKeywords = const [],
  }) async {
    // 1. Validate File Extension
    final ext = _getExtension(filename);
    if (!allowedExtensions.contains(ext)) {
      return const OcrValidationResult(
        isValid: false,
        errorMessage: 'Please upload a payment screenshot in JPG, JPEG, PNG or WEBP format.',
      );
    }

    // 2. Validate File Size
    if (bytes.lengthInBytes > maxFileSizeBytes) {
      return const OcrValidationResult(
        isValid: false,
        errorMessage: 'File size exceeds 10MB. Please upload a smaller payment screenshot.',
      );
    }

    // 3. Validate Image Bytes Integrity
    if (bytes.isEmpty || bytes.lengthInBytes < 500) {
      return const OcrValidationResult(
        isValid: false,
        errorMessage: 'The uploaded image is not clear enough. Please upload a clearer payment confirmation screenshot.',
      );
    }

    // 4. Validate UTR input non-empty
    final cleanEnteredUtr = enteredUtr.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toUpperCase();
    if (cleanEnteredUtr.isEmpty || cleanEnteredUtr.length < 6) {
      return const OcrValidationResult(
        isValid: false,
        errorMessage: 'Please enter a valid Transaction ID / UTR before uploading.',
      );
    }

    // 4b. Check if Developer OCR Test Mode is ON (bypasses OCR scan completely for testing)
    final bool isTestMode = await DeveloperTestingService().isOcrTestModeEnabled();
    if (isTestMode) {
      return const OcrValidationResult(
        isValid: true,
        extractedText: 'OCR Test Mode Bypass Active',
      );
    }

    // If not running in Flutter Web, pass-through with basic validation
    if (!kIsWeb) {
      return const OcrValidationResult(
        isValid: true,
        extractedText: 'Non-web platform skip OCR pass',
      );
    }

    // 5. Convert Image Bytes to Data URL
    final mimeType = ext == 'png'
        ? 'image/png'
        : ext == 'webp'
            ? 'image/webp'
            : 'image/jpeg';
    final base64String = base64Encode(bytes);
    final dataUrl = 'data:$mimeType;base64,$base64String';

    // 6. Execute Tesseract.js recognition via JS interop
    String extractedText = '';
    try {
      final completer = Completer<String>();

      final jsCallback = ((JSString? error, JSString? text) {
        final errStr = error?.toDart;
        final textStr = text?.toDart;
        if (errStr != null && errStr.isNotEmpty) {
          if (!completer.isCompleted) completer.completeError(errStr);
        } else {
          if (!completer.isCompleted) completer.complete(textStr ?? '');
        }
      }).toJS;

      _performOcrOnImage(dataUrl.toJS, jsCallback);

      extractedText = await completer.future.timeout(
        const Duration(seconds: 25),
        onTimeout: () => throw TimeoutException('OCR scanning timed out'),
      );
    } catch (e) {
      return const OcrValidationResult(
        isValid: false,
        errorMessage: "We couldn't detect payment details in the uploaded image. Please upload a clear payment confirmation screenshot.",
      );
    }

    final uppercaseExtracted = extractedText.toUpperCase();

    // 7. Search Payment Keywords
    List<String> keywordsToSearch = [...defaultKeywords];
    try {
      final snap = await FirebaseFirestore.instance.collection('paymentValidationSettings').doc('default').get();
      if (snap.exists && snap.data() != null) {
        final list = snap.data()!['ocrKeywords'] as List?;
        if (list != null && list.isNotEmpty) {
          keywordsToSearch = list.map((k) => k.toString().toUpperCase()).toList();
        }
      }
    } catch (_) {}

    if (customKeywords.isNotEmpty) {
      keywordsToSearch.addAll(customKeywords.map((k) => k.toUpperCase()));
    }
    final foundKeywords = keywordsToSearch
        .where((kw) => uppercaseExtracted.contains(kw))
        .toList();

    if (foundKeywords.isEmpty) {
      return const OcrValidationResult(
        isValid: false,
        errorMessage: "We couldn't detect payment details in the uploaded image. Please upload a clear payment confirmation screenshot.",
      );
    }

    // 8. Search and Match UTR
    final cleanExtractedText = uppercaseExtracted.replaceAll(RegExp(r'[^A-Z0-9]'), '');
    final bool utrMatched = cleanExtractedText.contains(cleanEnteredUtr) ||
        uppercaseExtracted.contains(enteredUtr.trim().toUpperCase());

    if (!utrMatched) {
      return const OcrValidationResult(
        isValid: false,
        errorMessage: "The Transaction ID entered could not be matched with the uploaded payment screenshot. Please verify and try again.",
      );
    }

    // 9. Validation Success
    return OcrValidationResult(
      isValid: true,
      extractedText: extractedText,
      detectedKeywords: foundKeywords,
    );
  }

  static String _getExtension(String filename) {
    final parts = filename.split('.');
    if (parts.length < 2) return '';
    return parts.last.toLowerCase().trim();
  }
}
