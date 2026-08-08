// ─── OrderService ─────────────────────────────────────────────────────────────
// Firestore collections: orders, orderTimeline, orderStatus, dispatchInformation, refundInformation, orderAudit
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/order_model.dart';

class OrderDashboardSummary {
  final int pendingVerificationCount;
  final int pendingConfirmationCount;
  final int orderReceivedCount;
  final int confirmedCount;
  final int dispatchedCount;
  final int rejectedCount;
  final int todayOrdersCount;
  final int thisMonthOrdersCount;
  final double revenueToday;
  final double revenueThisMonth;
  final double averageOrderValue;
  final int totalCustomersCount;
  final List<CustomerOrder> recentOrders;

  const OrderDashboardSummary({
    this.pendingVerificationCount = 0,
    this.pendingConfirmationCount = 0,
    this.orderReceivedCount = 0,
    this.confirmedCount = 0,
    this.dispatchedCount = 0,
    this.rejectedCount = 0,
    this.todayOrdersCount = 0,
    this.thisMonthOrdersCount = 0,
    this.revenueToday = 0.0,
    this.revenueThisMonth = 0.0,
    this.averageOrderValue = 0.0,
    this.totalCustomersCount = 0,
    this.recentOrders = const [],
  });
}

class OrderService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _ordersRef =>
      _db.collection('orders');

  CollectionReference<Map<String, dynamic>> get _auditRef =>
      _db.collection('orderAudit');

  CollectionReference<Map<String, dynamic>> get _dispatchRef =>
      _db.collection('dispatchInformation');

  CollectionReference<Map<String, dynamic>> get _refundRef =>
      _db.collection('refundInformation');

  /// Creates a new customer order and logs audit event
  Future<String> createOrder(CustomerOrder order) async {
    final docRef = _ordersRef.doc(order.id.isNotEmpty ? order.id : null);
    final data = order.toMap();
    await docRef.set(data, SetOptions(merge: true));

    // Audit log
    await _auditRef.add({
      'orderId': docRef.id,
      'action': 'ORDER_CREATED',
      'customerId': order.customerId,
      'grandTotal': order.grandTotal,
      'timestamp': FieldValue.serverTimestamp(),
    });

    return docRef.id;
  }

  /// Streams admin orders with lazy loading / limit options
  Stream<List<CustomerOrder>> streamAdminOrders({int limit = 50}) {
    return _ordersRef
        .orderBy('orderDate', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => CustomerOrder.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Streams orders for a specific customer
  Stream<List<CustomerOrder>> streamCustomerOrders(String customerId) {
    return _ordersRef
        .where('customerId', isEqualTo: customerId)
        .orderBy('orderDate', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => CustomerOrder.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Fetches a single order by ID
  Future<CustomerOrder?> getOrderById(String orderId) async {
    final doc = await _ordersRef.doc(orderId).get();
    if (!doc.exists || doc.data() == null) return null;
    return CustomerOrder.fromMap(doc.data()!, doc.id);
  }

  /// Confirms an order
  Future<void> confirmOrder({
    required String orderId,
    required String adminUser,
  }) async {
    final now = DateTime.now();
    final doc = await _ordersRef.doc(orderId).get();
    if (!doc.exists || doc.data() == null) return;

    final existingOrder = CustomerOrder.fromMap(doc.data()!, doc.id);

    // Update timeline stages
    final updatedTimeline = existingOrder.timeline.map((t) {
      if (t.stageName == 'Order Confirmed') {
        return OrderTimelineStage(
          stageName: 'Order Confirmed',
          isCompleted: true,
          timestamp: now,
        );
      }
      return t;
    }).toList();

    await _ordersRef.doc(orderId).update({
      'status': 'Confirmed',
      'timeline': updatedTimeline.map((t) => t.toMap()).toList(),
      'lastUpdated': FieldValue.serverTimestamp(),
    });

    // Record audit entry
    await _auditRef.add({
      'orderId': orderId,
      'action': 'CONFIRMED',
      'adminUser': adminUser,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  /// Rejects an order (available before AND after confirmation)
  Future<void> rejectOrder({
    required String orderId,
    required bool refundRequired,
    required String refundTimeline,
    required String reason,
    String? adminNote,
    required String adminUser,
  }) async {
    final now = DateTime.now();

    final refundInfo = OrderRefundInfo(
      refundRequired: refundRequired,
      refundTimeline: refundTimeline,
      reason: reason,
      adminNote: adminNote ?? '',
      rejectedBy: adminUser,
      rejectedTime: now,
    );

    await _ordersRef.doc(orderId).update({
      'status': 'Rejected',
      'refundInfo': refundInfo.toMap(),
      'lastUpdated': FieldValue.serverTimestamp(),
    });

    // Store in refundInformation collection
    await _refundRef.doc(orderId).set(refundInfo.toMap(), SetOptions(merge: true));

    // Audit log
    await _auditRef.add({
      'orderId': orderId,
      'action': 'REJECTED',
      'reason': reason,
      'refundRequired': refundRequired,
      'refundTimeline': refundTimeline,
      'adminUser': adminUser,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  /// Dispatches an order
  Future<void> dispatchOrder({
    required String orderId,
    required String courierCompany,
    required String awbNumber,
    required String trackingUrl,
    String? additionalNote,
    required String adminUser,
  }) async {
    final now = DateTime.now();
    final doc = await _ordersRef.doc(orderId).get();
    if (!doc.exists || doc.data() == null) return;

    final existingOrder = CustomerOrder.fromMap(doc.data()!, doc.id);

    final dispatchInfo = OrderDispatchInfo(
      courierCompany: courierCompany,
      awbNumber: awbNumber,
      trackingUrl: trackingUrl,
      additionalNote: additionalNote ?? '',
      dispatchedBy: adminUser,
      dispatchedTime: now,
    );

    // Update timeline stages
    final updatedTimeline = existingOrder.timeline.map((t) {
      if (t.stageName == 'Dispatched') {
        return OrderTimelineStage(
          stageName: 'Dispatched',
          isCompleted: true,
          timestamp: now,
        );
      }
      return t;
    }).toList();

    await _ordersRef.doc(orderId).update({
      'status': 'Dispatched',
      'dispatchInfo': dispatchInfo.toMap(),
      'timeline': updatedTimeline.map((t) => t.toMap()).toList(),
      'lastUpdated': FieldValue.serverTimestamp(),
    });

    // Store in dispatchInformation collection
    await _dispatchRef.doc(orderId).set(dispatchInfo.toMap(), SetOptions(merge: true));

    // Audit log
    await _auditRef.add({
      'orderId': orderId,
      'action': 'DISPATCHED',
      'courierCompany': courierCompany,
      'awbNumber': awbNumber,
      'adminUser': adminUser,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  /// Calculates Orders Dashboard summary metrics
  Future<OrderDashboardSummary> getOrdersDashboardSummary() async {
    try {
      final snap = await _ordersRef.get();
      final docs = snap.docs.map((d) => CustomerOrder.fromMap(d.data(), d.id)).toList();

      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final monthStart = DateTime(now.year, now.month, 1);

      int pendingVerification = 0;
      int pendingConfirmation = 0;
      int orderReceived = 0;
      int confirmed = 0;
      int dispatched = 0;
      int rejected = 0;
      int todayCount = 0;
      int monthCount = 0;
      double revToday = 0.0;
      double revMonth = 0.0;
      double totalRevenue = 0.0;
      int validOrdersCount = 0;
      final customerIds = <String>{};

      for (final order in docs) {
        if (order.customerId.isNotEmpty) customerIds.add(order.customerId);

        if (order.status == 'Pending Payment') pendingVerification++;
        if (order.status == 'Order Received') {
          orderReceived++;
          pendingConfirmation++;
        }
        if (order.status == 'Confirmed') confirmed++;
        if (order.status == 'Dispatched') dispatched++;
        if (order.status == 'Rejected') rejected++;

        if (order.status != 'Rejected') {
          totalRevenue += order.grandTotal;
          validOrdersCount++;
        }

        if (order.orderDate.isAfter(todayStart)) {
          todayCount++;
          if (order.status != 'Rejected') revToday += order.grandTotal;
        }

        if (order.orderDate.isAfter(monthStart)) {
          monthCount++;
          if (order.status != 'Rejected') revMonth += order.grandTotal;
        }
      }

      docs.sort((a, b) => b.orderDate.compareTo(a.orderDate));
      final recent = docs.take(5).toList();
      final double aov = validOrdersCount > 0 ? (totalRevenue / validOrdersCount) : 0.0;

      return OrderDashboardSummary(
        pendingVerificationCount: pendingVerification,
        pendingConfirmationCount: pendingConfirmation,
        orderReceivedCount: orderReceived,
        confirmedCount: confirmed,
        dispatchedCount: dispatched,
        rejectedCount: rejected,
        todayOrdersCount: todayCount,
        thisMonthOrdersCount: monthCount,
        revenueToday: revToday,
        revenueThisMonth: revMonth,
        averageOrderValue: aov,
        totalCustomersCount: customerIds.length,
        recentOrders: recent,
      );
    } catch (_) {
      return const OrderDashboardSummary();
    }
  }

  /// Destructive action to delete an order with minimal audit trail
  Future<void> deleteOrder({
    required String orderId,
    required String adminUser,
  }) async {
    // 1. Delete order doc
    await _ordersRef.doc(orderId).delete();

    // 2. Clear from dispatch collection if exists
    await _dispatchRef.doc(orderId).delete().catchError((_) {});

    // 3. Clear from refund collection if exists
    await _refundRef.doc(orderId).delete().catchError((_) {});

    // 4. Record minimal audit trail
    await _auditRef.add({
      'orderId': orderId,
      'action': 'DELETED',
      'deletedBy': adminUser,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }
}
