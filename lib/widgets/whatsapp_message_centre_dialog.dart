import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/order_model.dart';
import '../services/whatsapp_message_service.dart';
import '../services/auth_service.dart';

class WhatsAppMessageCentreDialog extends StatefulWidget {
  final CustomerOrder order;

  const WhatsAppMessageCentreDialog({super.key, required this.order});

  static void show(BuildContext context, CustomerOrder order) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => WhatsAppMessageCentreDialog(order: order),
    );
  }

  @override
  State<WhatsAppMessageCentreDialog> createState() => _WhatsAppMessageCentreDialogState();
}

class _WhatsAppMessageCentreDialogState extends State<WhatsAppMessageCentreDialog> {
  final _service = WhatsAppMessageService();
  String _selectedTemplate = 'Order Received'; // 'Order Received', 'Order Confirmed', 'Order Dispatched', 'Order Cancelled', 'Custom Message'

  // Form Controllers
  final _var1Ctrl = TextEditingController(); // Est verification / Exp dispatch / Courier / Cancel Reason / Custom
  final _var2Ctrl = TextEditingController(); // Tracking Number / Refund Timeline
  final _var3Ctrl = TextEditingController(); // Tracking Link
  final _noteCtrl = TextEditingController(); // Additional Note
  final _previewCtrl = TextEditingController();

  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _rebuildPreview();
  }

  @override
  void dispose() {
    _var1Ctrl.dispose();
    _var2Ctrl.dispose();
    _var3Ctrl.dispose();
    _noteCtrl.dispose();
    _previewCtrl.dispose();
    super.dispose();
  }

  void _rebuildPreview() {
    String msg = '';
    if (_selectedTemplate == 'Order Received') {
      msg = _service.buildOrderReceivedMessage(
        order: widget.order,
        estimatedVerificationTime: _var1Ctrl.text.trim(),
        additionalNote: _noteCtrl.text.trim(),
      );
    } else if (_selectedTemplate == 'Order Confirmed') {
      msg = _service.buildOrderConfirmedMessage(
        order: widget.order,
        expectedDispatchDate: _var1Ctrl.text.trim(),
        additionalNote: _noteCtrl.text.trim(),
      );
    } else if (_selectedTemplate == 'Order Dispatched') {
      msg = _service.buildOrderDispatchedMessage(
        order: widget.order,
        courierCompany: _var1Ctrl.text.trim().isNotEmpty ? _var1Ctrl.text.trim() : (widget.order.dispatchInfo?.courierCompany ?? 'Courier Partner'),
        trackingNumber: _var2Ctrl.text.trim().isNotEmpty ? _var2Ctrl.text.trim() : (widget.order.dispatchInfo?.awbNumber ?? 'AWB12345'),
        trackingLink: _var3Ctrl.text.trim().isNotEmpty ? _var3Ctrl.text.trim() : (widget.order.dispatchInfo?.trackingUrl ?? ''),
        additionalNote: _noteCtrl.text.trim(),
      );
    } else if (_selectedTemplate == 'Order Cancelled') {
      msg = _service.buildOrderCancelledMessage(
        order: widget.order,
        reason: _var1Ctrl.text.trim().isNotEmpty ? _var1Ctrl.text.trim() : (widget.order.refundInfo?.reason ?? 'Processing issue'),
        refundTimeline: _var2Ctrl.text.trim().isNotEmpty ? _var2Ctrl.text.trim() : (widget.order.refundInfo?.refundTimeline ?? ''),
        additionalNote: _noteCtrl.text.trim(),
      );
    } else {
      msg = _service.buildCustomMessage(
        order: widget.order,
        customText: _var1Ctrl.text.trim().isNotEmpty ? _var1Ctrl.text.trim() : 'We have an update regarding your order.',
      );
    }

    _previewCtrl.text = msg;
  }

  Future<void> _handleSendWhatsApp() async {
    setState(() => _isSending = true);
    final adminUser = AuthService().currentUser?.email ?? 'Admin User';

    final launched = await _service.sendWhatsAppMessage(
      order: widget.order,
      messageText: _previewCtrl.text.trim(),
      templateType: _selectedTemplate,
      adminUser: adminUser,
    );

    if (mounted) {
      setState(() => _isSending = false);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            launched ? 'WhatsApp opened with pre-filled message!' : 'Could not launch WhatsApp.',
            style: GoogleFonts.inter(),
          ),
          backgroundColor: launched ? const Color(0xFF2E7D32) : Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final isDesktop = w >= 700;

    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      contentPadding: const EdgeInsets.all(24),
      title: Row(
        children: [
          const Icon(Icons.chat_outlined, color: Color(0xFF2E7D32), size: 24),
          const SizedBox(width: 10),
          Text(
            'WhatsApp Message Centre',
            style: GoogleFonts.cormorantGaramond(fontWeight: FontWeight.bold, fontSize: 22),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      content: SizedBox(
        width: isDesktop ? 650 : w * 0.9,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Select Message Template:', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54)),
              const SizedBox(height: 8),

              // Template Selector Chips
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  'Order Received',
                  'Order Confirmed',
                  'Order Dispatched',
                  'Order Cancelled',
                  'Custom Message',
                ].map((t) {
                  final isSel = _selectedTemplate == t;
                  return ChoiceChip(
                    label: Text(t, style: GoogleFonts.inter(fontSize: 11, fontWeight: isSel ? FontWeight.bold : FontWeight.normal)),
                    selected: isSel,
                    selectedColor: const Color(0xFF2E7D32),
                    backgroundColor: const Color(0xFFFAFAFA),
                    labelStyle: TextStyle(color: isSel ? Colors.white : Colors.black87),
                    onSelected: (_) {
                      setState(() {
                        _selectedTemplate = t;
                        _var1Ctrl.clear();
                        _var2Ctrl.clear();
                        _var3Ctrl.clear();
                        _noteCtrl.clear();
                        _rebuildPreview();
                      });
                    },
                  );
                }).toList(),
              ),

              const SizedBox(height: 20),
              const Divider(height: 1, color: Color(0xFFEEEEEE)),
              const SizedBox(height: 16),

              // Template Dynamic Variable Inputs
              _buildVariableInputs(),

              const SizedBox(height: 16),
              Text('Live Editable Message Preview:', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54)),
              const SizedBox(height: 8),

              // Editable Message Preview Area
              TextField(
                controller: _previewCtrl,
                minLines: 8,
                maxLines: 12,
                style: GoogleFonts.inter(fontSize: 13, height: 1.5),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFFF9F9F9),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFDDDDDD))),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 1.5)),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel', style: GoogleFonts.inter(color: Colors.black54)),
        ),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2E7D32),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: _isSending ? null : _handleSendWhatsApp,
          icon: const Icon(Icons.send, size: 16),
          label: _isSending
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)))
              : Text('SEND ON WHATSAPP', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13)),
        ),
      ],
    );
  }

  Widget _buildVariableInputs() {
    if (_selectedTemplate == 'Order Received') {
      return Column(
        children: [
          _field(_var1Ctrl, 'Estimated Verification Time (Optional)', 'e.g. Within 2 Hours'),
          const SizedBox(height: 10),
          _field(_noteCtrl, 'Additional Note (Optional)', 'e.g. Please ensure your payment reference is clear.'),
        ],
      );
    } else if (_selectedTemplate == 'Order Confirmed') {
      return Column(
        children: [
          _field(_var1Ctrl, 'Expected Dispatch Date (Optional)', 'e.g. Tomorrow by 5 PM'),
          const SizedBox(height: 10),
          _field(_noteCtrl, 'Additional Note (Optional)', 'e.g. Preparing for dispatch.'),
        ],
      );
    } else if (_selectedTemplate == 'Order Dispatched') {
      return Column(
        children: [
          _field(_var1Ctrl, 'Courier Company', widget.order.dispatchInfo?.courierCompany ?? 'e.g. Delhivery'),
          const SizedBox(height: 10),
          _field(_var2Ctrl, 'Consignment / Tracking Number', widget.order.dispatchInfo?.awbNumber ?? 'e.g. 148294028492'),
          const SizedBox(height: 10),
          _field(_var3Ctrl, 'Tracking Link (Optional)', widget.order.dispatchInfo?.trackingUrl ?? 'https://...'),
          const SizedBox(height: 10),
          _field(_noteCtrl, 'Additional Note (Optional)', 'e.g. Safe delivery instructions...'),
        ],
      );
    } else if (_selectedTemplate == 'Order Cancelled') {
      return Column(
        children: [
          _field(_var1Ctrl, 'Cancellation Reason', widget.order.refundInfo?.reason ?? 'e.g. Stock unavailable'),
          const SizedBox(height: 10),
          _field(_var2Ctrl, 'Refund Timeline (Optional)', widget.order.refundInfo?.refundTimeline ?? 'e.g. 2 Working Days'),
          const SizedBox(height: 10),
          _field(_noteCtrl, 'Additional Note (Optional)', 'e.g. Contact customer support for details.'),
        ],
      );
    } else {
      // Custom Message
      return Column(
        children: [
          _field(_var1Ctrl, 'Custom Message Body *', 'Type any custom update for this customer...', maxLines: 3),
        ],
      );
    }
  }

  Widget _field(TextEditingController ctrl, String label, String hint, {int maxLines = 1}) {
    return TextFormField(
      controller: ctrl,
      maxLines: maxLines,
      onChanged: (_) => setState(() => _rebuildPreview()),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: GoogleFonts.inter(fontSize: 12, color: Colors.black54),
        filled: true,
        fillColor: const Color(0xFFFAFAFA),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFDDDDDD))),
      ),
    );
  }
}
