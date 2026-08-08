import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/order_model.dart';
import '../../services/order_service.dart';
import '../../services/auth_service.dart';
import '../../services/order_lock_service.dart';
import '../../services/receipt_generator_service.dart';
import '../../widgets/whatsapp_message_centre_dialog.dart';
import '../../services/cloudinary_service.dart';

class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> {
  final _service = OrderService();
  final _searchCtrl = TextEditingController();
  String _activeFilter = 'All Orders'; // 'All Orders', 'Pending Payment', 'Order Received', 'Confirmed', 'Dispatched', 'Rejected', 'Today', 'This Month'
  String _sortOption = 'Newest First'; // 'Newest First', 'Oldest First'

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<CustomerOrder> _filterAndSort(List<CustomerOrder> orders) {
    final query = _searchCtrl.text.trim().toLowerCase();
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final monthStart = DateTime(now.year, now.month, 1);

    var filtered = orders.where((o) {
      // 1. Search Query Filter
      if (query.isNotEmpty) {
        final awb = o.dispatchInfo?.awbNumber.toLowerCase() ?? '';
        final matchesQuery = o.id.toLowerCase().contains(query) ||
            o.customerName.toLowerCase().contains(query) ||
            o.companyName.toLowerCase().contains(query) ||
            o.phoneNumber.toLowerCase().contains(query) ||
            o.whatsAppNumber.toLowerCase().contains(query) ||
            o.paymentInfo.utrNumber.toLowerCase().contains(query) ||
            awb.contains(query);
        if (!matchesQuery) return false;
      }

      // 2. Status / Category Filter
      if (_activeFilter == 'Pending Payment') return o.status == 'Pending Payment';
      if (_activeFilter == 'Order Received') return o.status == 'Order Received';
      if (_activeFilter == 'Confirmed') return o.status == 'Confirmed';
      if (_activeFilter == 'Dispatched') return o.status == 'Dispatched';
      if (_activeFilter == 'Rejected') return o.status == 'Rejected';
      if (_activeFilter == 'Today') return o.orderDate.isAfter(todayStart);
      if (_activeFilter == 'This Month') return o.orderDate.isAfter(monthStart);

      return true;
    }).toList();

    // 3. Sorting
    if (_sortOption == 'Oldest First') {
      filtered.sort((a, b) => a.orderDate.compareTo(b.orderDate));
    } else {
      filtered.sort((a, b) => b.orderDate.compareTo(a.orderDate));
    }

    return filtered;
  }

  Future<void> _launchUrl(String url) async {
    if (url.isEmpty) return;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label copied to clipboard!', style: GoogleFonts.inter()), backgroundColor: Colors.black),
    );
  }

  // ── CONFIRM ORDER DIALOG ──────────────────────────────────────────────────
  void _showConfirmOrderDialog(CustomerOrder order) {
    bool isSubmitting = false;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Confirm Order?', style: GoogleFonts.cormorantGaramond(fontWeight: FontWeight.bold, fontSize: 24)),
          content: Text(
            'Are you sure you want to confirm order #${order.id}?',
            style: GoogleFonts.inter(fontSize: 14, color: Colors.black87),
          ),
          actions: [
            TextButton(
              onPressed: isSubmitting ? null : () => Navigator.pop(ctx),
              child: Text('Cancel', style: GoogleFonts.inter(color: Colors.black54)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: isSubmitting
                  ? null
                  : () async {
                      setState(() => isSubmitting = true);
                      final adminEmail = AuthService().currentUser?.email ?? 'Admin User';
                      await _service.confirmOrder(orderId: order.id, adminUser: adminEmail);
                      if (ctx.mounted) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          SnackBar(content: Text('Order #${order.id} confirmed successfully!', style: GoogleFonts.inter()), backgroundColor: const Color(0xFF2E7D32)),
                        );
                      }
                    },
              child: isSubmitting
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)))
                  : Text('Confirm', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  // ── REJECT ORDER DIALOG (BEFORE & AFTER CONFIRMATION) ─────────────────────
  void _showRejectOrderDialog(CustomerOrder order) {
    final reasonCtrl = TextEditingController();
    final customTimelineCtrl = TextEditingController();
    final adminNoteCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool refundRequired = false;
    String selectedTimeline = '2 Working Days';
    bool isSubmitting = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Reject Order?', style: GoogleFonts.cormorantGaramond(fontWeight: FontWeight.bold, fontSize: 24)),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('This order will be marked as rejected.', style: GoogleFonts.inter(fontSize: 13, color: Colors.black54)),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: reasonCtrl,
                    minLines: 3,
                    maxLines: 5,
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Rejection reason is required' : null,
                    decoration: InputDecoration(
                      labelText: 'Rejection Reason *',
                      hintText: 'e.g. Stock unavailable / Invalid payment details.',
                      labelStyle: GoogleFonts.inter(fontSize: 13, color: Colors.black54),
                      filled: true,
                      fillColor: const Color(0xFFFAFAFA),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFDDDDDD))),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Refund Required Switch
                  Row(
                    children: [
                      Text('Refund Required?', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
                      const Spacer(),
                      Switch(
                        value: refundRequired,
                        activeThumbColor: const Color(0xFFD32F2F),
                        onChanged: (val) => setState(() => refundRequired = val),
                      ),
                    ],
                  ),

                  // Refund Timeline Dropdown
                  if (refundRequired) ...[
                    const SizedBox(height: 12),
                    Text('Refund Timeline', style: GoogleFonts.inter(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      initialValue: selectedTimeline,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFFFAFAFA),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFDDDDDD))),
                      ),
                      items: ['Within 24 Hours', '2 Working Days', '5 Working Days', '7 Working Days', 'Custom']
                          .map((t) => DropdownMenuItem(value: t, child: Text(t, style: GoogleFonts.inter(fontSize: 13))))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => selectedTimeline = val);
                      },
                    ),
                    if (selectedTimeline == 'Custom') ...[
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: customTimelineCtrl,
                        decoration: InputDecoration(
                          labelText: 'Custom Refund Timeline',
                          hintText: 'e.g. 10 Working Days',
                          filled: true,
                          fillColor: const Color(0xFFFAFAFA),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ],
                  ],

                  const SizedBox(height: 14),
                  TextFormField(
                    controller: adminNoteCtrl,
                    minLines: 2,
                    maxLines: 4,
                    decoration: InputDecoration(
                      labelText: 'Additional Admin Note (Optional)',
                      hintText: 'Internal note for team reference...',
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
                      final adminEmail = AuthService().currentUser?.email ?? 'Admin User';
                      final finalTimeline = selectedTimeline == 'Custom' ? customTimelineCtrl.text.trim() : selectedTimeline;

                      await _service.rejectOrder(
                        orderId: order.id,
                        refundRequired: refundRequired,
                        refundTimeline: finalTimeline,
                        reason: reasonCtrl.text.trim(),
                        adminNote: adminNoteCtrl.text.trim(),
                        adminUser: adminEmail,
                      );

                      if (ctx.mounted) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          SnackBar(content: Text('Order #${order.id} rejected and reason recorded', style: GoogleFonts.inter()), backgroundColor: Colors.red),
                        );
                      }
                    },
              child: isSubmitting
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)))
                  : Text('Reject Order', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  // ── DISPATCH ORDER DIALOG ─────────────────────────────────────────────────
  void _showDispatchOrderDialog(CustomerOrder order) {
    final courierCtrl = TextEditingController();
    final awbCtrl = TextEditingController();
    final trackingCtrl = TextEditingController();
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
          title: Text('Dispatch Order?', style: GoogleFonts.cormorantGaramond(fontWeight: FontWeight.bold, fontSize: 24)),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Enter courier dispatch details for Order #${order.id}:', style: GoogleFonts.inter(fontSize: 13, color: Colors.black54)),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: courierCtrl,
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Courier company is required' : null,
                    decoration: InputDecoration(
                      labelText: 'Courier Company *',
                      hintText: 'e.g. Delhivery, BlueDart, DTDC, India Post',
                      filled: true,
                      fillColor: const Color(0xFFFAFAFA),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: awbCtrl,
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Consignment / AWB Number is required' : null,
                    decoration: InputDecoration(
                      labelText: 'Consignment / AWB Number *',
                      hintText: 'e.g. 148294028492',
                      filled: true,
                      fillColor: const Color(0xFFFAFAFA),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: trackingCtrl,
                    decoration: InputDecoration(
                      labelText: 'Tracking URL (Optional)',
                      hintText: 'e.g. https://www.delhivery.com/track/pkg/148294028492',
                      filled: true,
                      fillColor: const Color(0xFFFAFAFA),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: noteCtrl,
                    minLines: 2,
                    maxLines: 4,
                    decoration: InputDecoration(
                      labelText: 'Additional Dispatch Note (Optional)',
                      hintText: 'e.g. Packed in 2 separate parcels.',
                      filled: true,
                      fillColor: const Color(0xFFFAFAFA),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
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
                backgroundColor: const Color(0xFF1565C0),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: isSubmitting
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setState(() => isSubmitting = true);
                      final adminEmail = AuthService().currentUser?.email ?? 'Admin User';

                      await _service.dispatchOrder(
                        orderId: order.id,
                        courierCompany: courierCtrl.text.trim(),
                        awbNumber: awbCtrl.text.trim(),
                        trackingUrl: trackingCtrl.text.trim(),
                        additionalNote: noteCtrl.text.trim(),
                        adminUser: adminEmail,
                      );

                      if (ctx.mounted) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          SnackBar(content: Text('Order #${order.id} marked as Dispatched!', style: GoogleFonts.inter()), backgroundColor: const Color(0xFF1565C0)),
                        );
                      }
                    },
              child: isSubmitting
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)))
                  : Text('Dispatch', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _showMessageCentre(CustomerOrder order) {
    WhatsAppMessageCentreDialog.show(context, order);
  }

  void _showDeleteOrderDialog(CustomerOrder order) {
    final currentAdmin = AuthService().currentUser?.email ?? 'Admin User';
    bool isDeleting = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text('Delete Order?', style: GoogleFonts.cormorantGaramond(fontWeight: FontWeight.bold, fontSize: 22, color: const Color(0xFFD32F2F))),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Are you sure you want to delete this order? This action cannot be undone.',
                  style: GoogleFonts.inter(fontSize: 13, height: 1.5, color: Colors.black87),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAFAFA),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFEEEEEE)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Order ID: #${order.id}', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('Customer: ${order.customerName}', style: GoogleFonts.inter(fontSize: 12)),
                      const SizedBox(height: 4),
                      Text('Order Amount: ₹${order.grandTotal.toStringAsFixed(0)}', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: isDeleting ? null : () => Navigator.pop(dialogCtx),
                child: Text('CANCEL', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54)),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD32F2F),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: isDeleting
                    ? null
                    : () async {
                        setDialogState(() => isDeleting = true);
                        try {
                          await _service.deleteOrder(
                            orderId: order.id,
                            adminUser: currentAdmin,
                          );
                          if (dialogCtx.mounted) {
                            Navigator.pop(dialogCtx);
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text('Order #${order.id} deleted successfully.', style: GoogleFonts.inter()),
                              backgroundColor: const Color(0xFFD32F2F),
                            ));
                          }
                        } catch (e) {
                          setDialogState(() => isDeleting = false);
                          if (dialogCtx.mounted) {
                            ScaffoldMessenger.of(dialogCtx).showSnackBar(SnackBar(
                              content: Text('Failed to delete order: $e', style: GoogleFonts.inter()),
                              backgroundColor: const Color(0xFFD32F2F),
                            ));
                          }
                        }
                      },
                child: isDeleting
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)))
                    : Text('DELETE ORDER', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showGenerateReceipt(CustomerOrder order) async {
    final generator = ReceiptGeneratorService();
    bool isGenerating = false;
    String? currentUrl = order.receiptUrl;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final urlAvailable = currentUrl != null && currentUrl!.isNotEmpty;

          return AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text('Order Summary Receipt — #${order.id}', style: GoogleFonts.cormorantGaramond(fontWeight: FontWeight.bold, fontSize: 22)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Receipt Number: ${order.receiptNumber ?? "HZR (Auto-generated)"}', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text('Customer: ${order.customerName}', style: GoogleFonts.inter(fontSize: 12, color: Colors.black54)),
                Text('Grand Total: ₹${order.grandTotal.toStringAsFixed(0)}', style: GoogleFonts.inter(fontSize: 12, color: Colors.black54)),
                const SizedBox(height: 16),
                if (urlAvailable) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle, color: Color(0xFF2E7D32), size: 18),
                        const SizedBox(width: 8),
                        Expanded(child: Text('Receipt PDF generated & ready.', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF2E7D32)))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => _launchUrl(currentUrl!),
                        icon: const Icon(Icons.visibility, size: 16),
                        label: const Text('View / Download'),
                      ),
                      const Spacer(),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white),
                        onPressed: isGenerating
                            ? null
                            : () async {
                                setDialogState(() => isGenerating = true);
                                try {
                                  final url = await generator.generateAndUploadReceipt(order, isRegeneration: true);
                                  setDialogState(() {
                                    isGenerating = false;
                                    currentUrl = url;
                                  });
                                } catch (e) {
                                  setDialogState(() => isGenerating = false);
                                  if (dialogCtx.mounted) {
                                    ScaffoldMessenger.of(dialogCtx).showSnackBar(SnackBar(
                                      content: Text('Receipt generation failed: $e', style: GoogleFonts.inter()),
                                      backgroundColor: Colors.red.shade700,
                                      duration: const Duration(seconds: 6),
                                    ));
                                  }
                                }
                              },
                        icon: const Icon(Icons.refresh, size: 16),
                        label: const Text('Regenerate'),
                      ),
                    ],
                  ),
                ] else ...[
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32), foregroundColor: Colors.white, minimumSize: const Size.fromHeight(44)),
                    onPressed: isGenerating
                        ? null
                        : () async {
                            setDialogState(() => isGenerating = true);
                            try {
                              final url = await generator.generateAndUploadReceipt(order);
                              setDialogState(() {
                                isGenerating = false;
                                currentUrl = url;
                              });
                            } catch (e) {
                              setDialogState(() => isGenerating = false);
                              if (dialogCtx.mounted) {
                                ScaffoldMessenger.of(dialogCtx).showSnackBar(SnackBar(
                                  content: Text('Receipt generation failed: $e', style: GoogleFonts.inter()),
                                  backgroundColor: Colors.red.shade700,
                                  duration: const Duration(seconds: 6),
                                ));
                              }
                            }
                          },
                    icon: isGenerating
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)))
                        : const Icon(Icons.picture_as_pdf, size: 18),
                    label: Text(isGenerating ? 'Generating System Receipt...' : 'Generate Official Receipt (PDF)', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Close')),
            ],
          );
        },
      ),
    );
  }

  void _showUploadInvoice(CustomerOrder order) {
    final firestore = FirebaseFirestore.instance;
    bool isUploading = false;
    String? currentInvoiceUrl = order.invoiceUrl;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final invoiceAvailable = currentInvoiceUrl != null && currentInvoiceUrl!.isNotEmpty;

          return AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text('Final Tax Invoice — #${order.id}', style: GoogleFonts.cormorantGaramond(fontWeight: FontWeight.bold, fontSize: 22)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Upload official PDF invoice for Order #${order.id}. Accepts PDF format up to 10MB.', style: GoogleFonts.inter(fontSize: 12, color: Colors.black54)),
                const SizedBox(height: 16),
                if (invoiceAvailable) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: const Color(0xFFE3F2FD), borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      children: [
                        const Icon(Icons.description, color: Color(0xFF1565C0), size: 18),
                        const SizedBox(width: 8),
                        Expanded(child: Text('Invoice PDF uploaded & available to customer.', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF1565C0)))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => _launchUrl(currentInvoiceUrl!),
                        icon: const Icon(Icons.visibility, size: 14),
                        label: const Text('View Invoice'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () async {
                          final res = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf'], withData: true);
                          if (res == null || res.files.isEmpty || res.files.first.bytes == null) return;
                          final f = res.files.first;
                          if (f.size > 10 * 1024 * 1024) {
                            if (dialogCtx.mounted) {
                              ScaffoldMessenger.of(dialogCtx).showSnackBar(const SnackBar(content: Text('File exceeds maximum size limit of 10MB.')));
                            }
                            return;
                          }
                          setDialogState(() => isUploading = true);
                          try {
                            final url = await CloudinaryService().uploadFile(
                              bytes: f.bytes!,
                              filename: '${order.id}_invoice.pdf',
                              folder: 'hashzone/invoices',
                              resourceType: 'raw',
                            ).timeout(const Duration(seconds: 30));
                            await firestore.collection('orders').doc(order.id).set({'invoiceUrl': url}, SetOptions(merge: true));
                            setDialogState(() {
                              isUploading = false;
                              currentInvoiceUrl = url;
                            });
                          } catch (e) {
                            setDialogState(() => isUploading = false);
                            if (dialogCtx.mounted) {
                              ScaffoldMessenger.of(dialogCtx).showSnackBar(SnackBar(
                                content: Text('Invoice upload failed: $e', style: GoogleFonts.inter()),
                                backgroundColor: Colors.red.shade700,
                                duration: const Duration(seconds: 6),
                              ));
                            }
                          }
                        },
                        icon: const Icon(Icons.edit, size: 14),
                        label: const Text('Replace Invoice'),
                      ),
                      TextButton.icon(
                        style: TextButton.styleFrom(foregroundColor: Colors.red),
                        onPressed: () async {
                          await firestore.collection('orders').doc(order.id).set({'invoiceUrl': FieldValue.delete()}, SetOptions(merge: true));
                          setDialogState(() => currentInvoiceUrl = null);
                        },
                        icon: const Icon(Icons.delete_outline, size: 14),
                        label: const Text('Delete'),
                      ),
                    ],
                  ),
                ] else ...[
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white, minimumSize: const Size.fromHeight(44)),
                    onPressed: isUploading
                        ? null
                        : () async {
                            final res = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf'], withData: true);
                            if (res == null || res.files.isEmpty || res.files.first.bytes == null) return;
                            final f = res.files.first;
                            if (f.size > 10 * 1024 * 1024) {
                              if (dialogCtx.mounted) {
                                ScaffoldMessenger.of(dialogCtx).showSnackBar(const SnackBar(content: Text('File exceeds maximum size limit of 10MB.')));
                              }
                              return;
                            }
                            setDialogState(() => isUploading = true);
                            try {
                              final url = await CloudinaryService().uploadFile(
                                bytes: f.bytes!,
                                filename: '${order.id}_invoice.pdf',
                                folder: 'hashzone/invoices',
                                resourceType: 'raw',
                              ).timeout(const Duration(seconds: 30));
                              await firestore.collection('orders').doc(order.id).set({'invoiceUrl': url}, SetOptions(merge: true));
                              setDialogState(() {
                                isUploading = false;
                                currentInvoiceUrl = url;
                              });
                            } catch (e) {
                              setDialogState(() => isUploading = false);
                              if (dialogCtx.mounted) {
                                ScaffoldMessenger.of(dialogCtx).showSnackBar(SnackBar(
                                  content: Text('Invoice upload failed: $e', style: GoogleFonts.inter()),
                                  backgroundColor: Colors.red.shade700,
                                  duration: const Duration(seconds: 6),
                                ));
                              }
                            }
                          },
                    icon: isUploading
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)))
                        : const Icon(Icons.upload_file, size: 18),
                    label: Text(isUploading ? 'Uploading Invoice...' : 'Upload PDF Invoice', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Close')),
            ],
          );
        },
      ),
    );
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
          'ORDER MANAGEMENT SYSTEM',
          style: GoogleFonts.cormorantGaramond(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            letterSpacing: 2.5,
            color: Colors.white,
          ),
        ),
      ),
      body: FutureBuilder<OrderDashboardSummary>(
        future: _service.getOrdersDashboardSummary(),
        builder: (context, summarySnap) {
          final summary = summarySnap.data ?? const OrderDashboardSummary();

          return StreamBuilder<List<CustomerOrder>>(
            stream: _service.streamAdminOrders(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
                return const Center(child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.black)));
              }

              final allOrders = snap.data ?? [];
              final filteredOrders = _filterAndSort(allOrders);

              return SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: isDesktop ? 48 : 16, vertical: 32),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1100),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── 1. SUMMARY CARDS GRID ────────────────────────────
                        _buildSummaryCards(summary, isDesktop),
                        const SizedBox(height: 32),

                        // ── 2. SEARCH & FILTERS TOOLBAR ──────────────────────
                        _buildToolbar(),
                        const SizedBox(height: 24),

                        // ── 3. ORDERS LIST ───────────────────────────────────
                        if (filteredOrders.isEmpty)
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
                                const Icon(Icons.shopping_bag_outlined, size: 56, color: Colors.black26),
                                const SizedBox(height: 16),
                                Text('No orders found matching your filter criteria.', style: GoogleFonts.inter(fontSize: 14, color: Colors.black45)),
                              ],
                            ),
                          )
                        else
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: filteredOrders.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 24),
                            itemBuilder: (context, i) => _buildOrderCard(filteredOrders[i]),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // ── SUMMARY CARDS GRID ────────────────────────────────────────────────────
  Widget _buildSummaryCards(OrderDashboardSummary summary, bool isDesktop) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: isDesktop ? 3 : 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: isDesktop ? 2.2 : 2.0,
      children: [
        _metricCard('Pending Payment', summary.pendingVerificationCount.toString(), Icons.hourglass_empty, const Color(0xFFF57C00)),
        _metricCard('Pending Confirmation', summary.pendingConfirmationCount.toString(), Icons.inbox, const Color(0xFF0288D1)),
        _metricCard('Orders Today', summary.todayOrdersCount.toString(), Icons.today, Colors.black),
        _metricCard('Revenue Today', '₹${summary.revenueToday.toStringAsFixed(0)}', Icons.payments, const Color(0xFF2E7D32)),
        _metricCard('Revenue This Month', '₹${summary.revenueThisMonth.toStringAsFixed(0)}', Icons.account_balance_wallet, const Color(0xFF2E7D32)),
        _metricCard('Average Order Value', '₹${summary.averageOrderValue.toStringAsFixed(0)}', Icons.analytics_outlined, const Color(0xFF1565C0)),
        _metricCard('Total Customers', summary.totalCustomersCount.toString(), Icons.people_outline, Colors.black),
        _metricCard('Dispatched Orders', summary.dispatchedCount.toString(), Icons.local_shipping_outlined, const Color(0xFF1565C0)),
        _metricCard('Rejected Orders', summary.rejectedCount.toString(), Icons.cancel_outlined, const Color(0xFFD32F2F)),
      ],
    );
  }

  Widget _metricCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Expanded(child: Text(title, style: GoogleFonts.inter(fontSize: 11, color: Colors.black54, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
            ],
          ),
          const SizedBox(height: 8),
          Text(value, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  // ── SEARCH & FILTERS TOOLBAR ──────────────────────────────────────────────
  Widget _buildToolbar() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Search by Order ID, Customer, Phone, UTR, AWB...',
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
                    items: ['Newest First', 'Oldest First']
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
          const SizedBox(height: 16),
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                'All Orders',
                'Pending Payment',
                'Order Received',
                'Confirmed',
                'Dispatched',
                'Rejected',
                'Today',
                'This Month',
              ].map((f) {
                final isSelected = _activeFilter == f;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(f, style: GoogleFonts.inter(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                    selected: isSelected,
                    selectedColor: Colors.black,
                    backgroundColor: const Color(0xFFFAFAFA),
                    labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black87),
                    onSelected: (_) => setState(() => _activeFilter = f),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(CustomerOrder order) {
    final isDesktop = MediaQuery.of(context).size.width >= 800;
    final dateStr = DateFormat('dd MMM yyyy').format(order.orderDate);
    final timeStr = DateFormat('hh:mm a').format(order.orderDate);
    final currentAdmin = AuthService().currentUser?.email ?? 'Admin User';

    return StreamBuilder<OrderLock?>(
      stream: OrderLockService().streamOrderLock(order.id),
      builder: (context, lockSnap) {
        final lock = lockSnap.data;
        final bool isLockedByOther = lock != null && lock.lockedBy != currentAdmin;

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isLockedByOther ? const Color(0xFFFFB74D) : const Color(0xFFEEEEEE),
              width: isLockedByOther ? 2.0 : 1.0,
            ),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Lock Indicator Banner if locked by another admin
              if (isLockedByOther) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8E1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFFE082)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.lock, size: 16, color: Color(0xFFF57C00)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Currently being processed by ${lock.lockedBy}',
                          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFFF57C00)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // ── HEADER ────────────────────────────────────────────────────────
              Row(
                children: [
                  Text('ORDER #${order.id}', style: GoogleFonts.cormorantGaramond(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                  const SizedBox(width: 12),
                  Text('$dateStr at $timeStr', style: GoogleFonts.inter(fontSize: 12, color: Colors.black45)),
                  const Spacer(),
                  _statusBadge(order.status),
                ],
              ),
              const Divider(height: 24, color: Color(0xFFEEEEEE)),

          // ── CUSTOMER & DELIVERY ADDRESS & PAYMENT INFO ────────────────────
          isDesktop
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildCustomerSection(order)),
                    const SizedBox(width: 24),
                    Expanded(child: _buildDeliverySection(order)),
                    const SizedBox(width: 24),
                    Expanded(child: _buildPaymentSection(order)),
                  ],
                )
              : Column(
                  children: [
                    _buildCustomerSection(order),
                    const SizedBox(height: 16),
                    _buildDeliverySection(order),
                    const SizedBox(height: 16),
                    _buildPaymentSection(order),
                  ],
                ),
          const SizedBox(height: 20),

          // ── CUSTOMER NOTE ─────────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFAFAFA),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFEEEEEE)),
            ),
            child: Row(
              children: [
                const Icon(Icons.note_alt_outlined, size: 16, color: Colors.black54),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    order.customerNote.isNotEmpty ? 'Customer Note: ${order.customerNote}' : 'No customer note provided.',
                    style: GoogleFonts.inter(fontSize: 12.5, color: order.customerNote.isNotEmpty ? Colors.black87 : Colors.black45, fontStyle: order.customerNote.isEmpty ? FontStyle.italic : FontStyle.normal),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── PRODUCT TABLE ─────────────────────────────────────────────────
          _buildProductTable(order),
          const SizedBox(height: 16),

          // ── ORDER SUMMARY ─────────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                width: 280,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: const Color(0xFFFAFAFA), borderRadius: BorderRadius.circular(10)),
                child: Column(
                  children: [
                    _sumRow('Subtotal', '₹${order.subtotal.toStringAsFixed(0)}'),
                    _sumRow('Shipping', 'Calculated separately'),
                    if (order.pendingAmount > 0) _sumRow('Pending', '₹${order.pendingAmount.toStringAsFixed(0)}'),
                    const Divider(height: 16),
                    _sumRow('Grand Total', '₹${order.grandTotal.toStringAsFixed(0)}', isBold: true),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── ORDER TIMELINE ────────────────────────────────────────────────
          _buildTimeline(order),
          const SizedBox(height: 20),

          // ── REJECTION / DISPATCH DETAILS (IF ANY) ─────────────────────────
          if (order.isRejected && order.refundInfo != null) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: const Color(0xFFFFF3F3), borderRadius: BorderRadius.circular(10)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Rejection Details', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFFD32F2F))),
                  const SizedBox(height: 4),
                  Text('Reason: ${order.refundInfo!.reason}', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFFD32F2F))),
                  if (order.refundInfo!.refundRequired)
                    Text('Refund Timeline: ${order.refundInfo!.refundTimeline}', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFFD32F2F))),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          if (order.isDispatched && order.dispatchInfo != null) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: const Color(0xFFE3F2FD), borderRadius: BorderRadius.circular(10)),
              child: Row(
                children: [
                  const Icon(Icons.local_shipping_outlined, color: Color(0xFF1565C0), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Courier: ${order.dispatchInfo!.courierCompany} | AWB: ${order.dispatchInfo!.awbNumber}',
                      style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.bold, color: const Color(0xFF1565C0)),
                    ),
                  ),
                  if (order.dispatchInfo!.trackingUrl.isNotEmpty)
                    TextButton(
                      onPressed: () => _launchUrl(order.dispatchInfo!.trackingUrl),
                      child: Text('Track Package', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF1565C0), decoration: TextDecoration.underline)),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // ── ACTION BUTTONS BAR ────────────────────────────────────────────
          const Divider(height: 24, color: Color(0xFFEEEEEE)),
          _buildActionButtons(order, isLockedByOther),
        ],
      ),
    );
  },
);
}

  // Customer Info Section
  Widget _buildCustomerSection(CustomerOrder order) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('CUSTOMER INFORMATION', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black45, letterSpacing: 1.0)),
        const SizedBox(height: 8),
        Text(order.customerName, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
        if (order.companyName.isNotEmpty) Text('Company: ${order.companyName}', style: GoogleFonts.inter(fontSize: 12, color: Colors.black54)),
        Text('Phone: ${order.phoneNumber}', style: GoogleFonts.inter(fontSize: 12, color: Colors.black54)),
        if (order.whatsAppNumber.isNotEmpty) Text('WhatsApp: ${order.whatsAppNumber}', style: GoogleFonts.inter(fontSize: 12, color: Colors.black54)),
        if (order.email.isNotEmpty) Text('Email: ${order.email}', style: GoogleFonts.inter(fontSize: 12, color: Colors.black54)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            OutlinedButton.icon(
              onPressed: () => _launchUrl('tel:${order.phoneNumber}'),
              icon: const Icon(Icons.phone, size: 14),
              label: Text('Call', style: GoogleFonts.inter(fontSize: 11)),
              style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6)),
            ),
            OutlinedButton.icon(
              onPressed: () => _launchUrl('https://wa.me/${order.whatsAppNumber.isNotEmpty ? order.whatsAppNumber : order.phoneNumber}'),
              icon: const Icon(Icons.chat, size: 14),
              label: Text('WhatsApp', style: GoogleFonts.inter(fontSize: 11)),
              style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6)),
            ),
            OutlinedButton.icon(
              onPressed: () => _copyToClipboard(order.phoneNumber, 'Phone Number'),
              icon: const Icon(Icons.copy, size: 14),
              label: Text('Copy', style: GoogleFonts.inter(fontSize: 11)),
              style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6)),
            ),
          ],
        ),
      ],
    );
  }

  // Delivery Section
  Widget _buildDeliverySection(CustomerOrder order) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('DELIVERY ADDRESS', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black45, letterSpacing: 1.0)),
        const SizedBox(height: 8),
        Text(order.shippingAddress.fullAddress, style: GoogleFonts.inter(fontSize: 13, color: Colors.black87, height: 1.5)),
      ],
    );
  }

  // Payment Section
  Widget _buildPaymentSection(CustomerOrder order) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('PAYMENT INFORMATION', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black45, letterSpacing: 1.0)),
        const SizedBox(height: 8),
        Text('Method: ${order.paymentInfo.method}', style: GoogleFonts.inter(fontSize: 12, color: Colors.black87)),
        Text('Amount Paid: ₹${order.paymentInfo.amountPaid.toStringAsFixed(0)}', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87)),
        Text('UTR: ${order.paymentInfo.utrNumber}', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87)),
        Text('Status: ${order.paymentInfo.paymentStatus}', style: GoogleFonts.inter(fontSize: 12, color: Colors.black54)),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: () => _launchUrl(order.paymentInfo.cloudinaryScreenshotUrl),
          icon: const Icon(Icons.open_in_new, size: 14),
          label: Text('View Payment Screenshot', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold)),
          style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6)),
        ),
      ],
    );
  }

  // Product Table
  Widget _buildProductTable(CustomerOrder order) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFEEEEEE)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Table(
        columnWidths: const {
          0: FixedColumnWidth(110),
          1: FlexColumnWidth(2.5),
          2: FlexColumnWidth(1),
          3: FlexColumnWidth(1),
          4: FlexColumnWidth(1),
          5: FlexColumnWidth(1),
        },
        children: [
          TableRow(
            decoration: const BoxDecoration(color: Color(0xFFFAFAFA)),
            children: [
              _th('Image'),
              _th('Product Name'),
              _th('SKU / Code'),
              _th('Size'),
              _th('Qty'),
              _th('Total'),
            ],
          ),
          ...order.items.map((item) => TableRow(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: OutlinedButton(
                      onPressed: () => _launchUrl(item.imageUrl),
                      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4)),
                      child: Text('View Image', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  _td(item.title, isBold: true),
                  _td('${item.sku}\n${item.internalProductCode}'),
                  _td(item.size),
                  _td('${item.quantity}'),
                  _td('₹${item.lineTotal.toStringAsFixed(0)}', isBold: true),
                ],
              )),
        ],
      ),
    );
  }

  Widget _th(String label) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Text(label, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black54)),
    );
  }

  Widget _td(String label, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: isBold ? FontWeight.bold : FontWeight.normal, color: Colors.black87)),
    );
  }

  Widget _sumRow(String label, String val, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          const Spacer(),
          Text(val, style: GoogleFonts.inter(fontSize: isBold ? 14 : 12, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }

  // 3-Stage Timeline
  Widget _buildTimeline(CustomerOrder order) {
    final stages = order.timeline;
    final rcv = stages.firstWhere((t) => t.stageName == 'Order Received', orElse: () => const OrderTimelineStage(stageName: 'Order Received', isCompleted: true));
    final cnf = stages.firstWhere((t) => t.stageName == 'Order Confirmed', orElse: () => const OrderTimelineStage(stageName: 'Order Confirmed', isCompleted: false));
    final dsp = stages.firstWhere((t) => t.stageName == 'Dispatched', orElse: () => const OrderTimelineStage(stageName: 'Dispatched', isCompleted: false));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFFFAFAFA), borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ORDER TIMELINE', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black45, letterSpacing: 1.0)),
          const SizedBox(height: 14),
          Row(
            children: [
              _timelineStep('Order Received', rcv.isCompleted, rcv.timestamp),
              _timelineConnector(cnf.isCompleted),
              _timelineStep('Order Confirmed', cnf.isCompleted, cnf.timestamp),
              _timelineConnector(dsp.isCompleted),
              _timelineStep('Dispatched', dsp.isCompleted, dsp.timestamp),
            ],
          ),
        ],
      ),
    );
  }

  Widget _timelineStep(String title, bool isDone, DateTime? ts) {
    final timeText = ts != null ? DateFormat('dd MMM, hh:mm a').format(ts) : '';
    return Expanded(
      child: Column(
        children: [
          Icon(isDone ? Icons.check_circle : Icons.radio_button_unchecked, color: isDone ? const Color(0xFF2E7D32) : Colors.black26, size: 20),
          const SizedBox(height: 4),
          Text(title, style: GoogleFonts.inter(fontSize: 11, fontWeight: isDone ? FontWeight.bold : FontWeight.normal, color: isDone ? Colors.black87 : Colors.black38), textAlign: TextAlign.center),
          if (timeText.isNotEmpty) Text(timeText, style: GoogleFonts.inter(fontSize: 9, color: Colors.black45), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _timelineConnector(bool isDone) {
    return Container(
      width: 40,
      height: 2,
      color: isDone ? const Color(0xFF2E7D32) : const Color(0xFFDDDDDD),
    );
  }

  // ── ACTION BUTTONS ────────────────────────────────────────────────────────
  Widget _buildActionButtons(CustomerOrder order, [bool isLockedByOther = false]) {
    final isConfirmed = order.isConfirmed || order.isDispatched;

    return Wrap(
      spacing: 12,
      runSpacing: 10,
      children: [
        if (!isConfirmed && !order.isRejected)
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: isLockedByOther ? null : () => _showConfirmOrderDialog(order),
            icon: const Icon(Icons.check_circle_outline, size: 16),
            label: Text('Confirm Order', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12)),
          ),
        if (isConfirmed && !order.isDispatched && !order.isRejected)
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1565C0),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: isLockedByOther ? null : () => _showDispatchOrderDialog(order),
            icon: const Icon(Icons.local_shipping_outlined, size: 16),
            label: Text('Dispatch Order', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12)),
          ),

        // REJECT ORDER MUST EXIST BEFORE AND AFTER CONFIRMATION
        if (!order.isRejected)
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD32F2F),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: isLockedByOther ? null : () => _showRejectOrderDialog(order),
            icon: const Icon(Icons.cancel_outlined, size: 16),
            label: Text('Reject Order', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12)),
          ),

        OutlinedButton.icon(
          onPressed: () => _showMessageCentre(order),
          icon: const Icon(Icons.chat_bubble_outline, size: 16),
          label: Text('Message Centre', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold)),
          style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12)),
        ),
        OutlinedButton.icon(
          onPressed: () => _showGenerateReceipt(order),
          icon: const Icon(Icons.receipt_long, size: 16),
          label: Text('Generate Receipt', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold)),
          style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12)),
        ),
        OutlinedButton.icon(
          onPressed: () => _showUploadInvoice(order),
          icon: const Icon(Icons.upload_file, size: 16),
          label: Text('Upload Invoice', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold)),
          style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12)),
        ),
        OutlinedButton.icon(
          onPressed: isLockedByOther ? null : () => _showDeleteOrderDialog(order),
          icon: const Icon(Icons.delete_outline, size: 16, color: Color(0xFFD32F2F)),
          label: Text('Delete Order', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFFD32F2F))),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            side: const BorderSide(color: Color(0xFFFFCDD2)),
            backgroundColor: const Color(0xFFFFF3F3),
          ),
        ),
      ],
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 6),
          Text(status.toUpperCase(), style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: fg, letterSpacing: 0.8)),
        ],
      ),
    );
  }
}
