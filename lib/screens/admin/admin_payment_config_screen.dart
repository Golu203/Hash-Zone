import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/payment_config_service.dart';

class AdminPaymentConfigScreen extends StatefulWidget {
  const AdminPaymentConfigScreen({super.key});

  @override
  State<AdminPaymentConfigScreen> createState() => _AdminPaymentConfigScreenState();
}

class _AdminPaymentConfigScreenState extends State<AdminPaymentConfigScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = PaymentConfigService();

  final _bankNameCtrl = TextEditingController();
  final _accountNameCtrl = TextEditingController();
  final _accountNumberCtrl = TextEditingController();
  final _ifscCodeCtrl = TextEditingController();
  final _branchNameCtrl = TextEditingController();
  final _instructionsCtrl = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;
  String? _success;

  @override
  void initState() {
    super.initState();
    _loadExistingConfig();
  }

  Future<void> _loadExistingConfig() async {
    setState(() => _isLoading = true);
    try {
      final config = await _service.getConfig();
      _bankNameCtrl.text = config.bankName;
      _accountNameCtrl.text = config.accountName;
      _accountNumberCtrl.text = config.accountNumber;
      _ifscCodeCtrl.text = config.ifscCode;
      _branchNameCtrl.text = config.branchName;
      _instructionsCtrl.text = config.paymentInstructions;
    } catch (e) {
      _error = 'Failed to load payment configuration: $e';
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _bankNameCtrl.dispose();
    _accountNameCtrl.dispose();
    _accountNumberCtrl.dispose();
    _ifscCodeCtrl.dispose();
    _branchNameCtrl.dispose();
    _instructionsCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveConfiguration() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _error = null;
      _success = null;
    });

    try {
      final config = PaymentConfig(
        bankName: _bankNameCtrl.text.trim(),
        accountName: _accountNameCtrl.text.trim(),
        accountNumber: _accountNumberCtrl.text.trim(),
        ifscCode: _ifscCodeCtrl.text.trim(),
        branchName: _branchNameCtrl.text.trim(),
        paymentInstructions: _instructionsCtrl.text.trim(),
        isConfigured: true,
      );

      await _service.saveConfig(config);
      if (mounted) {
        setState(() {
          _success = 'Payment configuration saved & live on Checkout!';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'Failed to save configuration: $e');
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
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
          'PAYMENT CONFIGURATION',
          style: GoogleFonts.cormorantGaramond(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            letterSpacing: 2.5,
            color: Colors.white,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
              ),
            )
          : SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 48 : 16,
                vertical: 32,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Notification Banners
                        if (_error != null) _buildAlert(_error!, isError: true),
                        if (_success != null) _buildAlert(_success!, isError: false),

                        // Section 1: Bank Transfer Details
                        _buildCard(
                          title: 'BANK TRANSFER CONFIGURATION',
                          icon: Icons.account_balance,
                          child: Column(
                            children: [
                              _field(_accountNameCtrl, 'Account Holder Name', Icons.person_outline),
                              const SizedBox(height: 12),
                              _field(_bankNameCtrl, 'Bank Name (e.g. State Bank of India, HDFC Bank)', Icons.account_balance_outlined),
                              const SizedBox(height: 12),
                              _field(_accountNumberCtrl, 'Account Number', Icons.numbers),
                              const SizedBox(height: 12),
                              _field(_ifscCodeCtrl, 'IFSC Code', Icons.code),
                              const SizedBox(height: 12),
                              _field(_branchNameCtrl, 'Branch Name (Optional)', Icons.location_on_outlined),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Section 3: Payment Instructions
                        _buildCard(
                          title: 'PAYMENT INSTRUCTIONS FOR CUSTOMERS',
                          icon: Icons.article_outlined,
                          child: Column(
                            children: [
                              TextFormField(
                                controller: _instructionsCtrl,
                                minLines: 3,
                                maxLines: 6,
                                decoration: InputDecoration(
                                  labelText: 'Instructions & Guidelines',
                                  hintText: 'e.g. Please transfer exact order total and upload screenshot with clear 12-digit UTR number.',
                                  labelStyle: GoogleFonts.inter(fontSize: 13, color: Colors.black54),
                                  filled: true,
                                  fillColor: const Color(0xFFFAFAFA),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFDDDDDD))),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Save Button
                        SizedBox(
                          height: 54,
                          child: ElevatedButton(
                            onPressed: _isSaving ? null : _saveConfiguration,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: Colors.black38,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
                            ),
                            child: _isSaving
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)),
                                  )
                                : Text(
                                    'SAVE PAYMENT CONFIGURATION',
                                    style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 1.2),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildCard({required String title, required IconData icon, required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: Colors.black),
              const SizedBox(width: 10),
              Text(
                title,
                style: GoogleFonts.cormorantGaramond(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.0),
              ),
            ],
          ),
          const Divider(height: 24, color: Color(0xFFEEEEEE)),
          child,
        ],
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label, IconData icon) {
    return TextFormField(
      controller: ctrl,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.inter(fontSize: 13, color: Colors.black54),
        prefixIcon: Icon(icon, size: 18, color: Colors.black54),
        filled: true,
        fillColor: const Color(0xFFFAFAFA),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFDDDDDD))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFDDDDDD))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.black, width: 1.5)),
      ),
    );
  }

  Widget _buildAlert(String message, {required bool isError}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isError ? const Color(0xFFFFF3F3) : const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isError ? const Color(0xFFFFCDD2) : const Color(0xFFA5D6A7)),
      ),
      child: Row(
        children: [
          Icon(isError ? Icons.error_outline : Icons.check_circle_outline, color: isError ? const Color(0xFFD32F2F) : const Color(0xFF2E7D32), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.inter(fontSize: 13, color: isError ? const Color(0xFFD32F2F) : const Color(0xFF2E7D32)),
            ),
          ),
        ],
      ),
    );
  }
}
