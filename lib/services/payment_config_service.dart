// ─── PaymentConfigService ─────────────────────────────────────────────────────
// Firestore collections:
// - paymentConfiguration/default
// - paymentValidationSettings/default
// - paymentInstructions/default
// - developerSettings/default

import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentConfig {
  final String bankName;
  final String accountName;
  final String accountNumber;
  final String ifscCode;
  final String branchName;
  final String paymentInstructions;
  final bool isConfigured;
  final DateTime? lastUpdated;

  const PaymentConfig({
    this.bankName = '',
    this.accountName = '',
    this.accountNumber = '',
    this.ifscCode = '',
    this.branchName = '',
    this.paymentInstructions = '',
    this.isConfigured = false,
    this.lastUpdated,
  });

  Map<String, dynamic> toMap() => {
        'bankName': bankName,
        'accountName': accountName,
        'accountNumber': accountNumber,
        'ifscCode': ifscCode,
        'branchName': branchName,
        'paymentInstructions': paymentInstructions,
        'isConfigured': isConfigured,
        'lastUpdated': FieldValue.serverTimestamp(),
      };

  factory PaymentConfig.fromMap(Map<String, dynamic> map) {
    return PaymentConfig(
      bankName: map['bankName'] as String? ?? '',
      accountName: map['accountName'] as String? ?? '',
      accountNumber: map['accountNumber'] as String? ?? '',
      ifscCode: map['ifscCode'] as String? ?? '',
      branchName: map['branchName'] as String? ?? '',
      paymentInstructions: map['paymentInstructions'] as String? ?? '',
      isConfigured: map['isConfigured'] as bool? ?? false,
      lastUpdated: (map['lastUpdated'] as Timestamp?)?.toDate(),
    );
  }

  bool get hasBankDetails =>
      bankName.isNotEmpty && accountNumber.isNotEmpty && ifscCode.isNotEmpty;
}

class PaymentConfigService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> get _ref =>
      _db.collection('paymentConfiguration').doc('default');

  DocumentReference<Map<String, dynamic>> get _validationRef =>
      _db.collection('paymentValidationSettings').doc('default');

  DocumentReference<Map<String, dynamic>> get _instructionsRef =>
      _db.collection('paymentInstructions').doc('default');

  DocumentReference<Map<String, dynamic>> get _devRef =>
      _db.collection('developerSettings').doc('default');

  Stream<PaymentConfig> streamConfig() {
    return _ref.snapshots().map((snap) {
      if (!snap.exists || snap.data() == null) return const PaymentConfig();
      return PaymentConfig.fromMap(snap.data()!);
    });
  }

  Future<PaymentConfig> getConfig() async {
    final snap = await _ref.get();
    if (!snap.exists || snap.data() == null) return const PaymentConfig();
    return PaymentConfig.fromMap(snap.data()!);
  }

  Future<void> saveConfig(PaymentConfig config) async {
    await _ref.set(config.toMap(), SetOptions(merge: true));

    // Also update sub-documents for future scalability
    await _instructionsRef.set({
      'instructions': config.paymentInstructions,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await _validationRef.set({
      'enabled': true,
      'requireOcr': true,
      'allowedFormats': ['jpg', 'jpeg', 'png', 'webp'],
      'maxSizeBytes': 10485760,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await _devRef.set({
      'version': '1.0.0',
      'lastConfiguredAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> seedIfAbsent() async {
    final snap = await _ref.get();
    if (snap.exists) return;
    await saveConfig(const PaymentConfig());
  }
}
