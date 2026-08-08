import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/customer_auth_provider.dart';
import '../../services/customer_auth_service.dart';
import '../../widgets/navbar.dart';
import '../../widgets/smart_back_button.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _companyCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _waCtrl = TextEditingController();
  bool _isSaving = false;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _prefill());
  }

  void _prefill() {
    final profile = context.read<CustomerAuthProvider>().profile;
    if (profile == null) return;
    _nameCtrl.text = profile.displayName;
    _companyCtrl.text = profile.companyName;
    _phoneCtrl.text = profile.phoneNumber;
    _waCtrl.text = profile.whatsAppNumber;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _companyCtrl.dispose();
    _phoneCtrl.dispose();
    _waCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isSaving = true; _saved = false; });

    try {
      final auth = context.read<CustomerAuthProvider>();
      final uid = auth.firebaseUser?.uid;
      if (uid == null) return;

      final current = auth.profile!;
      final updated = current.copyWith(
        displayName: _nameCtrl.text.trim(),
        companyName: _companyCtrl.text.trim(),
        phoneNumber: _phoneCtrl.text.trim(),
        whatsAppNumber: _waCtrl.text.trim(),
      );

      await CustomerAuthService().updateProfile(updated);
      if (mounted) setState(() => _saved = true);
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) context.go('/dashboard');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save. Please try again.', style: GoogleFonts.inter()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<CustomerAuthProvider>();
    final isMobile = MediaQuery.of(context).size.width < 700;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const HZNavBar(),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: isMobile ? 20 : 64, vertical: 32),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  Row(
                    children: [
                      const HZSmartBackButton(fallbackRoute: '/dashboard', label: null),
                      const SizedBox(width: 8),
                      Text(
                        'Edit Profile',
                        style: GoogleFonts.cormorantGaramond(fontSize: 26, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // Email (read-only)
                  _readOnlyField('Email Address', auth.firebaseUser?.email ?? '', Icons.email_outlined),
                  const SizedBox(height: 14),

                  _field('Full Name *', Icons.person_outline, _nameCtrl,
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Name is required' : null),
                  const SizedBox(height: 14),
                  _field('Company / Business Name', Icons.business_outlined, _companyCtrl),
                  const SizedBox(height: 14),
                  _field('Mobile Number *', Icons.phone_outlined, _phoneCtrl,
                      inputType: TextInputType.phone,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Mobile number is required';
                        if (v.replaceAll(RegExp(r'[^0-9]'), '').length < 10) return 'Enter a valid number';
                        return null;
                      }),
                  const SizedBox(height: 14),
                  _field('WhatsApp Number *', Icons.chat_outlined, _waCtrl,
                      inputType: TextInputType.phone,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'WhatsApp number is required';
                        if (v.replaceAll(RegExp(r'[^0-9]'), '').length < 10) return 'Enter a valid number';
                        return null;
                      }),
                  const SizedBox(height: 28),

                  // Save Button
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.black38,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: _isSaving
                          ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)))
                          : _saved
                              ? Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                                  const Icon(Icons.check, color: Colors.white, size: 20),
                                  const SizedBox(width: 8),
                                  Text('SAVED!', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 1.2)),
                                ])
                              : Text('SAVE CHANGES', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 1.2)),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextButton(
                    onPressed: () => context.go('/dashboard'),
                    child: Text('Cancel', style: GoogleFonts.inter(fontSize: 13, color: Colors.black54)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(String label, IconData icon, TextEditingController ctrl, {
    String? Function(String?)? validator,
    TextInputType inputType = TextInputType.text,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: inputType,
      textInputAction: TextInputAction.next,
      validator: validator,
      decoration: _dec(label, icon),
    );
  }

  Widget _readOnlyField(String label, String value, IconData icon) {
    return InputDecorator(
      decoration: _dec(label, icon).copyWith(fillColor: const Color(0xFFF5F5F5)),
      child: Text(value, style: GoogleFonts.inter(fontSize: 14, color: Colors.black45)),
    );
  }

  InputDecoration _dec(String label, IconData icon) => InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.inter(fontSize: 13, color: Colors.black54),
        prefixIcon: Icon(icon, size: 18, color: Colors.black54),
        filled: true,
        fillColor: const Color(0xFFFAFAFA),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFDDDDDD))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFDDDDDD))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.black, width: 1.5)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFD32F2F))),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFD32F2F), width: 1.5)),
      );
}
