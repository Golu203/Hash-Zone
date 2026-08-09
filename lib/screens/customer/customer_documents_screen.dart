import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/order_model.dart';
import '../../providers/customer_auth_provider.dart';
import '../../services/order_service.dart';
import '../../widgets/navbar.dart';
import '../../widgets/footer.dart';
import '../../widgets/smart_back_button.dart';

class CustomerDocumentsScreen extends StatelessWidget {
  const CustomerDocumentsScreen({super.key});

  Future<void> _launchUrl(String url) async {
    if (url.isEmpty) return;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  /// Rewrites Cloudinary /image/upload/ to /raw/upload/ for PDF files.
  String _toPdfUrl(String url) {
    if (url.contains('/image/upload/')) {
      return url.replaceFirst('/image/upload/', '/raw/upload/');
    }
    return url;
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;
    final service = OrderService();
    final auth = Provider.of<CustomerAuthProvider>(context, listen: false);
    final customerId = auth.firebaseUser?.uid ?? auth.profile?.uid ?? '';

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
                  Text('My Documents', style: GoogleFonts.cormorantGaramond(fontSize: 26, fontWeight: FontWeight.bold)),
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
                    stream: service.streamCustomerOrders(customerId),
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
                                  'Error loading documents',
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
                      // Filter only orders that have at least one document
                      final docOrders = allOrders.where((o) => o.receiptUrl != null || o.invoiceUrl != null).toList();

                      if (docOrders.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 64),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.folder_open_outlined, size: 56, color: Colors.black26),
                                const SizedBox(height: 16),
                                Text('No documents available yet.', style: GoogleFonts.inter(fontSize: 14, color: Colors.black45)),
                                const SizedBox(height: 8),
                                Text('Invoices and receipts will appear here once your orders are confirmed.', style: GoogleFonts.inter(fontSize: 12, color: Colors.black38), textAlign: TextAlign.center),
                              ],
                            ),
                          ),
                        );
                      }

                      return ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: docOrders.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 20),
                        itemBuilder: (context, idx) {
                          final order = docOrders[idx];
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
                                Row(
                                  children: [
                                    Text('Order #${order.id}', style: GoogleFonts.cormorantGaramond(fontSize: 20, fontWeight: FontWeight.bold)),
                                    const SizedBox(width: 10),
                                    Text(dateStr, style: GoogleFonts.inter(fontSize: 12, color: Colors.black45)),
                                  ],
                                ),
                                const Divider(height: 24, color: Color(0xFFEEEEEE)),

                                if (order.receiptUrl != null) ...[
                                  _buildDocRow(
                                    context,
                                    title: 'Official Receipt',
                                    subtitle: order.receiptNumber ?? 'Receipt file',
                                    icon: Icons.receipt_long_outlined,
                                    url: order.receiptUrl!,
                                  ),
                                ],

                                if (order.receiptUrl != null && order.invoiceUrl != null)
                                  const SizedBox(height: 16),

                                if (order.invoiceUrl != null) ...[
                                  _buildDocRow(
                                    context,
                                    title: 'Tax Invoice',
                                    subtitle: 'Official PDF Invoice',
                                    icon: Icons.description_outlined,
                                    url: _toPdfUrl(order.invoiceUrl!),
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
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

  Widget _buildDocRow(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required String url,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F9F9),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 24, color: Colors.black54),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold)),
                Text(subtitle, style: GoogleFonts.inter(fontSize: 11, color: Colors.black45)),
              ],
            ),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => _launchUrl(url),
            icon: const Icon(Icons.visibility, size: 14),
            label: Text('VIEW', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
