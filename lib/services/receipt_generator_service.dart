// ─── ReceiptGeneratorService ──────────────────────────────────────────────────
// Automatically generates system receipts (e.g. HZR000001) for orders.
// Uploads PDF to Firebase Storage (`receipts/`) & updates Firestore order record.
// Provides View, Download, and Regenerate receipt features. Zero paid services.

import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/order_model.dart';
import 'cloudinary_service.dart';

class ReceiptGeneratorService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _ordersRef =>
      _db.collection('orders');

  /// Generates a sequential receipt number like HZR000001
  Future<String> generateNextReceiptNumber() async {
    final counterRef = _db.collection('systemSettings').doc('receiptCounter');
    final snap = await counterRef.get();
    int current = 1;
    if (snap.exists && snap.data() != null) {
      current = (snap.data()!['lastNumber'] as int? ?? 0) + 1;
    }
    await counterRef.set({'lastNumber': current}, SetOptions(merge: true));
    return 'HZR${current.toString().padLeft(6, '0')}';
  }

  /// Builds HTML markup for the order receipt PDF
  String buildReceiptHtml(CustomerOrder order, String receiptNumber, DateTime receiptDate) {
    final dateStr = "${receiptDate.day}/${receiptDate.month}/${receiptDate.year}";

    final itemsRows = order.items.map((item) => '''
      <tr>
        <td style="padding: 8px; border-bottom: 1px solid #eee;">${item.title}</td>
        <td style="padding: 8px; border-bottom: 1px solid #eee;">${item.size}</td>
        <td style="padding: 8px; border-bottom: 1px solid #eee; text-align: center;">${item.quantity}</td>
        <td style="padding: 8px; border-bottom: 1px solid #eee; text-align: right;">₹${item.unitPrice.toStringAsFixed(0)}</td>
        <td style="padding: 8px; border-bottom: 1px solid #eee; text-align: right; font-weight: bold;">₹${item.lineTotal.toStringAsFixed(0)}</td>
      </tr>
    ''').join('');

    return '''
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="utf-8">
      <title>Order Receipt $receiptNumber - HashZone</title>
      <style>
        body { font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif; color: #111; margin: 0; padding: 30px; }
        .header { display: flex; justify-content: space-between; border-bottom: 2px solid #000; padding-bottom: 15px; margin-bottom: 20px; }
        .logo { font-size: 24px; font-weight: bold; letter-spacing: 2px; }
        .receipt-info { text-align: right; font-size: 13px; }
        .section-title { font-size: 14px; font-weight: bold; margin-top: 20px; margin-bottom: 8px; text-transform: uppercase; color: #555; }
        .table { width: 100%; border-collapse: collapse; margin-top: 10px; font-size: 13px; }
        .table th { background: #f5f5f5; text-align: left; padding: 8px; border-bottom: 1px solid #ddd; }
        .totals { margin-top: 20px; width: 300px; margin-left: auto; font-size: 13px; }
        .totals-row { display: flex; justify-content: space-between; padding: 5px 0; }
        .grand-total { font-size: 16px; font-weight: bold; border-top: 2px solid #000; padding-top: 8px; margin-top: 8px; }
        .footer { margin-top: 40px; border-top: 1px solid #eee; padding-top: 15px; text-align: center; font-size: 12px; color: #777; }
      </style>
    </head>
    <body>
      <div class="header">
        <div>
          <div class="logo">HASHZONE</div>
          <div style="font-size: 12px; color: #666; margin-top: 4px;">Premium Clothing & Wholesale</div>
        </div>
        <div class="receipt-info">
          <div><strong>OFFICIAL RECEIPT</strong></div>
          <div>Receipt No: <strong>$receiptNumber</strong></div>
          <div>Date: $dateStr</div>
          <div>Order ID: <strong>#${order.id}</strong></div>
        </div>
      </div>

      <div style="display: flex; justify-content: space-between; font-size: 13px;">
        <div style="width: 48%;">
          <div class="section-title">Customer Details</div>
          <div><strong>Name:</strong> ${order.customerName}</div>
          ${order.companyName.isNotEmpty ? "<div><strong>Company:</strong> ${order.companyName}</div>" : ""}
          <div><strong>Phone:</strong> ${order.phoneNumber}</div>
          ${order.email.isNotEmpty ? "<div><strong>Email:</strong> ${order.email}</div>" : ""}
        </div>
        <div style="width: 48%;">
          <div class="section-title">Shipping Address</div>
          <div>${order.shippingAddress.fullAddress}</div>
        </div>
      </div>

      <div class="section-title">Ordered Products</div>
      <table class="table">
        <thead>
          <tr>
            <th>Product Name</th>
            <th>Size</th>
            <th style="text-align: center;">Qty</th>
            <th style="text-align: right;">Unit Price</th>
            <th style="text-align: right;">Line Total</th>
          </tr>
        </thead>
        <tbody>
          $itemsRows
        </tbody>
      </table>

      <div class="totals">
        <div class="totals-row">
          <span>Subtotal:</span>
          <span>₹${order.subtotal.toStringAsFixed(0)}</span>
        </div>
        <div class="totals-row">
          <span>Shipping:</span>
          <span>Calculated separately</span>
        </div>
        <div class="totals-row grand-total">
          <span>Grand Total:</span>
          <span>₹${order.grandTotal.toStringAsFixed(0)}</span>
        </div>
      </div>

      <div class="section-title">Payment & Status</div>
      <div style="font-size: 13px;">
        <div><strong>Payment Method:</strong> ${order.paymentInfo.method}</div>
        <div><strong>Transaction ID / UTR:</strong> ${order.paymentInfo.utrNumber}</div>
        <div><strong>Payment Status:</strong> ${order.paymentInfo.paymentStatus}</div>
        <div><strong>Order Status:</strong> ${order.status}</div>
        ${order.customerNote.isNotEmpty ? "<div style='margin-top: 6px;'><strong>Customer Note:</strong> ${order.customerNote}</div>" : ""}
      </div>

      <div class="footer">
        <p>Thank you for choosing HashZone.</p>
        <p style="font-size: 11px;">This receipt is system generated.</p>
      </div>
    </body>
    </html>
    ''';
  }

  /// Generates receipt PDF (HTML format for web simplicity), uploads to Cloudinary, updates Firestore order
  Future<String> generateAndUploadReceipt(CustomerOrder order, {bool isRegeneration = false}) async {
    final receiptDate = DateTime.now();
    final receiptNumber = isRegeneration
        ? 'HZR${order.id.replaceAll(RegExp(r'[^0-9]'), '').padLeft(6, '0')}'
        : await generateNextReceiptNumber();

    final htmlContent = buildReceiptHtml(order, receiptNumber, receiptDate);
    final bytes = utf8.encode(htmlContent);

    try {
      final filename = '${order.id}_$receiptNumber.html';
      final downloadUrl = await CloudinaryService().uploadFile(
        bytes: Uint8List.fromList(bytes),
        filename: filename,
        folder: 'hashzone/receipts',
        resourceType: 'raw',
      ).timeout(const Duration(seconds: 30), onTimeout: () {
        throw Exception('Cloudinary receipt upload timed out.');
      });

      // Store ONLY URL inside Firestore order document
      await _ordersRef.doc(order.id).set({
        'receiptNumber': receiptNumber,
        'receiptUrl': downloadUrl,
        'receiptGeneratedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      return downloadUrl;
    } catch (e) {
      throw Exception('Receipt generation failed: $e\n\nIf this error persists, please check your network connection and Cloudinary configurations.');
    }
  }
}
