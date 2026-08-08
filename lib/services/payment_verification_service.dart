// ─── PaymentVerificationService ──────────────────────────────────────────────
// Firestore collections: paymentVerification & paymentAudit
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/payment_verification.dart';

class PaymentVerificationService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _db.collection('paymentVerification');

  CollectionReference<Map<String, dynamic>> get _auditCollection =>
      _db.collection('paymentAudit');

  /// Streams all payment verification records ordered by submitted time descending
  Stream<List<PaymentVerification>> streamVerifications() {
    return _collection
        .orderBy('submittedTime', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => PaymentVerification.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Creates a new payment verification submission entry and logs audit event
  Future<String> submitVerification(PaymentVerification item) async {
    final docRef = _collection.doc(item.id.isNotEmpty ? item.id : null);
    final data = item.toMap();
    await docRef.set(data, SetOptions(merge: true));

    // Audit log
    await _auditCollection.add({
      'verificationId': docRef.id,
      'orderId': item.orderId,
      'action': 'SUBMITTED',
      'utrNumber': item.utrNumber,
      'cloudinaryUrl': item.cloudinaryUrl,
      'ocrStatus': item.ocrStatus ?? 'OCR Verified',
      'timestamp': FieldValue.serverTimestamp(),
    });

    return docRef.id;
  }

  /// Approves a payment verification record
  Future<void> approvePayment({
    required String id,
    required String adminUser,
  }) async {
    final now = DateTime.now();
    await _collection.doc(id).update({
      'paymentStatus': 'Verified',
      'orderStatus': 'Confirmed & Processing',
      'verifiedBy': adminUser,
      'verifiedTime': Timestamp.fromDate(now),
      'lastUpdated': FieldValue.serverTimestamp(),
    });

    // Permanent Audit Trail Record
    await _auditCollection.add({
      'verificationId': id,
      'action': 'APPROVED',
      'verifiedBy': adminUser,
      'verifiedTime': Timestamp.fromDate(now),
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  /// Rejects a payment verification record with reason and admin note
  Future<void> rejectPayment({
    required String id,
    required String reason,
    String? adminNote,
    required String adminUser,
  }) async {
    final now = DateTime.now();
    await _collection.doc(id).update({
      'paymentStatus': 'Rejected',
      'orderStatus': 'Payment Rejected',
      'rejectedBy': adminUser,
      'rejectedTime': Timestamp.fromDate(now),
      'rejectionReason': reason,
      'adminNote': adminNote ?? '',
      'lastUpdated': FieldValue.serverTimestamp(),
    });

    // Permanent Audit Trail Record
    await _auditCollection.add({
      'verificationId': id,
      'action': 'REJECTED',
      'rejectedBy': adminUser,
      'rejectedTime': Timestamp.fromDate(now),
      'rejectionReason': reason,
      'adminNote': adminNote ?? '',
      'timestamp': FieldValue.serverTimestamp(),
    });
  }
}
