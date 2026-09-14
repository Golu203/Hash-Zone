import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/order_model.dart';

/// Service responsible for dispatching new order notifications to the
/// administrative Google Sheet ("Orders" tab) and triggering the admin email alert
/// via Google Apps Script Web App.
///
/// Strictly isolated and failure-safe: errors are safely logged and will NEVER
/// fail an order, block the UI, or affect the customer success flow.
class OrderNotificationService {
  static final OrderNotificationService _instance = OrderNotificationService._internal();
  factory OrderNotificationService() => _instance;
  OrderNotificationService._internal();

  // Webhook secret for Google Apps Script Web App
  static const String webhookSecret = 'HZ_orders_2026_ajay9884875578';

  // Direct Google Apps Script Web App URL
  static const String appsScriptUrl =
      'https://script.google.com/macros/s/AKfycbyKGTx4QzEWlwQg8JuTXk2xDpCH_uD4UkihU3Yosul3jGFHBTpvY5mSGA0PGjTTYCgH/exec';

  // Serverless relay endpoint
  static const String serverlessRelayUrl =
      'https://www.hashzone.co.in/api/order-notification';

  // Dedicated admin notification recipient
  static const String adminEmail = 'smtind20@gmail.com';
  static const String senderDisplayName = 'HASH ZONE DIGITAL STORE';

  // In-memory set to prevent duplicate dispatches during active sessions/rebuilds
  static final Set<String> _dispatchedOrderIds = {};

  /// Asynchronously dispatches the new order notification.
  /// Fully failure-safe: catches all exceptions so order creation is never impacted.
  Future<void> notifyNewOrder(CustomerOrder order) async {
    if (order.id.isEmpty) return;

    // ── DUPLICATE PROTECTION ────────────────────────────────────────────────
    // 1. Check in-memory registry
    if (_dispatchedOrderIds.contains(order.id)) {
      debugPrint('[OrderNotificationService] Skipping duplicate notification for order ${order.id} (in-memory)');
      return;
    }

    // 2. Check persistent SharedPreferences registry
    try {
      final prefs = await SharedPreferences.getInstance();
      final prefKey = 'notif_sent_${order.id}';
      if (prefs.getBool(prefKey) == true) {
        debugPrint('[OrderNotificationService] Skipping duplicate notification for order ${order.id} (persistent)');
        _dispatchedOrderIds.add(order.id);
        return;
      }
      // Mark as dispatched immediately to prevent race conditions
      _dispatchedOrderIds.add(order.id);
      await prefs.setBool(prefKey, true);
    } catch (e) {
      debugPrint('[OrderNotificationService] SharedPreferences check error: $e');
      _dispatchedOrderIds.add(order.id);
    }

    // ── DISPATCH ────────────────────────────────────────────────────────────
    try {
      await _dispatchNotification(order);
    } catch (err) {
      // Critical Failure Safety: Log safely and NEVER throw
      debugPrint('[OrderNotificationService] Non-fatal notification error for order ${order.id}: $err');
    }
  }

  Future<void> _dispatchNotification(CustomerOrder order) async {
    // 1. Format timestamp (e.g. "2026-09-08 20:30:45")
    final d = order.orderDate.toLocal();
    String pad(int n) => n.toString().padLeft(2, '0');
    final timestampStr =
        '${d.year}-${pad(d.month)}-${pad(d.day)} ${pad(d.hour)}:${pad(d.minute)}:${pad(d.second)}';

    // 2. Format products list
    final productDescriptions = order.items.map((item) {
      final bundlePart = (item.bundleName != null && item.bundleName!.isNotEmpty)
          ? ' (${item.bundleName})'
          : '';
      final sizePart = (item.size.isNotEmpty && item.size != 'Free Size')
          ? ' [Size: ${item.size}]'
          : '';
      final qty = item.bundleQuantity ?? item.quantity;
      return '${item.title}$bundlePart$sizePart x$qty';
    }).join(', ');

    // 3. Compute total bundle quantity
    final totalBundleQuantity = order.items.fold<int>(
      0,
      (sum, item) => sum + (item.bundleQuantity ?? item.quantity),
    );

    // 4. Build complete 25-column mapping + flexible JSON keys
    final payload = {
      // Authentication & Config
      'secret': webhookSecret,
      'webhookSecret': webhookSecret,
      'adminEmail': adminEmail,
      'senderName': senderDisplayName,

      // Exact Google Sheet "Orders" Tab Columns (A through Y)
      'Timestamp': timestampStr,
      'Order ID': order.id,
      'Customer Name': order.customerName,
      'Customer Phone': order.phoneNumber,
      'Customer Email': order.email,
      'Identification Type': order.businessIdType ?? '',
      'Identification Number': order.businessIdValue ?? '',
      'Door Number': order.shippingAddress.doorNumber,
      'Street': order.shippingAddress.road,
      'Area': order.shippingAddress.area,
      'State': order.shippingAddress.state,
      'City': order.shippingAddress.city,
      'PIN Code': order.shippingAddress.pincode,
      'Landmark': order.shippingAddress.landmark,
      'Products': productDescriptions,
      'Bundle Quantity': totalBundleQuantity,
      'Product Subtotal': order.subtotal,
      'Shipping Cost': order.shippingCharge,
      'Grand Total': order.grandTotal,
      'Payment Method': order.paymentInfo.method,
      'UTR / Reference': order.paymentInfo.utrNumber,
      'Payment Status': order.paymentInfo.paymentStatus,
      'Order Status': order.status,
      'Customer Note': order.customerNote,
      'Notification Status': 'Pending',

      // camelCase aliases for maximum Apps Script parser compatibility
      'orderId': order.id,
      'timestamp': timestampStr,
      'customerName': order.customerName,
      'customerPhone': order.phoneNumber,
      'customerEmail': order.email,
      'identificationType': order.businessIdType ?? '',
      'identificationNumber': order.businessIdValue ?? '',
      'doorNumber': order.shippingAddress.doorNumber,
      'street': order.shippingAddress.road,
      'area': order.shippingAddress.area,
      'state': order.shippingAddress.state,
      'city': order.shippingAddress.city,
      'pincode': order.shippingAddress.pincode,
      'pinCode': order.shippingAddress.pincode,
      'landmark': order.shippingAddress.landmark,
      'products': productDescriptions,
      'bundleQuantity': totalBundleQuantity,
      'productSubtotal': order.subtotal,
      'subtotal': order.subtotal,
      'shippingCost': order.shippingCharge,
      'shippingCharge': order.shippingCharge,
      'grandTotal': order.grandTotal,
      'paymentMethod': order.paymentInfo.method,
      'utr': order.paymentInfo.utrNumber,
      'utrNumber': order.paymentInfo.utrNumber,
      'paymentStatus': order.paymentInfo.paymentStatus,
      'orderStatus': order.status,
      'customerNote': order.customerNote,
      'notificationStatus': 'Pending',

      // Explicit row array in column A-Y order
      'row': [
        timestampStr,
        order.id,
        order.customerName,
        order.phoneNumber,
        order.email,
        order.businessIdType ?? '',
        order.businessIdValue ?? '',
        order.shippingAddress.doorNumber,
        order.shippingAddress.road,
        order.shippingAddress.area,
        order.shippingAddress.state,
        order.shippingAddress.city,
        order.shippingAddress.pincode,
        order.shippingAddress.landmark,
        productDescriptions,
        totalBundleQuantity,
        order.subtotal,
        order.shippingCharge,
        order.grandTotal,
        order.paymentInfo.method,
        order.paymentInfo.utrNumber,
        order.paymentInfo.paymentStatus,
        order.status,
        order.customerNote,
        'Pending',
      ],
    };

    final bodyJson = jsonEncode(payload);

    // Endpoints in priority order:
    // 1. Serverless relay (keeps secret on server in production)
    // 2. Relative serverless path if on same domain
    // 3. Direct Apps Script Web App
    final endpoints = <Uri>[
      Uri.parse(serverlessRelayUrl),
      if (kIsWeb) Uri.parse('/api/order-notification'),
      Uri.parse(appsScriptUrl),
    ];

    for (final uri in endpoints) {
      try {
        final response = await http
            .post(
              uri,
              headers: {'Content-Type': 'application/json'},
              body: bodyJson,
            )
            .timeout(const Duration(seconds: 15));

        if (response.statusCode >= 200 && response.statusCode < 400) {
          debugPrint('[OrderNotificationService] Successfully sent notification for order ${order.id} via $uri');
          return;
        } else {
          debugPrint('[OrderNotificationService] Endpoint $uri returned status ${response.statusCode}');
        }
      } catch (e) {
        debugPrint('[OrderNotificationService] Endpoint $uri failed: $e');
      }
    }
  }
}
