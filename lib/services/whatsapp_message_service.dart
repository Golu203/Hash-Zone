// ─── WhatsAppMessageService ──────────────────────────────────────────────────
// WhatsApp Message Centre & Communication Engine using zero paid/Meta APIs.
// Direct pre-filled https://wa.me/ URL launcher with live Firestore message logging.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/order_model.dart';

class WhatsAppMessageService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _logsRef =>
      _db.collection('messageLogs');

  CollectionReference<Map<String, dynamic>> get _commRef =>
      _db.collection('orderCommunication');

  /// Formats product list into bulleted text block for messages
  String _formatProductsList(List<OrderProductItem> items) {
    return items.map((i) => "• ${i.title} (Size: ${i.size}, Qty: ${i.quantity})").join("\n");
  }

  /// 1. ORDER RECEIVED MESSAGE TEMPLATE
  String buildOrderReceivedMessage({
    required CustomerOrder order,
    String estimatedVerificationTime = '',
    String additionalNote = '',
  }) {
    final products = _formatProductsList(order.items);
    final est = estimatedVerificationTime.isNotEmpty
        ? "\n*Estimated Verification Time:* $estimatedVerificationTime"
        : "";
    final note = additionalNote.isNotEmpty ? "\n*Note:* $additionalNote" : "";

    return "Hello ${order.customerName},\n\n"
        "Thank you for placing your order with *HashZone*!\n\n"
        "*Order ID:* #${order.id}\n"
        "*Status:* Order Received (Payment Pending Verification)\n"
        "*Order Amount:* ₹${order.grandTotal.toStringAsFixed(0)}\n\n"
        "*Ordered Items:*\n$products\n$est$note\n\n"
        "We are verifying your payment details. You will receive an update as soon as your payment is verified.\n\n"
        "Best regards,\n*HashZone Team*";
  }

  /// 2. ORDER CONFIRMED MESSAGE TEMPLATE
  String buildOrderConfirmedMessage({
    required CustomerOrder order,
    String expectedDispatchDate = '',
    String additionalNote = '',
  }) {
    final products = _formatProductsList(order.items);
    final disp = expectedDispatchDate.isNotEmpty
        ? "\n*Expected Dispatch Date:* $expectedDispatchDate"
        : "";
    final note = additionalNote.isNotEmpty ? "\n*Note:* $additionalNote" : "";

    return "Hello ${order.customerName},\n\n"
        "Great news! Your order *#${order.id}* has been *CONFIRMED* by HashZone! 🎉\n\n"
        "*Order Amount:* ₹${order.grandTotal.toStringAsFixed(0)}\n\n"
        "*Confirmed Items:*\n$products\n$disp$note\n\n"
        "Your order is now being packed and prepared for dispatch. We will notify you with the tracking details once shipped.\n\n"
        "Thank you for choosing *HashZone*!";
  }

  /// 3. ORDER DISPATCHED MESSAGE TEMPLATE
  String buildOrderDispatchedMessage({
    required CustomerOrder order,
    required String courierCompany,
    required String trackingNumber,
    String trackingLink = '',
    String additionalNote = '',
  }) {
    final products = _formatProductsList(order.items);
    final linkText = trackingLink.isNotEmpty ? "\n*Track Link:* $trackingLink" : "";
    final note = additionalNote.isNotEmpty ? "\n*Note:* $additionalNote" : "";

    return "Hello ${order.customerName},\n\n"
        "Your order *#${order.id}* has been *DISPATCHED*! 🚚\n\n"
        "*Courier Partner:* $courierCompany\n"
        "*AWB / Tracking No:* $trackingNumber$linkText\n\n"
        "*Items Shipped:*\n$products$note\n\n"
        "Thank you for shopping with *HashZone*! Please let us know if you need any assistance.";
  }

  /// 4. ORDER CANCELLED / REJECTED MESSAGE TEMPLATE
  String buildOrderCancelledMessage({
    required CustomerOrder order,
    required String reason,
    String refundTimeline = '',
    String additionalNote = '',
  }) {
    final refund = refundTimeline.isNotEmpty
        ? "\n*Refund Timeline:* $refundTimeline"
        : "";
    final note = additionalNote.isNotEmpty ? "\n*Note:* $additionalNote" : "";

    return "Hello ${order.customerName},\n\n"
        "Regrettably, your order *#${order.id}* could not be processed and has been *CANCELLED*.\n\n"
        "*Reason for Cancellation:* $reason$refund$note\n\n"
        "If you have any questions or require further assistance, please feel free to reply directly to this message.\n\n"
        "Sincerely,\n*HashZone Support*";
  }

  /// 5. CUSTOM MESSAGE TEMPLATE
  String buildCustomMessage({
    required CustomerOrder order,
    required String customText,
  }) {
    return "Hello ${order.customerName},\n\n"
        "Regarding your order *#${order.id}*:\n\n"
        "$customText\n\n"
        "Best regards,\n*HashZone Team*";
  }

  /// Sends message via pre-filled https://wa.me/ URL and logs to Firestore
  Future<bool> sendWhatsAppMessage({
    required CustomerOrder order,
    required String messageText,
    required String templateType,
    required String adminUser,
  }) async {
    final phone = order.whatsAppNumber.isNotEmpty ? order.whatsAppNumber : order.phoneNumber;
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final fullPhone = cleanPhone.length == 10 ? '91$cleanPhone' : cleanPhone;

    final encodedMsg = Uri.encodeComponent(messageText);
    final waUrl = "https://wa.me/$fullPhone?text=$encodedMsg";

    final uri = Uri.parse(waUrl);
    bool launched = false;
    if (await canLaunchUrl(uri)) {
      launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    }

    // Log message to Firestore async
    try {
      await _logsRef.add({
        'orderId': order.id,
        'customerId': order.customerId,
        'customerName': order.customerName,
        'phoneNumber': fullPhone,
        'templateType': templateType,
        'messageText': messageText,
        'adminUser': adminUser,
        'launched': launched,
        'timestamp': FieldValue.serverTimestamp(),
      });

      await _commRef.doc(order.id).collection('history').add({
        'templateType': templateType,
        'messageText': messageText,
        'sentBy': adminUser,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (_) {}

    return launched;
  }
}
