import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/payment_verification.dart';
import '../../services/payment_verification_service.dart';
import '../../services/auth_service.dart';

class AdminPaymentVerificationScreen extends StatefulWidget {
  const AdminPaymentVerificationScreen({super.key});

  @override
  State<AdminPaymentVerificationScreen> createState() => _AdminPaymentVerificationScreenState();
}

class _AdminPaymentVerificationScreenState extends State<AdminPaymentVerificationScreen> {
  final _service = PaymentVerificationService();
  final _searchCtrl = TextEditingController();
  String _sortOption = 'Newest First'; // 'Newest First', 'Oldest First', 'Pending First'

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<PaymentVerification> _filterAndSort(List<PaymentVerification> items) {
    final query = _searchCtrl.text.trim().toLowerCase();
    var filtered = items.where((item) {
      if (query.isEmpty) return true;
      final formattedDate = DateFormat('dd MMM yyyy').format(item.submittedTime).toLowerCase();
      return item.orderId.toLowerCase().contains(query) ||
          item.customerName.toLowerCase().contains(query) ||
          item.companyName.toLowerCase().contains(query) ||
          item.phoneNumber.toLowerCase().contains(query) ||
          item.whatsAppNumber.toLowerCase().contains(query) ||
          item.utrNumber.toLowerCase().contains(query) ||
          formattedDate.contains(query);
    }).toList();

    if (_sortOption == 'Oldest First') {
      filtered.sort((a, b) => a.submittedTime.compareTo(b.submittedTime));
    } else if (_sortOption == 'Pending First') {
      filtered.sort((a, b) {
        if (a.isPending && !b.isPending) return -1;
        if (!a.isPending && b.isPending) return 1;
        return b.submittedTime.compareTo(a.submittedTime);
      });
    } else {
      // Newest First
      filtered.sort((a, b) => b.submittedTime.compareTo(a.submittedTime));
    }

    return filtered;
  }

  Future<void> _openScreenshot(String url) async {
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No screenshot URL available', style: GoogleFonts.inter()), backgroundColor: Colors.red),
      );
      return;
    }
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open screenshot URL', style: GoogleFonts.inter()), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showRejectDialog(PaymentVerification item) {
    final reasonCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isSubmitting = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Reject Payment?', style: GoogleFonts.cormorantGaramond(fontWeight: FontWeight.bold, fontSize: 24)),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('This payment will be marked as rejected.', style: GoogleFonts.inter(fontSize: 13, color: Colors.black54)),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: reasonCtrl,
                    minLines: 3,
                    maxLines: 5,
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Rejection reason is required' : null,
                    decoration: InputDecoration(
                      labelText: 'Rejection Reason *',
                      hintText: 'e.g. UTR number not found in bank records / Incorrect amount paid.',
                      labelStyle: GoogleFonts.inter(fontSize: 13, color: Colors.black54),
                      filled: true,
                      fillColor: const Color(0xFFFAFAFA),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFDDDDDD))),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: noteCtrl,
                    minLines: 2,
                    maxLines: 4,
                    decoration: InputDecoration(
                      labelText: 'Additional Admin Note (Optional)',
                      hintText: 'Internal note for reference...',
                      labelStyle: GoogleFonts.inter(fontSize: 13, color: Colors.black54),
                      filled: true,
                      fillColor: const Color(0xFFFAFAFA),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFDDDDDD))),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSubmitting ? null : () => Navigator.pop(ctx),
              child: Text('Cancel', style: GoogleFonts.inter(color: Colors.black54)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD32F2F),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: isSubmitting
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setState(() => isSubmitting = true);
                      try {
                        final adminEmail = AuthService().currentUser?.email ?? 'Admin User';
                        await _service.rejectPayment(
                          id: item.id,
                          reason: reasonCtrl.text.trim(),
                          adminNote: noteCtrl.text.trim(),
                          adminUser: adminEmail,
                        );
                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(content: Text('Payment rejected and status recorded', style: GoogleFonts.inter()), backgroundColor: Colors.red),
                          );
                        }
                      } catch (e) {
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Failed to reject payment: $e', style: GoogleFonts.inter()), backgroundColor: Colors.red),
                          );
                        }
                      }
                    },
              child: isSubmitting
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)))
                  : Text('Reject Payment', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _approvePayment(PaymentVerification item) async {
    try {
      final adminEmail = AuthService().currentUser?.email ?? 'Admin User';
      await _service.approvePayment(id: item.id, adminUser: adminEmail);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment verified! Order #${item.orderId} moved to next stage.', style: GoogleFonts.inter()),
            backgroundColor: const Color(0xFF2E7D32),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to verify payment: $e', style: GoogleFonts.inter()), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF000000),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.go('/admin/dashboard'),
        ),
        title: Text(
          'PAYMENT VERIFICATION',
          style: GoogleFonts.cormorantGaramond(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            letterSpacing: 2.5,
            color: Colors.white,
          ),
        ),
      ),
      body: StreamBuilder<List<PaymentVerification>>(
        stream: _service.streamVerifications(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.black)),
            );
          }

          final allItems = snap.data ?? [];
          final items = _filterAndSort(allItems);

          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: isDesktop ? 48 : 16, vertical: 32),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1000),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Search & Filter Toolbar
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFEEEEEE)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _searchCtrl,
                              onChanged: (_) => setState(() {}),
                              decoration: InputDecoration(
                                hintText: 'Search by Order ID, Customer, Phone, UTR, Date...',
                                hintStyle: GoogleFonts.inter(fontSize: 13, color: Colors.black38),
                                prefixIcon: const Icon(Icons.search, size: 20, color: Colors.black45),
                                filled: true,
                                fillColor: const Color(0xFFFAFAFA),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          DropdownButtonHideUnderline(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFAFAFA),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFFDDDDDD)),
                              ),
                              child: DropdownButton<String>(
                                value: _sortOption,
                                icon: const Icon(Icons.sort, size: 18, color: Colors.black54),
                                style: GoogleFonts.inter(fontSize: 13, color: Colors.black87, fontWeight: FontWeight.w600),
                                items: ['Newest First', 'Oldest First', 'Pending First']
                                    .map((opt) => DropdownMenuItem(value: opt, child: Text(opt)))
                                    .toList(),
                                onChanged: (val) {
                                  if (val != null) setState(() => _sortOption = val);
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Empty State
                    if (items.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(48),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFEEEEEE)),
                        ),
                        child: Column(
                          children: [
                            const Icon(Icons.assignment_turned_in_outlined, size: 56, color: Colors.black26),
                            const SizedBox(height: 16),
                            Text(
                              allItems.isEmpty ? 'No payment submissions found' : 'No records match your search criteria',
                              style: GoogleFonts.inter(fontSize: 15, color: Colors.black45),
                            ),
                          ],
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 20),
                        itemBuilder: (context, i) => _buildCard(items[i]),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCard(PaymentVerification item) {
    final isDesktop = MediaQuery.of(context).size.width >= 700;
    final dateStr = DateFormat('dd MMM yyyy, hh:mm a').format(item.submittedTime);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: item.isPending
              ? const Color(0xFFFFB74D)
              : item.isVerified
                  ? const Color(0xFFA5D6A7)
                  : const Color(0xFFFFCDD2),
          width: 1.5,
        ),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row (Order ID, Date, Badge)
          Row(
            children: [
              Text(
                'ORDER #${item.orderId}',
                style: GoogleFonts.cormorantGaramond(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 1.0),
              ),
              const SizedBox(width: 12),
              Text(
                dateStr,
                style: GoogleFonts.inter(fontSize: 12, color: Colors.black45),
              ),
              const Spacer(),
              _statusBadge(item.paymentStatus),
            ],
          ),
          const Divider(height: 24, color: Color(0xFFEEEEEE)),

          // Details Grid
          isDesktop
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _row('Customer', item.customerName),
                          if (item.companyName.isNotEmpty) _row('Company', item.companyName),
                          _row('Phone', item.phoneNumber),
                          if (item.whatsAppNumber.isNotEmpty) _row('WhatsApp', item.whatsAppNumber),
                          _row('Shipping Address', item.shippingAddress.isNotEmpty ? item.shippingAddress : '—'),
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _row('Method', item.paymentMethod),
                          _row('Amount Paid', '₹${item.amountPaid.toStringAsFixed(0)}'),
                          _row('Transaction / UTR', item.utrNumber, isBold: true),
                          if (item.customerNote.isNotEmpty) _row('Customer Note', item.customerNote),
                          _row('Current Order Status', item.orderStatus),
                        ],
                      ),
                    ),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _row('Customer', item.customerName),
                    if (item.companyName.isNotEmpty) _row('Company', item.companyName),
                    _row('Phone', item.phoneNumber),
                    _row('Amount Paid', '₹${item.amountPaid.toStringAsFixed(0)}'),
                    _row('Transaction / UTR', item.utrNumber, isBold: true),
                    _row('Current Order Status', item.orderStatus),
                  ],
                ),
          const SizedBox(height: 16),

          // Screenshot Button
          OutlinedButton.icon(
            onPressed: () => _openScreenshot(item.cloudinaryUrl),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.black,
              side: const BorderSide(color: Color(0xFFDDDDDD)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            icon: const Icon(Icons.open_in_new, size: 16),
            label: Text('View Screenshot', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold)),
          ),

          // Rejection info if rejected
          if (item.isRejected && item.rejectionReason != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFFFFF3F3), borderRadius: BorderRadius.circular(8)),
              child: Text(
                'Rejection Reason: ${item.rejectionReason}',
                style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFFD32F2F), fontWeight: FontWeight.w600),
              ),
            ),
          ],

          // Approval info if verified
          if (item.isVerified && item.verifiedBy != null) ...[
            const SizedBox(height: 10),
            Text(
              'Verified by ${item.verifiedBy} on ${item.verifiedTime != null ? DateFormat('dd MMM, hh:mm a').format(item.verifiedTime!) : ''}',
              style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF2E7D32), fontWeight: FontWeight.w500),
            ),
          ],

          // Action Buttons (Only enabled if Pending)
          if (item.isPending) ...[
            const SizedBox(height: 20),
            const Divider(height: 1, color: Color(0xFFEEEEEE)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () => _approvePayment(item),
                    icon: const Icon(Icons.check_circle_outline, size: 18),
                    label: Text('Approve Payment', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD32F2F),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () => _showRejectDialog(item),
                    icon: const Icon(Icons.cancel_outlined, size: 18),
                    label: Text('Reject Payment', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _row(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: GoogleFonts.inter(fontSize: 12, color: Colors.black45, fontWeight: FontWeight.w600)),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(String status) {
    Color bg = const Color(0xFFFFF8E1);
    Color fg = const Color(0xFFF57C00);
    IconData icon = Icons.hourglass_top_rounded;

    if (status == 'Verified') {
      bg = const Color(0xFFE8F5E9);
      fg = const Color(0xFF2E7D32);
      icon = Icons.check_circle;
    } else if (status == 'Rejected') {
      bg = const Color(0xFFFFF3F3);
      fg = const Color(0xFFD32F2F);
      icon = Icons.cancel;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 6),
          Text(
            status.toUpperCase(),
            style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: fg, letterSpacing: 0.8),
          ),
        ],
      ),
    );
  }
}
