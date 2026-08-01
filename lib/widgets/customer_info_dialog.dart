import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HZCustomerInfoDialog extends StatefulWidget {
  const HZCustomerInfoDialog({super.key});

  static Future<Map<String, String>?> show(BuildContext context) {
    return showDialog<Map<String, String>>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const HZCustomerInfoDialog(),
    );
  }

  @override
  State<HZCustomerInfoDialog> createState() => _HZCustomerInfoDialogState();
}

class _HZCustomerInfoDialogState extends State<HZCustomerInfoDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      Navigator.of(context).pop({
        'name': _nameCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'note': _noteCtrl.text.trim(),
      });
    }
  }

  InputDecoration _inputDecoration(String label, {String? hint, IconData? icon}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: icon != null ? Icon(icon, size: 18, color: const Color(0xFF555555)) : null,
      labelStyle: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF555555)),
      hintStyle: GoogleFonts.inter(fontSize: 13, color: const Color(0xFFAAAAAA)),
      filled: true,
      fillColor: const Color(0xFFF8F8F8),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.black, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.red.shade700, width: 1.2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.red.shade700, width: 1.5),
      ),
      errorStyle: GoogleFonts.inter(fontSize: 11, color: Colors.red.shade700),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 40,
        vertical: isMobile ? 24 : 40,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: const Color(0xFF25D366),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.chat_bubble_outline_rounded, color: Colors.white, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'ORDER DETAILS',
                          style: GoogleFonts.cormorantGaramond(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: const Icon(Icons.close, color: Color(0xFF555555), size: 20),
                        onPressed: () => Navigator.of(context).pop(),
                        tooltip: 'Cancel',
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Please fill in your details so the store can identify your order.',
                    style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF777777)),
                  ),
                  const SizedBox(height: 24),

                  // Name field (required)
                  TextFormField(
                    controller: _nameCtrl,
                    textCapitalization: TextCapitalization.words,
                    style: GoogleFonts.inter(fontSize: 14, color: Colors.black),
                    decoration: _inputDecoration('Full Name *', hint: 'e.g. Rahul Sharma', icon: Icons.person_outline),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Name is required';
                      if (v.trim().length < 2) return 'Enter a valid name';
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

                  // Phone field (required)
                  TextFormField(
                    controller: _phoneCtrl,
                    keyboardType: TextInputType.phone,
                    style: GoogleFonts.inter(fontSize: 14, color: Colors.black),
                    decoration: _inputDecoration('Phone Number *', hint: 'e.g. 9876543210', icon: Icons.phone_outlined),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Phone number is required';
                      final digits = v.replaceAll(RegExp(r'[^\d]'), '');
                      if (digits.length < 7) return 'Enter a valid phone number';
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

                  // Note field (optional)
                  TextFormField(
                    controller: _noteCtrl,
                    maxLines: 3,
                    minLines: 2,
                    textCapitalization: TextCapitalization.sentences,
                    style: GoogleFonts.inter(fontSize: 14, color: Colors.black),
                    decoration: _inputDecoration('Note (optional)', hint: 'Any special instructions, delivery address, or queries…', icon: Icons.notes_outlined),
                  ),
                  const SizedBox(height: 24),

                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF555555),
                            side: const BorderSide(color: Color(0xFFCCCCCC)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: Text('CANCEL', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: _submit,
                          icon: const Icon(Icons.chat_bubble_outline_rounded, color: Colors.white, size: 16),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF25D366),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            elevation: 0,
                          ),
                          label: Text('CONTINUE TO WHATSAPP', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
