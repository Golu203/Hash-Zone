import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/order_model.dart';
import '../../services/order_service.dart';
import '../../widgets/navbar.dart';
import '../../widgets/footer.dart';
import '../../widgets/smart_back_button.dart';
import 'package:provider/provider.dart';
import '../../providers/customer_auth_provider.dart';
import '../../services/receipt_generator_service.dart';
import '../../services/b2_invoice_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
class CustomerOrderDetailsScreen extends StatelessWidget {
  final String orderId;

  const CustomerOrderDetailsScreen({super.key, required this.orderId});

  Future<void> _launchUrl(String url) async {
    if (url.isEmpty) return;
    final uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(uri);
      }
    } catch (_) {
      await launchUrl(uri);
    }
  }

  /// Converts Cloudinary /image/upload/ URL to /raw/upload/ for PDF files.
  String _toPdfUrl(String url) {
    if (url.contains('/image/upload/')) {
      return url.replaceFirst('/image/upload/', '/raw/upload/');
    }
    return url;
  }

  void _handleCustomerInvoiceView(BuildContext context, CustomerOrder order) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null || currentUser.uid != order.customerId) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Access Denied: You are only authorized to access your own order invoices.', style: GoogleFonts.inter()),
          backgroundColor: Colors.red.shade700,
        ),
      );
      return;
    }

    if (order.invoiceUrl == null || order.invoiceUrl!.isEmpty) return;
    final accessUrl = B2InvoiceService().generatePresignedGetUrl(order.invoiceUrl!);
    _launchUrl(accessUrl);
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;
    final service = OrderService();
    final auth = Provider.of<CustomerAuthProvider>(context, listen: false);
    final currentUserId = auth.firebaseUser?.uid ?? auth.profile?.uid ?? '';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const HZNavBar(),
      endDrawer: MediaQuery.of(context).size.width < 1150 ? const HZMobileDrawer() : null,
      body: StreamBuilder<CustomerOrder?>(
        stream: service.streamOrderById(orderId),
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text('Error loading order details: ${snap.error}', style: GoogleFonts.inter(color: Colors.red)),
              ),
            );
          }

          if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
            return const Center(child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.black)));
          }

          final order = snap.data;
          if (order == null || order.customerId != currentUserId) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.lock_outline, size: 48, color: Colors.black26),
                  const SizedBox(height: 12),
                  Text('Access Denied or Order not found', style: GoogleFonts.inter(fontSize: 16, color: Colors.black54)),
                  const SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: () => context.go('/orders'),
                    child: const Text('Back to My Orders'),
                  ),
                ],
              ),
            );
          }

          final dateStr = DateFormat('dd MMM yyyy, hh:mm a').format(order.orderDate);

          final isMobile = MediaQuery.of(context).size.width < 750;

          return SingleChildScrollView(
            child: Column(
              children: [
                // Header Banner
                Container(
                  width: double.infinity,
                  color: const Color(0xFFF9F9F9),
                  padding: EdgeInsets.symmetric(horizontal: isDesktop ? 64 : 20, vertical: 24),
                  child: Row(
                    children: [
                      const HZSmartBackButton(fallbackRoute: '/orders', label: null),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Order Details #${order.id}',
                          style: GoogleFonts.cormorantGaramond(fontSize: isMobile ? 18 : 26, fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),

                // Main Content
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: isDesktop ? 64 : 16, vertical: 32),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 900),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Status Header Card
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFAFAFA),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFFEEEEEE)),
                            ),
                            child: isMobile
                                ? Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Placed on $dateStr', style: GoogleFonts.inter(fontSize: 12, color: Colors.black54)),
                                      const SizedBox(height: 6),
                                      Text('Status: ${order.status}', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black)),
                                      const SizedBox(height: 12),
                                      Text('Grand Total: ₹${order.grandTotal.toStringAsFixed(0)}', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold)),
                                    ],
                                  )
                                : Row(
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('Placed on $dateStr', style: GoogleFonts.inter(fontSize: 12, color: Colors.black54)),
                                          const SizedBox(height: 4),
                                          Text('Status: ${order.status}', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black)),
                                        ],
                                      ),
                                      const Spacer(),
                                      Text('Grand Total: ₹${order.grandTotal.toStringAsFixed(0)}', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                          ),

                          const SizedBox(height: 24),

                          // 3-Stage Timeline
                          _buildTimeline(order, isMobile),

                          const SizedBox(height: 24),

                          // Products Section
                          Text('Ordered Products', style: GoogleFonts.cormorantGaramond(fontSize: 20, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          ...order.items.map((item) => Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  border: Border.all(color: const Color(0xFFEEEEEE)),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: isMobile
                                    ? Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              ClipRRect(
                                                borderRadius: BorderRadius.circular(8),
                                                child: Image.network(
                                                  item.imageUrl,
                                                  width: 70,
                                                  height: 70,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (_, __, ___) => Container(width: 70, height: 70, color: const Color(0xFFF0F0F0), child: const Icon(Icons.image_not_supported, size: 24, color: Colors.black26)),
                                                ),
                                              ),
                                              const SizedBox(width: 16),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(item.title, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold)),
                                                    const SizedBox(height: 6),
                                                    Text('SKU: ${item.sku}', style: GoogleFonts.inter(fontSize: 12, color: Colors.black54)),
                                                    Text('Size: ${item.size}', style: GoogleFonts.inter(fontSize: 12, color: Colors.black54)),
                                                    Text('Quantity: ${item.quantity}', style: GoogleFonts.inter(fontSize: 12, color: Colors.black54)),
                                                    Text('Unit Price: ₹${item.unitPrice.toStringAsFixed(0)}', style: GoogleFonts.inter(fontSize: 12, color: Colors.black54)),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                          const Divider(height: 24, color: Color(0xFFEEEEEE)),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text('Item Total:', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.black54)),
                                              Text('₹${item.lineTotal.toStringAsFixed(0)}', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold)),
                                            ],
                                          ),
                                        ],
                                      )
                                    : Row(
                                        children: [
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(8),
                                            child: Image.network(
                                              item.imageUrl,
                                              width: 60,
                                              height: 60,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) => Container(width: 60, height: 60, color: const Color(0xFFF0F0F0), child: const Icon(Icons.image_not_supported, size: 24, color: Colors.black26)),
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(item.title, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold)),
                                                const SizedBox(height: 4),
                                                Text('Size: ${item.size}  |  SKU: ${item.sku}', style: GoogleFonts.inter(fontSize: 12, color: Colors.black45)),
                                                Text('Qty: ${item.quantity} × ₹${item.unitPrice.toStringAsFixed(0)}', style: GoogleFonts.inter(fontSize: 12, color: Colors.black54)),
                                              ],
                                            ),
                                          ),
                                          Text('₹${item.lineTotal.toStringAsFixed(0)}', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                              )),

                          const SizedBox(height: 24),

                          // Delivery & Payment Summaries
                          isMobile
                              ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(20),
                                      decoration: BoxDecoration(border: Border.all(color: const Color(0xFFEEEEEE)), borderRadius: BorderRadius.circular(12)),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('Shipping Address', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54)),
                                          const SizedBox(height: 8),
                                          Text(order.shippingAddress.formattedMultiLine, style: GoogleFonts.inter(fontSize: 13, height: 1.5)),
                                          if (order.phoneNumber.isNotEmpty || (order.businessIdType?.isNotEmpty == true && order.businessIdValue?.isNotEmpty == true)) ...[
                                            const SizedBox(height: 8),
                                            const Divider(height: 16, color: Color(0xFFEEEEEE)),
                                            if (order.phoneNumber.isNotEmpty)
                                              Text('Contact: ${order.phoneNumber}', style: GoogleFonts.inter(fontSize: 12, color: Colors.black87)),
                                            if (order.businessIdType?.isNotEmpty == true && order.businessIdValue?.isNotEmpty == true)
                                              Text('${order.businessIdType}: ${order.businessIdValue}', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF1E3A8A))),
                                          ],
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Container(
                                      padding: const EdgeInsets.all(20),
                                      decoration: BoxDecoration(border: Border.all(color: const Color(0xFFEEEEEE)), borderRadius: BorderRadius.circular(12)),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('Payment Summary', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54)),
                                          const SizedBox(height: 8),
                                          Text('Method: ${order.paymentInfo.method}', style: GoogleFonts.inter(fontSize: 13)),
                                          Text('UTR: ${order.paymentInfo.utrNumber}', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
                                          Text('Status: ${order.paymentInfo.paymentStatus}', style: GoogleFonts.inter(fontSize: 13, color: Colors.black54)),
                                        ],
                                      ),
                                    ),
                                  ],
                                )
                              : Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Container(
                                        padding: const EdgeInsets.all(20),
                                        decoration: BoxDecoration(border: Border.all(color: const Color(0xFFEEEEEE)), borderRadius: BorderRadius.circular(12)),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text('Shipping Address', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54)),
                                            const SizedBox(height: 8),
                                            Text(order.shippingAddress.formattedMultiLine, style: GoogleFonts.inter(fontSize: 13, height: 1.5)),
                                            if (order.phoneNumber.isNotEmpty || (order.businessIdType?.isNotEmpty == true && order.businessIdValue?.isNotEmpty == true)) ...[
                                              const SizedBox(height: 8),
                                              const Divider(height: 16, color: Color(0xFFEEEEEE)),
                                              if (order.phoneNumber.isNotEmpty)
                                                Text('Contact: ${order.phoneNumber}', style: GoogleFonts.inter(fontSize: 12, color: Colors.black87)),
                                              if (order.businessIdType?.isNotEmpty == true && order.businessIdValue?.isNotEmpty == true)
                                                Text('${order.businessIdType}: ${order.businessIdValue}', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF1E3A8A))),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Container(
                                        padding: const EdgeInsets.all(20),
                                        decoration: BoxDecoration(border: Border.all(color: const Color(0xFFEEEEEE)), borderRadius: BorderRadius.circular(12)),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text('Payment Summary', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54)),
                                            const SizedBox(height: 8),
                                            Text('Method: ${order.paymentInfo.method}', style: GoogleFonts.inter(fontSize: 13)),
                                            Text('UTR: ${order.paymentInfo.utrNumber}', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
                                            Text('Status: ${order.paymentInfo.paymentStatus}', style: GoogleFonts.inter(fontSize: 13, color: Colors.black54)),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                          // Rejection / Dispatch Cards
                          if (order.isRejected && order.refundInfo != null) ...[
                            const SizedBox(height: 24),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(color: const Color(0xFFFFF3F3), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFFFCDD2))),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Order Rejection Details', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFFD32F2F))),
                                  const SizedBox(height: 6),
                                  Text('Reason: ${order.refundInfo!.reason}', style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFFD32F2F))),
                                  if (order.refundInfo!.refundRequired)
                                    Text('Refund Timeline: ${order.refundInfo!.refundTimeline}', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFFD32F2F))),
                                ],
                              ),
                            ),
                          ],

                          if (order.isDispatched && order.dispatchInfo != null) ...[
                            const SizedBox(height: 24),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(color: const Color(0xFFE3F2FD), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF90CAF9))),
                              child: Row(
                                children: [
                                  const Icon(Icons.local_shipping_outlined, color: Color(0xFF1565C0), size: 24),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Courier: ${order.dispatchInfo!.courierCompany}', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF1565C0))),
                                        Text('AWB Tracking No: ${order.dispatchInfo!.awbNumber}', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF1565C0))),
                                      ],
                                    ),
                                  ),
                                  if (order.dispatchInfo!.trackingUrl.isNotEmpty)
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1565C0), foregroundColor: Colors.white),
                                      onPressed: () => _launchUrl(order.dispatchInfo!.trackingUrl),
                                      child: const Text('Track Order'),
                                    ),
                                ],
                              ),
                            ),
                          ],
                          const Divider(height: 32, color: Color(0xFFEEEEEE)),
                          Text('ORDER DOCUMENTS', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54, letterSpacing: 1.0)),
                          const SizedBox(height: 12),
                          isMobile
                              ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    // Receipt block
                                    Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        border: Border.all(color: const Color(0xFFEEEEEE)),
                                        borderRadius: BorderRadius.circular(12),
                                        color: const Color(0xFFFAFAFA),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('Order Receipt', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold)),
                                          const SizedBox(height: 6),
                                          if (order.receiptUrl != null && order.receiptUrl!.isNotEmpty) ...[
                                            Text(order.receiptNumber ?? 'Official Receipt', style: GoogleFonts.inter(fontSize: 11, color: Colors.black54)),
                                            const SizedBox(height: 12),
                                            ElevatedButton.icon(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: const Color(0xFF2E7D32),
                                                foregroundColor: Colors.white,
                                                elevation: 0,
                                                minimumSize: const Size.fromHeight(40),
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                              ),
                                              onPressed: () => _launchUrl(order.receiptUrl!),
                                              icon: const Icon(Icons.picture_as_pdf, size: 14),
                                              label: Text('VIEW RECEIPT', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold)),
                                            ),
                                          ] else ...[
                                            Text('Receipt not available.', style: GoogleFonts.inter(fontSize: 12, color: Colors.black38)),
                                            const SizedBox(height: 12),
                                            ElevatedButton.icon(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.black,
                                                foregroundColor: Colors.white,
                                                elevation: 0,
                                                minimumSize: const Size.fromHeight(40),
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                              ),
                                              onPressed: () async {
                                                final generator = ReceiptGeneratorService();
                                                final url = await generator.generateAndUploadReceipt(order);
                                                _launchUrl(url);
                                              },
                                              icon: const Icon(Icons.download, size: 14),
                                              label: Text('GENERATE RECEIPT', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold)),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    // Invoice block
                                    Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        border: Border.all(color: const Color(0xFFEEEEEE)),
                                        borderRadius: BorderRadius.circular(12),
                                        color: const Color(0xFFFAFAFA),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('Invoice', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold)),
                                          const SizedBox(height: 6),
                                          if (order.invoiceUrl != null && order.invoiceUrl!.isNotEmpty) ...[
                                            Text('Official PDF Invoice', style: GoogleFonts.inter(fontSize: 11, color: Colors.black54)),
                                            const SizedBox(height: 12),
                                            ElevatedButton.icon(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: const Color(0xFF1565C0),
                                                foregroundColor: Colors.white,
                                                elevation: 0,
                                                minimumSize: const Size.fromHeight(40),
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                              ),
                                              onPressed: () => _handleCustomerInvoiceView(context, order),
                                              icon: const Icon(Icons.description, size: 14),
                                              label: Text('VIEW INVOICE', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold)),
                                            ),
                                          ] else ...[
                                            Text('Invoice not yet available.', style: GoogleFonts.inter(fontSize: 12, color: Colors.black38)),
                                            const SizedBox(height: 12),
                                            ElevatedButton.icon(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.grey.shade300,
                                                foregroundColor: Colors.black38,
                                                elevation: 0,
                                                minimumSize: const Size.fromHeight(40),
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                              ),
                                              onPressed: null,
                                              icon: const Icon(Icons.lock_outline, size: 14),
                                              label: Text('NOT YET AVAILABLE', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold)),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                )
                              : Row(
                                  children: [
                                    // Receipt block
                                    Expanded(
                                      child: Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          border: Border.all(color: const Color(0xFFEEEEEE)),
                                          borderRadius: BorderRadius.circular(12),
                                          color: const Color(0xFFFAFAFA),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text('Order Receipt', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold)),
                                            const SizedBox(height: 6),
                                            if (order.receiptUrl != null && order.receiptUrl!.isNotEmpty) ...[
                                              Text(order.receiptNumber ?? 'Official Receipt', style: GoogleFonts.inter(fontSize: 11, color: Colors.black54)),
                                              const SizedBox(height: 12),
                                              ElevatedButton.icon(
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: const Color(0xFF2E7D32),
                                                  foregroundColor: Colors.white,
                                                  elevation: 0,
                                                  minimumSize: const Size.fromHeight(40),
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                ),
                                                onPressed: () => _launchUrl(order.receiptUrl!),
                                                icon: const Icon(Icons.picture_as_pdf, size: 14),
                                                label: Text('VIEW RECEIPT', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold)),
                                              ),
                                            ] else ...[
                                              Text('Receipt not available.', style: GoogleFonts.inter(fontSize: 12, color: Colors.black38)),
                                              const SizedBox(height: 12),
                                              ElevatedButton.icon(
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.black,
                                                  foregroundColor: Colors.white,
                                                  elevation: 0,
                                                  minimumSize: const Size.fromHeight(40),
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                ),
                                                onPressed: () async {
                                                  final generator = ReceiptGeneratorService();
                                                  final url = await generator.generateAndUploadReceipt(order);
                                                  _launchUrl(url);
                                                },
                                                icon: const Icon(Icons.download, size: 14),
                                                label: Text('GENERATE RECEIPT', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold)),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    // Invoice block
                                    Expanded(
                                      child: Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          border: Border.all(color: const Color(0xFFEEEEEE)),
                                          borderRadius: BorderRadius.circular(12),
                                          color: const Color(0xFFFAFAFA),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text('Invoice', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold)),
                                            const SizedBox(height: 6),
                                            if (order.invoiceUrl != null && order.invoiceUrl!.isNotEmpty) ...[
                                              Text('Official PDF Invoice', style: GoogleFonts.inter(fontSize: 11, color: Colors.black54)),
                                              const SizedBox(height: 12),
                                              ElevatedButton.icon(
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: const Color(0xFF1565C0),
                                                  foregroundColor: Colors.white,
                                                  elevation: 0,
                                                  minimumSize: const Size.fromHeight(40),
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                ),
                                                onPressed: () => _handleCustomerInvoiceView(context, order),
                                                icon: const Icon(Icons.description, size: 14),
                                                label: Text('VIEW INVOICE', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold)),
                                              ),
                                            ] else ...[
                                              Text('Invoice not yet available.', style: GoogleFonts.inter(fontSize: 12, color: Colors.black38)),
                                              const SizedBox(height: 12),
                                              ElevatedButton.icon(
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.grey.shade300,
                                                  foregroundColor: Colors.black38,
                                                  elevation: 0,
                                                  minimumSize: const Size.fromHeight(40),
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                ),
                                                onPressed: null,
                                                icon: const Icon(Icons.lock_outline, size: 14),
                                                label: Text('NOT YET AVAILABLE', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold)),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                        ],
                      ),
                    ),
                  ),
                ),

                const HZFooter(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTimeline(CustomerOrder order, bool isMobile) {
    final stages = order.timeline;
    final rcv = stages.firstWhere((t) => t.stageName == 'Order Received', orElse: () => const OrderTimelineStage(stageName: 'Order Received', isCompleted: true));
    final cnf = stages.firstWhere((t) => t.stageName == 'Order Confirmed', orElse: () => const OrderTimelineStage(stageName: 'Order Confirmed', isCompleted: false));
    final dsp = stages.firstWhere((t) => t.stageName == 'Dispatched', orElse: () => const OrderTimelineStage(stageName: 'Dispatched', isCompleted: false));

    if (isMobile) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: const Color(0xFFFAFAFA), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFEEEEEE))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Order Progress Timeline', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54)),
            const SizedBox(height: 16),
            _tVerticalStep('Order Received', rcv.isCompleted, rcv.timestamp),
            _tVerticalConn(cnf.isCompleted),
            _tVerticalStep('Order Confirmed', cnf.isCompleted, cnf.timestamp),
            _tVerticalConn(dsp.isCompleted),
            _tVerticalStep('Dispatched', dsp.isCompleted, dsp.timestamp),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: const Color(0xFFFAFAFA), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFEEEEEE))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Order Progress Timeline', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54)),
          const SizedBox(height: 16),
          Row(
            children: [
              _tStep('Order Received', rcv.isCompleted, rcv.timestamp),
              _tConn(cnf.isCompleted),
              _tStep('Order Confirmed', cnf.isCompleted, cnf.timestamp),
              _tConn(dsp.isCompleted),
              _tStep('Dispatched', dsp.isCompleted, dsp.timestamp),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tVerticalStep(String title, bool isDone, DateTime? ts) {
    final timeStr = ts != null ? DateFormat('dd MMM yyyy, hh:mm a').format(ts) : '';
    return Row(
      children: [
        Icon(isDone ? Icons.check_circle : Icons.radio_button_unchecked, color: isDone ? const Color(0xFF2E7D32) : Colors.black26, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: GoogleFonts.inter(fontSize: 13, fontWeight: isDone ? FontWeight.bold : FontWeight.normal, color: isDone ? Colors.black87 : Colors.black38)),
              if (timeStr.isNotEmpty) Text(timeStr, style: GoogleFonts.inter(fontSize: 11, color: Colors.black45)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _tVerticalConn(bool isDone) {
    return Container(
      margin: const EdgeInsets.only(left: 9, top: 4, bottom: 4),
      width: 2,
      height: 20,
      color: isDone ? const Color(0xFF2E7D32) : const Color(0xFFDDDDDD),
    );
  }

  Widget _tStep(String title, bool isDone, DateTime? ts) {
    final timeStr = ts != null ? DateFormat('dd MMM, hh:mm a').format(ts) : '';
    return Expanded(
      child: Column(
        children: [
          Icon(isDone ? Icons.check_circle : Icons.radio_button_unchecked, color: isDone ? const Color(0xFF2E7D32) : Colors.black26, size: 22),
          const SizedBox(height: 6),
          Text(title, style: GoogleFonts.inter(fontSize: 12, fontWeight: isDone ? FontWeight.bold : FontWeight.normal, color: isDone ? Colors.black87 : Colors.black38), textAlign: TextAlign.center),
          if (timeStr.isNotEmpty) Text(timeStr, style: GoogleFonts.inter(fontSize: 10, color: Colors.black45), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _tConn(bool isDone) {
    return Container(width: 40, height: 2, color: isDone ? const Color(0xFF2E7D32) : const Color(0xFFDDDDDD));
  }

}
