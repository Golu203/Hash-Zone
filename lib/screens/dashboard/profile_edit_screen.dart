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
  String _businessIdType = 'GST';
  final _businessIdValueCtrl = TextEditingController();
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
    setState(() {
      _businessIdType = profile.businessIdType.isNotEmpty ? profile.businessIdType : 'GST';
      _businessIdValueCtrl.text = profile.businessIdValue;
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _companyCtrl.dispose();
    _phoneCtrl.dispose();
    _waCtrl.dispose();
    _businessIdValueCtrl.dispose();
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
        businessIdType: _businessIdType,
        businessIdValue: _businessIdValueCtrl.text.trim().toUpperCase(),
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
      endDrawer: MediaQuery.of(context).size.width < 1150 ? const HZMobileDrawer() : null,
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
                        if (v.replaceAll(RegExp(r'[^0-9]'), '').length < 10) return 'Enter a valid 10-digit number';
                        return null;
                      }),
                  const SizedBox(height: 18),

                  // Business Identification Selector
                  Text(
                    'Business Identification *',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => setState(() {
                            _businessIdType = 'GST';
                            _formKey.currentState?.validate();
                          }),
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _businessIdType == 'GST' ? Colors.black : const Color(0xFFFAFAFA),
                              border: Border.all(
                                color: _businessIdType == 'GST' ? Colors.black : const Color(0xFFDDDDDD),
                                width: 1.5,
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text(
                                'GST Number',
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: _businessIdType == 'GST' ? Colors.white : Colors.black87,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: InkWell(
                          onTap: () => setState(() {
                            _businessIdType = 'PAN';
                            _formKey.currentState?.validate();
                          }),
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _businessIdType == 'PAN' ? Colors.black : const Color(0xFFFAFAFA),
                              border: Border.all(
                                color: _businessIdType == 'PAN' ? Colors.black : const Color(0xFFDDDDDD),
                                width: 1.5,
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text(
                                'PAN Number',
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: _businessIdType == 'PAN' ? Colors.white : Colors.black87,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  if (_businessIdType == 'GST')
                    _field(
                      'GST Number *',
                      Icons.verified_outlined,
                      _businessIdValueCtrl,
                      hintText: 'e.g. 33AAAAA0000A1Z5',
                      textCapitalization: TextCapitalization.characters,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'GST Number is required';
                        final clean = v.trim().toUpperCase();
                        final gstRegex = RegExp(r'^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[1-9A-Z]{1}Z[0-9A-Z]{1}$');
                        if (!gstRegex.hasMatch(clean)) {
                          return 'Enter a valid 15-character GST format (e.g. 33AAAAA0000A1Z5)';
                        }
                        return null;
                      },
                    )
                  else
                    _field(
                      'PAN Number *',
                      Icons.badge_outlined,
                      _businessIdValueCtrl,
                      hintText: 'e.g. ABCDE1234F',
                      textCapitalization: TextCapitalization.characters,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'PAN Number is required';
                        final clean = v.trim().toUpperCase();
                        final panRegex = RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]{1}$');
                        if (!panRegex.hasMatch(clean)) {
                          return 'Enter a valid 10-character PAN format (e.g. ABCDE1234F)';
                        }
                        return null;
                      },
                    ),
                  const SizedBox(height: 14),

                  _field('WhatsApp Number (Optional)', Icons.chat_outlined, _waCtrl,
                      inputType: TextInputType.phone),
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
    String? hintText,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: inputType,
      textCapitalization: textCapitalization,
      textInputAction: TextInputAction.next,
      validator: validator,
      decoration: _dec(label, icon, hintText: hintText),
    );
  }

  Widget _readOnlyField(String label, String value, IconData icon) {
    return InputDecorator(
      decoration: _dec(label, icon).copyWith(fillColor: const Color(0xFFF5F5F5)),
      child: Text(value, style: GoogleFonts.inter(fontSize: 14, color: Colors.black45)),
    );
  }

  InputDecoration _dec(String label, IconData icon, {String? hintText}) => InputDecoration(
        labelText: label,
        hintText: hintText,
        hintStyle: GoogleFonts.inter(fontSize: 12, color: Colors.black26),
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
