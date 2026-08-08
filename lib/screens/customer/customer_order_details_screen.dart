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
class CustomerOrderDetailsScreen extends StatelessWidget {
  final String orderId;

  const CustomerOrderDetailsScreen({super.key, required this.orderId});

  Future<void> _launchUrl(String url) async {
    if (url.isEmpty) return;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
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
      body: FutureBuilder<CustomerOrder?>(
        future: service.getOrderById(orderId),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
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
                      Text('Order Details #${order.id}', style: GoogleFonts.cormorantGaramond(fontSize: 26, fontWeight: FontWeight.bold)),
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
                            child: Row(
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
                          _buildTimeline(order),

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
                                child: Row(
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
                          Row(
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
                                      Text(order.shippingAddress.fullAddress, style: GoogleFonts.inter(fontSize: 13, height: 1.5)),
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
                          Text('DOCUMENTS', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black45, letterSpacing: 1.0)),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 12,
                            runSpacing: 10,
                            children: [
                              // 1. Order Summary Receipt
                              if (order.receiptUrl != null && order.receiptUrl!.isNotEmpty)
                                OutlinedButton.icon(
                                  onPressed: () => _launchUrl(order.receiptUrl!),
                                  icon: const Icon(Icons.picture_as_pdf, size: 14, color: Color(0xFF2E7D32)),
                                  label: Text('Receipt (${order.receiptNumber ?? "HZR"})', style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF2E7D32), fontWeight: FontWeight.bold)),
                                )
                              else
                                OutlinedButton.icon(
                                  onPressed: () async {
                                    final generator = ReceiptGeneratorService();
                                    final url = await generator.generateAndUploadReceipt(order);
                                    _launchUrl(url);
                                  },
                                  icon: const Icon(Icons.download, size: 14),
                                  label: Text('Download Receipt', style: GoogleFonts.inter(fontSize: 11)),
                                ),

                              // 2. Final Invoice (If uploaded by Admin)
                              if (order.invoiceUrl != null && order.invoiceUrl!.isNotEmpty)
                                OutlinedButton.icon(
                                  onPressed: () => _launchUrl(order.invoiceUrl!),
                                  icon: const Icon(Icons.description, size: 14, color: Color(0xFF1565C0)),
                                  label: Text('Tax Invoice (PDF)', style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF1565C0), fontWeight: FontWeight.bold)),
                                ),

                              // 3. Payment Screenshot
                              if (order.paymentInfo.cloudinaryScreenshotUrl.isNotEmpty)
                                OutlinedButton.icon(
                                  onPressed: () => _launchUrl(order.paymentInfo.cloudinaryScreenshotUrl),
                                  icon: const Icon(Icons.image, size: 14, color: Colors.black54),
                                  label: Text('Payment Receipt Screenshot', style: GoogleFonts.inter(fontSize: 11)),
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

  Widget _buildTimeline(CustomerOrder order) {
    final stages = order.timeline;
    final rcv = stages.firstWhere((t) => t.stageName == 'Order Received', orElse: () => const OrderTimelineStage(stageName: 'Order Received', isCompleted: true));
    final cnf = stages.firstWhere((t) => t.stageName == 'Order Confirmed', orElse: () => const OrderTimelineStage(stageName: 'Order Confirmed', isCompleted: false));
    final dsp = stages.firstWhere((t) => t.stageName == 'Dispatched', orElse: () => const OrderTimelineStage(stageName: 'Dispatched', isCompleted: false));

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
