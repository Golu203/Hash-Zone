import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/customer_profile.dart';
import '../../providers/customer_auth_provider.dart';
import '../../services/address_service.dart';
import '../../widgets/unified_address_form.dart';

class CustomerOnboardingScreen extends StatefulWidget {
  final String? redirectTo;
  const CustomerOnboardingScreen({super.key, this.redirectTo});

  @override
  State<CustomerOnboardingScreen> createState() => _CustomerOnboardingScreenState();
}

class _CustomerOnboardingScreenState extends State<CustomerOnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageCtrl = PageController();
  int _currentStep = 0;
  bool _isSaving = false;

  // Step 1 – Identity
  final _nameCtrl = TextEditingController();
  final _companyCtrl = TextEditingController();

  // Step 2 – Contact & Business Details
  final _phoneCtrl = TextEditingController();
  final _waCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  String _businessIdType = 'GST'; // 'GST' | 'PAN'
  final _businessIdValueCtrl = TextEditingController();
  bool _sameAsPhone = false; // "Same as mobile number" checkbox

  // Step 3 – Address (managed by UnifiedAddressForm)
  bool _termsAccepted = false;
  bool _privacyAccepted = false;
  String? _consentError;

  // Form keys per step
  final _step1Key = GlobalKey<FormState>();
  final _step2Key = GlobalKey<FormState>();

  late final AnimationController _progressCtrl;
  late Animation<double> _progressAnim;

  @override
  void initState() {
    super.initState();
    _progressCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 350));
    _progressAnim = Tween<double>(begin: 0.25, end: 0.25).animate(
      CurvedAnimation(parent: _progressCtrl, curve: Curves.easeInOut),
    );

    // Sync WhatsApp field whenever mobile changes and checkbox is ticked
    _phoneCtrl.addListener(() {
      if (_sameAsPhone) {
        _waCtrl.text = _phoneCtrl.text;
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<CustomerAuthProvider>();
      final email = auth.firebaseUser?.email ?? '';
      _emailCtrl.text = email;
      final name =
          auth.profile?.displayName ?? auth.firebaseUser?.displayName ?? '';
      if (name.isNotEmpty) _nameCtrl.text = name;
    });
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    _progressCtrl.dispose();
    _nameCtrl.dispose();
    _companyCtrl.dispose();
    _phoneCtrl.dispose();
    _waCtrl.dispose();
    _emailCtrl.dispose();
    _businessIdValueCtrl.dispose();
    super.dispose();
  }

  void _animateProgress(double target) {
    _progressAnim = Tween<double>(
      begin: _progressAnim.value,
      end: target,
    ).animate(CurvedAnimation(parent: _progressCtrl, curve: Curves.easeInOut));
    _progressCtrl.forward(from: 0);
  }

  Future<void> _nextStep() async {
    bool valid = true;
    if (_currentStep == 0) valid = _step1Key.currentState?.validate() ?? false;
    if (_currentStep == 1) valid = _step2Key.currentState?.validate() ?? false;
    if (!valid) return;

    if (_currentStep < 2) {
      setState(() => _currentStep++);
      _animateProgress((_currentStep + 1) / 4.0);
      _pageCtrl.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _animateProgress((_currentStep + 1) / 4.0);
      _pageCtrl.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _saveAndFinishWithAddress(CustomerAddress2 fullAddress) async {
    // Enforce Legal Consent
    if (!_termsAccepted || !_privacyAccepted) {
      setState(() {
        _consentError =
            'Please accept the Terms & Conditions and Privacy Policy to continue.';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please accept the Terms & Conditions and Privacy Policy to continue.',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600),
          ),
          backgroundColor: const Color(0xFFD32F2F),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final auth = context.read<CustomerAuthProvider>();
      final uid = auth.firebaseUser?.uid;

      await auth.completeOnboarding(
        displayName: _nameCtrl.text.trim().isNotEmpty
            ? _nameCtrl.text.trim()
            : fullAddress.name,
        companyName: _companyCtrl.text.trim().isNotEmpty
            ? _companyCtrl.text.trim()
            : fullAddress.companyName,
        phoneNumber: _phoneCtrl.text.trim().isNotEmpty
            ? _phoneCtrl.text.trim()
            : fullAddress.phone,
        whatsAppNumber: _waCtrl.text.trim(),
        businessIdType: _businessIdType,
        businessIdValue: _businessIdValueCtrl.text.trim().toUpperCase(),
        address: CustomerAddress(
          doorNumber: fullAddress.doorNumber,
          road: fullAddress.road,
          area: fullAddress.area,
          city: fullAddress.city,
          state: fullAddress.state,
          pincode: fullAddress.pincode,
          landmark: fullAddress.landmark,
        ),
        termsAccepted: _termsAccepted,
        privacyAccepted: _privacyAccepted,
      );

      if (uid != null) {
        final addrSvc = AddressService();
        final defaultAddress = fullAddress.copyWith(isDefault: true);
        await addrSvc.addAddress(uid, defaultAddress);
      }

      if (!mounted) return;
      setState(() => _currentStep = 3);
      _animateProgress(1.0);
      _pageCtrl.animateToPage(3,
          duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save profile. Please try again.',
                style: GoogleFonts.inter()),
            backgroundColor: const Color(0xFFD32F2F),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final isMobile = w < 600;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildProgressHeader(),
            Expanded(
              child: PageView(
                controller: _pageCtrl,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildStep1(isMobile),
                  _buildStep2(isMobile),
                  _buildStep3(isMobile),
                  _buildStep4(isMobile),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Progress Header ──────────────────────────────────────────────────────────
  Widget _buildProgressHeader() {
    final labels = ['Identity', 'Contact', 'Address', 'Done'];
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                'HASH ZONE',
                style: GoogleFonts.cormorantGaramond(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 3,
                  color: Colors.black,
                ),
              ),
              const Spacer(),
              Text(
                'Step ${_currentStep + 1} of 4',
                style: GoogleFonts.inter(fontSize: 12, color: Colors.black45),
              ),
            ],
          ),
          const SizedBox(height: 16),
          AnimatedBuilder(
            animation: _progressAnim,
            builder: (context, _) {
              return LinearProgressIndicator(
                value: _progressAnim.value,
                backgroundColor: const Color(0xFFEEEEEE),
                valueColor: const AlwaysStoppedAnimation(Colors.black),
                minHeight: 3,
              );
            },
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(labels.length, (i) {
              final active = i <= _currentStep;
              return Text(
                labels[i],
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: active ? FontWeight.bold : FontWeight.normal,
                  color: active ? Colors.black : Colors.black26,
                ),
              );
            }),
          ),
          const SizedBox(height: 4),
          const Divider(height: 1, color: Color(0xFFEEEEEE)),
        ],
      ),
    );
  }

  // ── Step 1: Identity ─────────────────────────────────────────────────────────
  Widget _buildStep1(bool isMobile) {
    return _stepWrapper(
      isMobile: isMobile,
      title: 'Tell us about yourself',
      subtitle: 'Your name helps us personalise your experience.',
      form: Form(
        key: _step1Key,
        child: Column(
          children: [
            _field(_nameCtrl, 'Full Name *', Icons.person_outline,
                validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Name is required';
              if (v.trim().length < 2) return 'Enter your full name';
              return null;
            }),
            const SizedBox(height: 14),
            _field(_companyCtrl,
                'Company / Business Name (Optional)', Icons.business_outlined),
          ],
        ),
      ),
      onNext: _nextStep,
      showBack: false,
      nextLabel: 'CONTINUE',
    );
  }

  // ── Step 2: Contact & Business Details ───────────────────────────────────────
  Widget _buildStep2(bool isMobile) {
    return _stepWrapper(
      isMobile: isMobile,
      title: 'Contact & Business Details',
      subtitle: 'Required for order updates, invoicing and GST/PAN compliance.',
      form: Form(
        key: _step2Key,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Contact Mobile ────────────────────────────────────────────
            _field(
              _phoneCtrl,
              'Contact Mobile Number *',
              Icons.phone_outlined,
              inputType: TextInputType.phone,
              validator: (v) {
                if (v == null || v.trim().isEmpty)
                  return 'Mobile number is required';
                final digits = v.replaceAll(RegExp(r'[^0-9]'), '');
                if (digits.length != 10)
                  return 'Enter a valid 10-digit mobile number';
                return null;
              },
            ),
            const SizedBox(height: 14),

            // ── WhatsApp Number ───────────────────────────────────────────
            _field(
              _waCtrl,
              'WhatsApp Number *',
              Icons.chat_outlined,
              inputType: TextInputType.phone,
              readOnly: _sameAsPhone,
              validator: (v) {
                if (v == null || v.trim().isEmpty)
                  return 'WhatsApp number is required';
                final digits = v.replaceAll(RegExp(r'[^0-9]'), '');
                if (digits.length < 10)
                  return 'Enter a valid WhatsApp number';
                return null;
              },
            ),
            // ── Same as mobile checkbox ───────────────────────────────────
            InkWell(
              onTap: () => setState(() {
                _sameAsPhone = !_sameAsPhone;
                if (_sameAsPhone) _waCtrl.text = _phoneCtrl.text;
              }),
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
                child: Row(
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: Checkbox(
                        value: _sameAsPhone,
                        activeColor: Colors.black,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4)),
                        onChanged: (v) => setState(() {
                          _sameAsPhone = v ?? false;
                          if (_sameAsPhone) _waCtrl.text = _phoneCtrl.text;
                        }),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Same as mobile number',
                      style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.black54,
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),

            // ── Email (read-only if from Google) ─────────────────────────
            _field(
              _emailCtrl,
              'Email Address',
              Icons.email_outlined,
              inputType: TextInputType.emailAddress,
              readOnly: context
                      .read<CustomerAuthProvider>()
                      .firebaseUser
                      ?.email
                      ?.isNotEmpty ??
                  false,
            ),
            const SizedBox(height: 22),

            // ── Business Identification ───────────────────────────────────
            Text(
              'BUSINESS IDENTIFICATION *',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
                color: const Color(0xFF666666),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Select one identifier for your business (mandatory for invoicing).',
              style: GoogleFonts.inter(fontSize: 12, color: Colors.black45),
            ),
            const SizedBox(height: 10),

            // Toggle selector: GST | PAN
            StatefulBuilder(
              builder: (ctx, setInner) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Selector tabs
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFDDDDDD)),
                    ),
                    child: Row(
                      children: [
                        _idTypeTab('GST Number', 'GST', setInner),
                        _idTypeTab('PAN Number', 'PAN', setInner),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Dynamic input field
                  TextFormField(
                    controller: _businessIdValueCtrl,
                    keyboardType: TextInputType.text,
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      labelText: _businessIdType == 'GST'
                          ? 'GST Number *'
                          : 'PAN Number *',
                      hintText: _businessIdType == 'GST'
                          ? 'e.g. 33AAAAA0000A1Z5'
                          : 'e.g. ABCDE1234F',
                      hintStyle:
                          GoogleFonts.inter(fontSize: 12, color: Colors.black26),
                      labelStyle:
                          GoogleFonts.inter(fontSize: 13, color: Colors.black54),
                      prefixIcon: Icon(
                        _businessIdType == 'GST'
                            ? Icons.receipt_long_outlined
                            : Icons.credit_card_outlined,
                        size: 18,
                        color: Colors.black54,
                      ),
                      filled: true,
                      fillColor: const Color(0xFFFAFAFA),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 16),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: Color(0xFFDDDDDD))),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: Color(0xFFDDDDDD))),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                              color: Colors.black, width: 1.5)),
                      errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: Color(0xFFD32F2F))),
                      focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                              color: Color(0xFFD32F2F), width: 1.5)),
                    ),
                    style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.black87,
                        letterSpacing: 1.0),
                    validator: (v) {
                      final val = v?.trim().toUpperCase() ?? '';
                      if (val.isEmpty) {
                        return _businessIdType == 'GST'
                            ? 'GST Number is required'
                            : 'PAN Number is required';
                      }
                      if (_businessIdType == 'GST') {
                        final gstRegex = RegExp(
                            r'^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[1-9A-Z]{1}Z[0-9A-Z]{1}$');
                        if (!gstRegex.hasMatch(val)) {
                          return 'Invalid GST format (e.g. 33AAAAA0000A1Z5)';
                        }
                      } else {
                        final panRegex =
                            RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]{1}$');
                        if (!panRegex.hasMatch(val)) {
                          return 'Invalid PAN format (e.g. ABCDE1234F)';
                        }
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      onNext: _nextStep,
      onBack: _prevStep,
      nextLabel: 'CONTINUE',
    );
  }

  // Tab button for GST / PAN selector
  Widget _idTypeTab(String label, String value, StateSetter setInner) {
    final selected = _businessIdType == value;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setInner(() {});
          setState(() {
            _businessIdType = value;
            _businessIdValueCtrl.clear();
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(3),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? Colors.black : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: selected ? Colors.white : Colors.black54,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Step 3: Address ──────────────────────────────────────────────────────────
  // NOTE: Uses a dedicated scroll wrapper WITHOUT the _stepWrapper button row
  // to avoid the duplicate button issue (UnifiedAddressForm has its own submit button).
  Widget _buildStep3(bool isMobile) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 24 : 48, vertical: 28),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Text(
                'Primary Delivery Address',
                style: GoogleFonts.cormorantGaramond(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Where should your wholesale orders be shipped?',
                style:
                    GoogleFonts.inter(fontSize: 13, color: Colors.black45, height: 1.5),
              ),
              const SizedBox(height: 28),

              // Back button row
              Row(
                children: [
                  OutlinedButton(
                    onPressed: _isSaving ? null : _prevStep,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.black,
                      side: const BorderSide(color: Color(0xFFDDDDDD), width: 1.5),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 14),
                    ),
                    child: Text('BACK',
                        style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            letterSpacing: 0.8)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Fill in your delivery address below',
                      style: GoogleFonts.inter(
                          fontSize: 12, color: Colors.black45),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Address form with its own COMPLETE SETUP button
              UnifiedAddressForm(
                defaultFullName: _nameCtrl.text.trim(),
                defaultPhone: _phoneCtrl.text.trim(),
                defaultCompany: _companyCtrl.text.trim(),
                submitButtonText: 'COMPLETE SETUP',
                isSaving: _isSaving,
                beforeSubmitWidget: _buildLegalConsentSection(isMobile),
                onSave: (address) async {
                  await _saveAndFinishWithAddress(address);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLegalConsentSection(bool isMobile) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F9FA),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E5E5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'LEGAL & POLICY CONSENT',
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              color: const Color(0xFF666666),
            ),
          ),
          const SizedBox(height: 10),

          // 1. Terms & Conditions
          InkWell(
            onTap: () => setState(() {
              _termsAccepted = !_termsAccepted;
              if (_termsAccepted && _privacyAccepted) _consentError = null;
            }),
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 22,
                    height: 22,
                    child: Checkbox(
                      value: _termsAccepted,
                      activeColor: Colors.black,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4)),
                      onChanged: (v) => setState(() {
                        _termsAccepted = v ?? false;
                        if (_termsAccepted && _privacyAccepted)
                          _consentError = null;
                      }),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          'I agree to the ',
                          style: GoogleFonts.inter(
                              fontSize: isMobile ? 12 : 13,
                              color: const Color(0xFF222222)),
                        ),
                        InkWell(
                          onTap: () => context.push('/terms'),
                          child: Text(
                            'Terms & Conditions',
                            style: GoogleFonts.inter(
                              fontSize: isMobile ? 12 : 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                        Text(
                          ' *',
                          style: GoogleFonts.inter(
                            fontSize: isMobile ? 12 : 13,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFD32F2F),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),

          // 2. Privacy Policy
          InkWell(
            onTap: () => setState(() {
              _privacyAccepted = !_privacyAccepted;
              if (_termsAccepted && _privacyAccepted) _consentError = null;
            }),
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 22,
                    height: 22,
                    child: Checkbox(
                      value: _privacyAccepted,
                      activeColor: Colors.black,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4)),
                      onChanged: (v) => setState(() {
                        _privacyAccepted = v ?? false;
                        if (_termsAccepted && _privacyAccepted)
                          _consentError = null;
                      }),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          'I acknowledge that I have read the ',
                          style: GoogleFonts.inter(
                              fontSize: isMobile ? 12 : 13,
                              color: const Color(0xFF222222)),
                        ),
                        InkWell(
                          onTap: () => context.push('/privacy'),
                          child: Text(
                            'Privacy Policy',
                            style: GoogleFonts.inter(
                              fontSize: isMobile ? 12 : 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                        Text(
                          ' *',
                          style: GoogleFonts.inter(
                            fontSize: isMobile ? 12 : 13,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFD32F2F),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Validation Error
          if (_consentError != null) ...[
            const SizedBox(height: 10),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFEBEE),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFFFCDD2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline,
                      size: 16, color: Color(0xFFD32F2F)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _consentError!,
                      style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFD32F2F)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Step 4: Completion ───────────────────────────────────────────────────────
  Widget _buildStep4(bool isMobile) {
    final name = _nameCtrl.text.trim().isNotEmpty
        ? _nameCtrl.text.trim().split(' ').first
        : 'there';

    return Center(
      child: Padding(
        padding:
            EdgeInsets.symmetric(horizontal: isMobile ? 24 : 48, vertical: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(44),
              ),
              child: const Icon(Icons.check, color: Colors.white, size: 44),
            ),
            const SizedBox(height: 28),
            Text(
              'Welcome, $name! 🎉',
              style: GoogleFonts.cormorantGaramond(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Your HashZone account is ready.\nYou can now browse, inquire and place wholesale orders.',
              style:
                  GoogleFonts.inter(fontSize: 14, color: Colors.black54, height: 1.7),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: isMobile ? double.infinity : 320,
              height: 54,
              child: ElevatedButton(
                onPressed: () => context.go(widget.redirectTo ?? '/'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: Text(
                  'START SHOPPING',
                  style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      letterSpacing: 1.4),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Step Wrapper (Steps 1 & 2 only) ─────────────────────────────────────────
  Widget _stepWrapper({
    required bool isMobile,
    required String title,
    required String subtitle,
    required Widget form,
    required VoidCallback onNext,
    VoidCallback? onBack,
    bool showBack = true,
    String? nextLabel,
    bool isLoading = false,
  }) {
    return SingleChildScrollView(
      padding:
          EdgeInsets.symmetric(horizontal: isMobile ? 24 : 48, vertical: 28),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                title,
                style: GoogleFonts.cormorantGaramond(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style:
                    GoogleFonts.inter(fontSize: 13, color: Colors.black45, height: 1.5),
              ),
              const SizedBox(height: 28),
              form,
              const SizedBox(height: 32),
              Row(
                children: [
                  if (showBack && onBack != null) ...[
                    SizedBox(
                      height: 52,
                      child: OutlinedButton(
                        onPressed: onBack,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.black,
                          side: const BorderSide(
                              color: Color(0xFFDDDDDD), width: 1.5),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          padding:
                              const EdgeInsets.symmetric(horizontal: 24),
                        ),
                        child: Text('BACK',
                            style: GoogleFonts.inter(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                letterSpacing: 0.8)),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : onNext,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.black38,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation(
                                        Colors.white)))
                            : Text(
                                nextLabel ?? 'CONTINUE',
                                style: GoogleFonts.inter(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    letterSpacing: 1.2),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Input Field Helper ───────────────────────────────────────────────────────
  Widget _field(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    String? Function(String?)? validator,
    TextInputType inputType = TextInputType.text,
    bool readOnly = false,
    String? hintText,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: inputType,
      readOnly: readOnly,
      textCapitalization: textCapitalization,
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        hintStyle: GoogleFonts.inter(fontSize: 12, color: Colors.black26),
        labelStyle: GoogleFonts.inter(fontSize: 13, color: Colors.black54),
        prefixIcon: Icon(icon, size: 18, color: Colors.black54),
        filled: true,
        fillColor:
            readOnly ? const Color(0xFFF5F5F5) : const Color(0xFFFAFAFA),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFDDDDDD))),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFDDDDDD))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.black, width: 1.5)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFD32F2F))),
        focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                const BorderSide(color: Color(0xFFD32F2F), width: 1.5)),
        disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFEEEEEE))),
      ),
      validator: validator,
      style: GoogleFonts.inter(
          fontSize: 14,
          color: readOnly ? Colors.black45 : Colors.black87),
    );
  }
}
