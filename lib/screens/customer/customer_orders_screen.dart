import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/order_model.dart';
import '../../providers/customer_auth_provider.dart';
import '../../services/order_service.dart';
import '../../services/receipt_generator_service.dart';
import '../../widgets/navbar.dart';
import '../../widgets/footer.dart';
import '../../widgets/smart_back_button.dart';

class CustomerOrdersScreen extends StatefulWidget {
  const CustomerOrdersScreen({super.key});

  @override
  State<CustomerOrdersScreen> createState() => _CustomerOrdersScreenState();
}

class _CustomerOrdersScreenState extends State<CustomerOrdersScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _service = OrderService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _launchUrl(String url) async {
    if (url.isEmpty) return;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<CustomerAuthProvider>();
    final customerId = auth.firebaseUser?.uid ?? auth.profile?.uid ?? '';
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const HZNavBar(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Page Header Banner
            Container(
              width: double.infinity,
              color: const Color(0xFFF9F9F9),
              padding: EdgeInsets.symmetric(horizontal: isDesktop ? 64 : 20, vertical: 24),
              child: Row(
                children: [
                  const HZSmartBackButton(fallbackRoute: '/dashboard', label: null),
                  const SizedBox(width: 8),
                  Text('My Orders', style: GoogleFonts.cormorantGaramond(fontSize: 26, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const Divider(height: 1),

            // Content Body
            Padding(
              padding: EdgeInsets.symmetric(horizontal: isDesktop ? 64 : 16, vertical: 32),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: StreamBuilder<List<CustomerOrder>>(
                    stream: _service.streamCustomerOrders(customerId),
                    builder: (context, snap) {
                      if (snap.connectionState == ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.all(48.0),
                          child: Center(child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.black))),
                        );
                      }

                      final allOrders = snap.data ?? [];
                      final currentOrders = allOrders.where((o) => o.status != 'Dispatched' && o.status != 'Rejected').toList();
                      final previousOrders = allOrders.where((o) => o.status == 'Dispatched' || o.status == 'Rejected').toList();

                      return Column(
                        children: [
                          // Tab Bar
                          TabBar(
                            controller: _tabController,
                            indicatorColor: Colors.black,
                            labelColor: Colors.black,
                            unselectedLabelColor: Colors.black45,
                            labelStyle: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14),
                            unselectedLabelStyle: GoogleFonts.inter(fontSize: 14),
                            tabs: [
                              Tab(text: 'Current Orders (${currentOrders.length})'),
                              Tab(text: 'Previous Orders (${previousOrders.length})'),
                            ],
                          ),
                          const SizedBox(height: 24),

                          SizedBox(
                            height: 650,
                            child: TabBarView(
                              controller: _tabController,
                              children: [
                                _buildOrdersList(currentOrders, 'No active orders found.'),
                                _buildOrdersList(previousOrders, 'No past orders found.'),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),

            const HZFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildOrdersList(List<CustomerOrder> orders, String emptyMsg) {
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.shopping_bag_outlined, size: 56, color: Colors.black26),
            const SizedBox(height: 16),
            Text(emptyMsg, style: GoogleFonts.inter(fontSize: 14, color: Colors.black45)),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () => context.go('/'),
              style: OutlinedButton.styleFrom(foregroundColor: Colors.black, side: const BorderSide(color: Colors.black)),
              child: Text('BROWSE PRODUCTS', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12)),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      itemCount: orders.length,
      separatorBuilder: (_, __) => const SizedBox(height: 20),
      itemBuilder: (context, i) => _customerOrderCard(orders[i]),
    );
  }

  Widget _customerOrderCard(CustomerOrder order) {
    final dateStr = DateFormat('dd MMM yyyy').format(order.orderDate);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              Text('Order #${order.id}', style: GoogleFonts.cormorantGaramond(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(width: 10),
              Text(dateStr, style: GoogleFonts.inter(fontSize: 12, color: Colors.black45)),
              const Spacer(),
              _statusBadge(order.status),
            ],
          ),
          const Divider(height: 24, color: Color(0xFFEEEEEE)),

          // Items summary
          ...order.items.map((item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.network(
                        item.imageUrl,
                        width: 44,
                        height: 44,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(width: 44, height: 44, color: const Color(0xFFF0F0F0), child: const Icon(Icons.image_not_supported, size: 18, color: Colors.black26)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.title, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                          Text('Size: ${item.size}  |  Qty: ${item.quantity}', style: GoogleFonts.inter(fontSize: 11, color: Colors.black45)),
                        ],
                      ),
                    ),
                    Text('₹${item.lineTotal.toStringAsFixed(0)}', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold)),
                  ],
                ),
              )),

          const SizedBox(height: 14),

          // Total Row
          Row(
            children: [
              Text('Grand Total:', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold)),
              const SizedBox(width: 6),
              Text('₹${order.grandTotal.toStringAsFixed(0)}', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black)),
            ],
          ),

          const SizedBox(height: 16),

          // ── 3-STAGE CUSTOMER TIMELINE ──────────────────────────────────────
          _buildCustomerTimeline(order),

          // ── REJECTION DETAILS (IF REJECTED) ───────────────────────────────
          if (order.isRejected && order.refundInfo != null) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFFFFF3F3), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFFFCDD2))),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Rejection Details', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFFD32F2F))),
                  const SizedBox(height: 4),
                  Text('Reason: ${order.refundInfo!.reason}', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFFD32F2F))),
                  if (order.refundInfo!.refundRequired)
                    Text('Refund Timeline: ${order.refundInfo!.refundTimeline}', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFFD32F2F))),
                ],
              ),
            ),
          ],

          // ── COURIER & TRACKING DETAILS (IF DISPATCHED) ────────────────────
          if (order.isDispatched && order.dispatchInfo != null) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFFE3F2FD), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFF90CAF9))),
              child: Row(
                children: [
                  const Icon(Icons.local_shipping_outlined, color: Color(0xFF1565C0), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Courier: ${order.dispatchInfo!.courierCompany}', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF1565C0))),
                        Text('AWB: ${order.dispatchInfo!.awbNumber}', style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF1565C0))),
                      ],
                    ),
                  ),
                  if (order.dispatchInfo!.trackingUrl.isNotEmpty)
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1565C0), foregroundColor: Colors.white, elevation: 0),
                      onPressed: () => _launchUrl(order.dispatchInfo!.trackingUrl),
                      child: Text('TRACK', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                ],
              ),
            ),
          ],

          // Customer Note
          if (order.customerNote.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text('Note: ${order.customerNote}', style: GoogleFonts.inter(fontSize: 12, color: Colors.black54, fontStyle: FontStyle.italic)),
          ],

          // ── DOCUMENTS SECTION ──────────────────────────────────────────────
          const Divider(height: 24, color: Color(0xFFEEEEEE)),
          Text('DOCUMENTS', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black45, letterSpacing: 1.0)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
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
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => context.go('/orders/${order.id}'),
              icon: const Icon(Icons.arrow_forward, size: 14),
              label: Text('View Full Order Details', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerTimeline(CustomerOrder order) {
    final stages = order.timeline;
    final rcv = stages.firstWhere((t) => t.stageName == 'Order Received', orElse: () => const OrderTimelineStage(stageName: 'Order Received', isCompleted: true));
    final cnf = stages.firstWhere((t) => t.stageName == 'Order Confirmed', orElse: () => const OrderTimelineStage(stageName: 'Order Confirmed', isCompleted: false));
    final dsp = stages.firstWhere((t) => t.stageName == 'Dispatched', orElse: () => const OrderTimelineStage(stageName: 'Dispatched', isCompleted: false));

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xFFFAFAFA), borderRadius: BorderRadius.circular(10)),
      child: Row(
        children: [
          _tStep('Order Received', rcv.isCompleted, rcv.timestamp),
          _tConn(cnf.isCompleted),
          _tStep('Order Confirmed', cnf.isCompleted, cnf.timestamp),
          _tConn(dsp.isCompleted),
          _tStep('Dispatched', dsp.isCompleted, dsp.timestamp),
        ],
      ),
    );
  }

  Widget _tStep(String title, bool isDone, DateTime? ts) {
    final timeStr = ts != null ? DateFormat('dd MMM').format(ts) : '';
    return Expanded(
      child: Column(
        children: [
          Icon(isDone ? Icons.check_circle : Icons.radio_button_unchecked, color: isDone ? const Color(0xFF2E7D32) : Colors.black26, size: 18),
          const SizedBox(height: 4),
          Text(title, style: GoogleFonts.inter(fontSize: 10, fontWeight: isDone ? FontWeight.bold : FontWeight.normal, color: isDone ? Colors.black87 : Colors.black38), textAlign: TextAlign.center),
          if (timeStr.isNotEmpty) Text(timeStr, style: GoogleFonts.inter(fontSize: 9, color: Colors.black45), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _tConn(bool isDone) {
    return Container(width: 24, height: 2, color: isDone ? const Color(0xFF2E7D32) : const Color(0xFFDDDDDD));
  }

  Widget _statusBadge(String status) {
    Color bg = const Color(0xFFE0F7FA);
    Color fg = const Color(0xFF00838F);
    IconData icon = Icons.inbox;

    if (status == 'Confirmed') {
      bg = const Color(0xFFE8F5E9);
      fg = const Color(0xFF2E7D32);
      icon = Icons.check_circle;
    } else if (status == 'Dispatched') {
      bg = const Color(0xFFE3F2FD);
      fg = const Color(0xFF1565C0);
      icon = Icons.local_shipping;
    } else if (status == 'Rejected') {
      bg = const Color(0xFFFFF3F3);
      fg = const Color(0xFFD32F2F);
      icon = Icons.cancel;
    } else if (status == 'Pending Payment') {
      bg = const Color(0xFFFFF8E1);
      fg = const Color(0xFFF57C00);
      icon = Icons.hourglass_empty;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: fg),
          const SizedBox(width: 4),
          Text(status.toUpperCase(), style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: fg)),
        ],
      ),
    );
  }
}
