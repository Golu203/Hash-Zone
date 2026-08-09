// ─── CustomerOrder Models ───────────────────────────────────────────────────
import 'package:cloud_firestore/cloud_firestore.dart';

class OrderProductItem {
  final String productId;
  final String title;
  final String imageUrl;
  final String sku;
  final String internalProductCode;
  final String size;
  final int quantity;
  final double unitPrice;
  final double lineTotal;

  const OrderProductItem({
    required this.productId,
    required this.title,
    required this.imageUrl,
    required this.sku,
    this.internalProductCode = '',
    required this.size,
    required this.quantity,
    required this.unitPrice,
    required this.lineTotal,
  });

  Map<String, dynamic> toMap() => {
        'productId': productId,
        'title': title,
        'imageUrl': imageUrl,
        'sku': sku,
        'internalProductCode': internalProductCode,
        'size': size,
        'quantity': quantity,
        'unitPrice': unitPrice,
        'lineTotal': lineTotal,
      };

  factory OrderProductItem.fromMap(Map<String, dynamic> map) {
    return OrderProductItem(
      productId: map['productId'] as String? ?? '',
      title: map['title'] as String? ?? 'Product',
      imageUrl: map['imageUrl'] as String? ?? '',
      sku: map['sku'] as String? ?? '',
      internalProductCode: map['internalProductCode'] as String? ?? '',
      size: map['size'] as String? ?? 'Free Size',
      quantity: (map['quantity'] as num?)?.toInt() ?? 1,
      unitPrice: (map['unitPrice'] as num?)?.toDouble() ?? 0.0,
      lineTotal: (map['lineTotal'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class OrderShippingAddress {
  final String doorNumber;
  final String road;
  final String area;
  final String city;
  final String state;
  final String pincode;
  final String landmark;

  const OrderShippingAddress({
    this.doorNumber = '',
    this.road = '',
    this.area = '',
    this.city = '',
    this.state = '',
    this.pincode = '',
    this.landmark = '',
  });

  String get fullAddress {
    final doorStr = doorNumber.trim();
    final roadStr = road.trim();
    final areaStr = area.trim();
    final cityStr = city.trim();
    final stateStr = state.trim();
    final pinStr = pincode.trim();
    var lmStr = landmark.trim();

    if (lmStr.isNotEmpty) {
      lmStr = lmStr.replaceAll(RegExp(r'\bNear\s+Near\b', caseSensitive: false), 'Near').trim();
    }

    final parts = <String>[];
    if (doorStr.isNotEmpty) parts.add(doorStr);
    if (roadStr.isNotEmpty) parts.add(roadStr);
    if (areaStr.isNotEmpty) parts.add(areaStr);
    if (cityStr.isNotEmpty) parts.add(cityStr);

    if (stateStr.isNotEmpty && pinStr.isNotEmpty) {
      parts.add('$stateStr - $pinStr');
    } else {
      if (stateStr.isNotEmpty) parts.add(stateStr);
      if (pinStr.isNotEmpty) parts.add(pinStr);
    }

    if (lmStr.isNotEmpty) {
      if (RegExp(r'^(near|opp|opposite|behind|beside)\b', caseSensitive: false).hasMatch(lmStr)) {
        parts.add(lmStr);
      } else {
        parts.add('Near $lmStr');
      }
    }

    if (parts.isEmpty) return 'No delivery address provided.';
    return parts.join(', ');
  }

  Map<String, dynamic> toMap() => {
        'doorNumber': doorNumber,
        'road': road,
        'area': area,
        'city': city,
        'state': state,
        'pincode': pincode,
        'landmark': landmark,
      };

  factory OrderShippingAddress.fromMap(Map<String, dynamic> map) {
    return OrderShippingAddress(
      doorNumber: map['doorNumber'] as String? ??
          map['doorNo'] as String? ??
          map['flatNo'] as String? ??
          map['houseNo'] as String? ??
          map['building'] as String? ??
          '',
      road: map['road'] as String? ??
          map['street'] as String? ??
          map['addressLine1'] as String? ??
          '',
      area: map['area'] as String? ??
          map['locality'] as String? ??
          map['addressLine2'] as String? ??
          '',
      city: map['city'] as String? ??
          map['town'] as String? ??
          '',
      state: map['state'] as String? ??
          map['region'] as String? ??
          '',
      pincode: map['pincode'] as String? ??
          map['zipCode'] as String? ??
          map['postalCode'] as String? ??
          map['pin'] as String? ??
          '',
      landmark: map['landmark'] as String? ??
          map['nearby'] as String? ??
          '',
    );
  }

  factory OrderShippingAddress.fromRawString(String raw) {
    if (raw.trim().isEmpty) return const OrderShippingAddress();
    final cleaned = raw.replaceAll(RegExp(r'\bNear\s+Near\b', caseSensitive: false), 'Near').trim();
    return OrderShippingAddress(road: cleaned);
  }
}

class OrderPaymentInfo {
  final String method;
  final double amountPaid;
  final String utrNumber;
  final String paymentStatus; // 'Pending', 'Verified', 'Rejected'
  final String cloudinaryScreenshotUrl;

  const OrderPaymentInfo({
    this.method = 'Bank Transfer',
    required this.amountPaid,
    required this.utrNumber,
    this.paymentStatus = 'Pending',
    this.cloudinaryScreenshotUrl = '',
  });

  Map<String, dynamic> toMap() => {
        'method': method,
        'amountPaid': amountPaid,
        'utrNumber': utrNumber,
        'paymentStatus': paymentStatus,
        'cloudinaryScreenshotUrl': cloudinaryScreenshotUrl,
      };

  factory OrderPaymentInfo.fromMap(Map<String, dynamic> map) {
    return OrderPaymentInfo(
      method: map['method'] as String? ?? 'Bank Transfer',
      amountPaid: (map['amountPaid'] as num?)?.toDouble() ?? 0.0,
      utrNumber: map['utrNumber'] as String? ?? '',
      paymentStatus: map['paymentStatus'] as String? ?? 'Pending',
      cloudinaryScreenshotUrl: map['cloudinaryScreenshotUrl'] as String? ?? '',
    );
  }
}

class OrderTimelineStage {
  final String stageName; // 'Order Received', 'Order Confirmed', 'Dispatched'
  final bool isCompleted;
  final DateTime? timestamp;

  const OrderTimelineStage({
    required this.stageName,
    required this.isCompleted,
    this.timestamp,
  });

  Map<String, dynamic> toMap() => {
        'stageName': stageName,
        'isCompleted': isCompleted,
        'timestamp': timestamp != null ? Timestamp.fromDate(timestamp!) : null,
      };

  factory OrderTimelineStage.fromMap(Map<String, dynamic> map) {
    return OrderTimelineStage(
      stageName: map['stageName'] as String? ?? '',
      isCompleted: map['isCompleted'] as bool? ?? false,
      timestamp: (map['timestamp'] as Timestamp?)?.toDate(),
    );
  }
}

class OrderDispatchInfo {
  final String courierCompany;
  final String awbNumber;
  final String trackingUrl;
  final String additionalNote;
  final String dispatchedBy;
  final DateTime? dispatchedTime;

  const OrderDispatchInfo({
    this.courierCompany = '',
    this.awbNumber = '',
    this.trackingUrl = '',
    this.additionalNote = '',
    this.dispatchedBy = '',
    this.dispatchedTime,
  });

  Map<String, dynamic> toMap() => {
        'courierCompany': courierCompany,
        'awbNumber': awbNumber,
        'trackingUrl': trackingUrl,
        'additionalNote': additionalNote,
        'dispatchedBy': dispatchedBy,
        'dispatchedTime': dispatchedTime != null ? Timestamp.fromDate(dispatchedTime!) : null,
      };

  factory OrderDispatchInfo.fromMap(Map<String, dynamic> map) {
    return OrderDispatchInfo(
      courierCompany: map['courierCompany'] as String? ?? '',
      awbNumber: map['awbNumber'] as String? ?? '',
      trackingUrl: map['trackingUrl'] as String? ?? '',
      additionalNote: map['additionalNote'] as String? ?? '',
      dispatchedBy: map['dispatchedBy'] as String? ?? '',
      dispatchedTime: (map['dispatchedTime'] as Timestamp?)?.toDate(),
    );
  }
}

class OrderRefundInfo {
  final bool refundRequired;
  final String refundTimeline;
  final String reason;
  final String adminNote;
  final String rejectedBy;
  final DateTime? rejectedTime;

  const OrderRefundInfo({
    this.refundRequired = false,
    this.refundTimeline = '',
    required this.reason,
    this.adminNote = '',
    this.rejectedBy = '',
    this.rejectedTime,
  });

  Map<String, dynamic> toMap() => {
        'refundRequired': refundRequired,
        'refundTimeline': refundTimeline,
        'reason': reason,
        'adminNote': adminNote,
        'rejectedBy': rejectedBy,
        'rejectedTime': rejectedTime != null ? Timestamp.fromDate(rejectedTime!) : null,
      };

  factory OrderRefundInfo.fromMap(Map<String, dynamic> map) {
    return OrderRefundInfo(
      refundRequired: map['refundRequired'] as bool? ?? false,
      refundTimeline: map['refundTimeline'] as String? ?? '',
      reason: map['reason'] as String? ?? '',
      adminNote: map['adminNote'] as String? ?? '',
      rejectedBy: map['rejectedBy'] as String? ?? '',
      rejectedTime: (map['rejectedTime'] as Timestamp?)?.toDate(),
    );
  }
}

class CustomerOrder {
  final String id;
  final String customerId;
  final String customerName;
  final String companyName;
  final String phoneNumber;
  final String whatsAppNumber;
  final String email;
  final DateTime orderDate;
  final String status; // 'Pending Payment', 'Order Received', 'Confirmed', 'Dispatched', 'Rejected'
  final OrderShippingAddress shippingAddress;
  final String customerNote;
  final OrderPaymentInfo paymentInfo;
  final List<OrderProductItem> items;
  final double subtotal;
  final double shippingCharge;
  final double pendingAmount;
  final double grandTotal;
  final List<OrderTimelineStage> timeline;
  final OrderDispatchInfo? dispatchInfo;
  final OrderRefundInfo? refundInfo;
  final String? receiptUrl;
  final String? receiptNumber;
  final String? invoiceUrl;
  final DateTime? lastUpdated;

  const CustomerOrder({
    required this.id,
    required this.customerId,
    required this.customerName,
    this.companyName = '',
    required this.phoneNumber,
    this.whatsAppNumber = '',
    this.email = '',
    required this.orderDate,
    this.status = 'Order Received',
    required this.shippingAddress,
    this.customerNote = '',
    required this.paymentInfo,
    required this.items,
    required this.subtotal,
    this.shippingCharge = 0.0,
    this.pendingAmount = 0.0,
    required this.grandTotal,
    required this.timeline,
    this.dispatchInfo,
    this.refundInfo,
    this.receiptUrl,
    this.receiptNumber,
    this.invoiceUrl,
    this.lastUpdated,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'customerId': customerId,
        'customerName': customerName,
        'companyName': companyName,
        'phoneNumber': phoneNumber,
        'whatsAppNumber': whatsAppNumber,
        'email': email,
        'orderDate': Timestamp.fromDate(orderDate),
        'status': status,
        'shippingAddress': shippingAddress.toMap(),
        'customerNote': customerNote,
        'paymentInfo': paymentInfo.toMap(),
        'items': items.map((i) => i.toMap()).toList(),
        'subtotal': subtotal,
        'shippingCharge': shippingCharge,
        'pendingAmount': pendingAmount,
        'grandTotal': grandTotal,
        'timeline': timeline.map((t) => t.toMap()).toList(),
        'dispatchInfo': dispatchInfo?.toMap(),
        'refundInfo': refundInfo?.toMap(),
        'receiptUrl': receiptUrl,
        'receiptNumber': receiptNumber,
        'invoiceUrl': invoiceUrl,
        'lastUpdated': FieldValue.serverTimestamp(),
      };

  factory CustomerOrder.fromMap(Map<String, dynamic> map, String docId) {
    final rawItems = map['items'] as List<dynamic>? ?? [];
    final rawTimeline = map['timeline'] as List<dynamic>? ?? [];

    return CustomerOrder(
      id: docId,
      customerId: map['customerId'] as String? ?? '',
      customerName: map['customerName'] as String? ?? 'Customer',
      companyName: map['companyName'] as String? ?? '',
      phoneNumber: map['phoneNumber'] as String? ?? '',
      whatsAppNumber: map['whatsAppNumber'] as String? ?? '',
      email: map['email'] as String? ?? '',
      orderDate: (map['orderDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: map['status'] as String? ?? 'Order Received',
      shippingAddress: map['shippingAddress'] != null
          ? (map['shippingAddress'] is Map
              ? OrderShippingAddress.fromMap(map['shippingAddress'] as Map<String, dynamic>)
              : (map['shippingAddress'] is String
                  ? OrderShippingAddress.fromRawString(map['shippingAddress'] as String)
                  : const OrderShippingAddress()))
          : const OrderShippingAddress(),
      customerNote: map['customerNote'] as String? ?? '',
      paymentInfo: map['paymentInfo'] != null
          ? OrderPaymentInfo.fromMap(map['paymentInfo'] as Map<String, dynamic>)
          : const OrderPaymentInfo(amountPaid: 0, utrNumber: ''),
      items: rawItems.map((i) => OrderProductItem.fromMap(i as Map<String, dynamic>)).toList(),
      subtotal: (map['subtotal'] as num?)?.toDouble() ?? 0.0,
      shippingCharge: (map['shippingCharge'] as num?)?.toDouble() ?? 0.0,
      pendingAmount: (map['pendingAmount'] as num?)?.toDouble() ?? 0.0,
      grandTotal: (map['grandTotal'] as num?)?.toDouble() ?? 0.0,
      timeline: rawTimeline.map((t) => OrderTimelineStage.fromMap(t as Map<String, dynamic>)).toList(),
      dispatchInfo: map['dispatchInfo'] != null
          ? OrderDispatchInfo.fromMap(map['dispatchInfo'] as Map<String, dynamic>)
          : null,
      refundInfo: map['refundInfo'] != null
          ? OrderRefundInfo.fromMap(map['refundInfo'] as Map<String, dynamic>)
          : null,
      receiptUrl: map['receiptUrl'] as String?,
      receiptNumber: map['receiptNumber'] as String?,
      invoiceUrl: map['invoiceUrl'] as String?,
      lastUpdated: (map['lastUpdated'] as Timestamp?)?.toDate(),
    );
  }

  bool get isConfirmed => status == 'Confirmed';
  bool get isDispatched => status == 'Dispatched';
  bool get isRejected => status == 'Rejected';
  bool get isPendingPayment => status == 'Pending Payment';
}
