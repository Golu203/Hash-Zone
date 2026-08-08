// ─── PaymentVerification Model ────────────────────────────────────────────────
import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentVerification {
  final String id;
  final String orderId;
  final DateTime orderDate;
  final String customerName;
  final String companyName;
  final String phoneNumber;
  final String whatsAppNumber;
  final String paymentMethod;
  final double amountPaid;
  final String utrNumber;
  final String cloudinaryUrl;
  final String customerNote;
  final String shippingAddress;
  final String orderStatus;
  final String paymentStatus; // 'Pending', 'Verified', 'Rejected'
  final DateTime submittedTime;
  final DateTime? verifiedTime;
  final String? verifiedBy;
  final DateTime? rejectedTime;
  final String? rejectedBy;
  final String? rejectionReason;
  final String? adminNote;
  final String? validationResult;
  final String? ocrStatus;
  final DateTime? lastUpdated;

  const PaymentVerification({
    required this.id,
    required this.orderId,
    required this.orderDate,
    required this.customerName,
    this.companyName = '',
    required this.phoneNumber,
    this.whatsAppNumber = '',
    this.paymentMethod = 'Bank Transfer',
    required this.amountPaid,
    required this.utrNumber,
    required this.cloudinaryUrl,
    this.customerNote = '',
    this.shippingAddress = '',
    this.orderStatus = 'Payment Submitted',
    this.paymentStatus = 'Pending',
    required this.submittedTime,
    this.verifiedTime,
    this.verifiedBy,
    this.rejectedTime,
    this.rejectedBy,
    this.rejectionReason,
    this.adminNote,
    this.validationResult,
    this.ocrStatus,
    this.lastUpdated,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'orderId': orderId,
        'orderDate': Timestamp.fromDate(orderDate),
        'customerName': customerName,
        'companyName': companyName,
        'phoneNumber': phoneNumber,
        'whatsAppNumber': whatsAppNumber,
        'paymentMethod': paymentMethod,
        'amountPaid': amountPaid,
        'utrNumber': utrNumber,
        'cloudinaryUrl': cloudinaryUrl,
        'customerNote': customerNote,
        'shippingAddress': shippingAddress,
        'orderStatus': orderStatus,
        'paymentStatus': paymentStatus,
        'submittedTime': Timestamp.fromDate(submittedTime),
        'verifiedTime': verifiedTime != null ? Timestamp.fromDate(verifiedTime!) : null,
        'verifiedBy': verifiedBy,
        'rejectedTime': rejectedTime != null ? Timestamp.fromDate(rejectedTime!) : null,
        'rejectedBy': rejectedBy,
        'rejectionReason': rejectionReason,
        'adminNote': adminNote,
        'validationResult': validationResult,
        'ocrStatus': ocrStatus,
        'lastUpdated': FieldValue.serverTimestamp(),
      };

  factory PaymentVerification.fromMap(Map<String, dynamic> map, String docId) {
    return PaymentVerification(
      id: docId,
      orderId: map['orderId'] as String? ?? docId,
      orderDate: (map['orderDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      customerName: map['customerName'] as String? ?? 'Customer',
      companyName: map['companyName'] as String? ?? '',
      phoneNumber: map['phoneNumber'] as String? ?? '',
      whatsAppNumber: map['whatsAppNumber'] as String? ?? '',
      paymentMethod: map['paymentMethod'] as String? ?? 'Bank Transfer',
      amountPaid: (map['amountPaid'] as num?)?.toDouble() ?? 0.0,
      utrNumber: map['utrNumber'] as String? ?? '',
      cloudinaryUrl: map['cloudinaryUrl'] as String? ?? '',
      customerNote: map['customerNote'] as String? ?? '',
      shippingAddress: map['shippingAddress'] as String? ?? '',
      orderStatus: map['orderStatus'] as String? ?? 'Payment Submitted',
      paymentStatus: map['paymentStatus'] as String? ?? 'Pending',
      submittedTime: (map['submittedTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      verifiedTime: (map['verifiedTime'] as Timestamp?)?.toDate(),
      verifiedBy: map['verifiedBy'] as String?,
      rejectedTime: (map['rejectedTime'] as Timestamp?)?.toDate(),
      rejectedBy: map['rejectedBy'] as String?,
      rejectionReason: map['rejectionReason'] as String?,
      adminNote: map['adminNote'] as String?,
      validationResult: map['validationResult'] as String?,
      ocrStatus: map['ocrStatus'] as String?,
      lastUpdated: (map['lastUpdated'] as Timestamp?)?.toDate(),
    );
  }

  bool get isPending => paymentStatus == 'Pending';
  bool get isVerified => paymentStatus == 'Verified';
  bool get isRejected => paymentStatus == 'Rejected';
}
