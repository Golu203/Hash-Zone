import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/order_model.dart';
import '../../providers/customer_auth_provider.dart';
import '../../services/order_service.dart';
import '../../widgets/navbar.dart';
import '../../widgets/footer.dart';
import '../../widgets/smart_back_button.dart';

class CustomerOrdersScreen extends StatefulWidget {
  const CustomerOrdersScreen({super.key});

  @override
  State<CustomerOrdersScreen> createState() => _CustomerOrdersScreenState();
}

class _CustomerOrdersScreenState extends State<CustomerOrdersScreen> {
  final _service = OrderService();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<CustomerAuthProvider>();
    final customerId = auth.firebaseUser?.uid ?? auth.profile?.uid ?? '';
    final isDesktop = MediaQuery.of(context).size.width >= 1150;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const HZNavBar(),
      endDrawer: !isDesktop ? const HZMobileDrawer() : null,
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
                      if (snap.hasError) {
                        return Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                                const SizedBox(height: 16),
                                Text(
                                  'Error loading orders',
                                  style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red),
                                ),
                                const SizedBox(height: 8),
                                SelectableText(
                                  '${snap.error}',
                                  style: GoogleFonts.inter(fontSize: 12, color: Colors.black54),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      if (snap.connectionState == ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.all(48.0),
                          child: Center(child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.black))),
                        );
                      }

                      final allOrders = snap.data ?? [];
                      return _buildOrdersList(allOrders, 'No orders found.');
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
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: orders.length,
      separatorBuilder: (_, __) => const SizedBox(height: 20),
      itemBuilder: (context, i) => _customerOrderCard(orders[i]),
    );
  }

  Widget _customerOrderCard(CustomerOrder order) {
    final dateStr = DateFormat('dd MMM yyyy').format(order.orderDate);
    final firstItem = order.items.isNotEmpty ? order.items.first : null;
    final totalItems = order.items.fold<int>(0, (sum, item) => sum + item.quantity);
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEEEEE)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Order ID & Date & Status
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Order #${order.id}', style: GoogleFonts.cormorantGaramond(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                  const SizedBox(height: 4),
                  Text(dateStr, style: GoogleFonts.inter(fontSize: 11, color: Colors.black45)),
                ],
              ),
              const Spacer(),
              _statusBadge(order.status),
            ],
          ),
          const Divider(height: 24, color: Color(0xFFEEEEEE)),

          // Product row info
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Primary image
              if (firstItem != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    firstItem.imageUrl,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 60,
                      height: 60,
                      color: const Color(0xFFF0F0F0),
                      child: const Icon(Icons.image_not_supported, size: 20, color: Colors.black26),
                    ),
                  ),
                )
              else
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F0F0),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.shopping_bag_outlined, size: 24, color: Colors.black26),
                ),
              const SizedBox(width: 16),
              // Summary & Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      firstItem != null ? firstItem.title : 'Products summary',
                      style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      totalItems == 1 ? '1 item' : '$totalItems items total',
                      style: GoogleFonts.inter(fontSize: 12, color: Colors.black54),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          '₹${order.grandTotal.toStringAsFixed(0)}',
                          style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F5F5),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            order.paymentInfo.paymentStatus.toUpperCase(),
                            style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w600, color: Colors.black54, letterSpacing: 0.5),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 24, color: Color(0xFFEEEEEE)),

          // Footer: Available documents & View button
          Row(
            children: [
              // Document presence labels
              if (order.receiptUrl != null && order.receiptUrl!.isNotEmpty) ...[
                const Icon(Icons.check_circle_outline, size: 14, color: Color(0xFF2E7D32)),
                const SizedBox(width: 4),
                Text('Receipt Available', style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF2E7D32), fontWeight: FontWeight.w500)),
                const SizedBox(width: 16),
              ],
              if (order.invoiceUrl != null && order.invoiceUrl!.isNotEmpty) ...[
                const Icon(Icons.check_circle_outline, size: 14, color: Color(0xFF1565C0)),
                const SizedBox(width: 4),
                Text('Invoice Available', style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF1565C0), fontWeight: FontWeight.w500)),
              ],
              const Spacer(),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                onPressed: () => context.go('/orders/${order.id}'),
                child: Text('VIEW ORDER', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
              ),
            ],
          ),
        ],
      ),
    );
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
