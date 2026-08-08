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

  // Step 2 – Contact
  final _phoneCtrl = TextEditingController();
  final _waCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();

  // Step 3 – Address
  final _doorCtrl = TextEditingController();
  final _roadCtrl = TextEditingController();
  final _areaCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _landmarkCtrl = TextEditingController();

  // Form keys per step
  final _step1Key = GlobalKey<FormState>();
  final _step2Key = GlobalKey<FormState>();
  final _step3Key = GlobalKey<FormState>();

  late final AnimationController _progressCtrl;
  late Animation<double> _progressAnim;

  @override
  void initState() {
    super.initState();
    _progressCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 350));
    _progressAnim = Tween<double>(begin: 0.25, end: 0.25).animate(
      CurvedAnimation(parent: _progressCtrl, curve: Curves.easeInOut),
    );

    // Pre-fill email from Firebase user
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<CustomerAuthProvider>();
      final email = auth.firebaseUser?.email ?? '';
      _emailCtrl.text = email;
      // Pre-fill name from Google profile if available
      final name = auth.profile?.displayName ?? auth.firebaseUser?.displayName ?? '';
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
    _doorCtrl.dispose();
    _roadCtrl.dispose();
    _areaCtrl.dispose();
    _cityCtrl.dispose();
    _landmarkCtrl.dispose();
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
    // Validate current step
    bool valid = true;
    if (_currentStep == 0) valid = _step1Key.currentState?.validate() ?? false;
    if (_currentStep == 1) valid = _step2Key.currentState?.validate() ?? false;
    if (_currentStep == 2) valid = _step3Key.currentState?.validate() ?? false;

    if (!valid) return;

    if (_currentStep < 2) {
      setState(() => _currentStep++);
      _animateProgress((_currentStep + 1) / 4.0);
      _pageCtrl.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // Step 3 complete — save and go to completion screen
      await _saveAndFinish();
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

  Future<void> _saveAndFinish() async {
    final defaultAddr = CustomerAddress2(
      id: '',
      name: _nameCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      companyName: _companyCtrl.text.trim(),
      doorNumber: _doorCtrl.text.trim(),
      road: _roadCtrl.text.trim(),
      area: _areaCtrl.text.trim(),
      city: _cityCtrl.text.trim(),
      landmark: _landmarkCtrl.text.trim(),
    );
    await _saveAndFinishWithAddress(defaultAddr);
  }

  Future<void> _saveAndFinishWithAddress(CustomerAddress2 fullAddress) async {
    setState(() => _isSaving = true);
    try {
      final auth = context.read<CustomerAuthProvider>();
      final uid = auth.firebaseUser?.uid;

      await auth.completeOnboarding(
        displayName: _nameCtrl.text.trim().isNotEmpty ? _nameCtrl.text.trim() : fullAddress.name,
        companyName: _companyCtrl.text.trim().isNotEmpty ? _companyCtrl.text.trim() : fullAddress.companyName,
        phoneNumber: _phoneCtrl.text.trim().isNotEmpty ? _phoneCtrl.text.trim() : fullAddress.phone,
        whatsAppNumber: _waCtrl.text.trim(),
        address: CustomerAddress(
          doorNumber: fullAddress.doorNumber,
          road: fullAddress.road,
          area: fullAddress.area,
          city: fullAddress.city,
          landmark: fullAddress.landmark,
        ),
      );

      if (uid != null) {
        final addrSvc = AddressService();
        final defaultAddress = fullAddress.copyWith(isDefault: true);
        await addrSvc.addAddress(uid, defaultAddress);
      }

      if (!mounted) return;
      // Move to step 4 (completion)
      setState(() => _currentStep = 3);
      _animateProgress(1.0);
      _pageCtrl.animateToPage(3, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save profile. Please try again.', style: GoogleFonts.inter()),
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
            // ── Progress Header ──────────────────────────────────────────
            _buildProgressHeader(),

            // ── Page Content ─────────────────────────────────────────────
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
              return Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: _currentStep == 0
                          ? 0.25
                          : _currentStep == 1
                              ? 0.5
                              : _currentStep == 2
                                  ? 0.75
                                  : 1.0,
                      backgroundColor: const Color(0xFFEEEEEE),
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.black),
                      minHeight: 3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(4, (i) {
                      final active = i <= _currentStep;
                      return Text(
                        labels[i],
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: active ? FontWeight.w600 : FontWeight.normal,
                          color: active ? Colors.black : Colors.black26,
                        ),
                      );
                    }),
                  ),
                ],
              );
            },
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
            _field(_nameCtrl, 'Full Name *', Icons.person_outline, validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Name is required';
              if (v.trim().length < 2) return 'Enter your full name';
              return null;
            }),
            const SizedBox(height: 14),
            _field(_companyCtrl, 'Company / Business Name (Optional)', Icons.business_outlined),
          ],
        ),
      ),
      onNext: _nextStep,
      showBack: false,
      nextLabel: 'CONTINUE',
    );
  }

  // ── Step 2: Contact ──────────────────────────────────────────────────────────
  Widget _buildStep2(bool isMobile) {
    return _stepWrapper(
      isMobile: isMobile,
      title: 'Contact details',
      subtitle: 'We use these for order updates and WhatsApp inquiries.',
      form: Form(
        key: _step2Key,
        child: Column(
          children: [
            _field(
              _phoneCtrl,
              'Mobile Number *',
              Icons.phone_outlined,
              inputType: TextInputType.phone,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Mobile number is required';
                final digits = v.replaceAll(RegExp(r'[^0-9]'), '');
                if (digits.length < 10) return 'Enter a valid mobile number';
                return null;
              },
            ),
            const SizedBox(height: 14),
            _field(
              _waCtrl,
              'WhatsApp Number *',
              Icons.chat_outlined,
              inputType: TextInputType.phone,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'WhatsApp number is required';
                final digits = v.replaceAll(RegExp(r'[^0-9]'), '');
                if (digits.length < 10) return 'Enter a valid WhatsApp number';
                return null;
              },
            ),
            const SizedBox(height: 14),
            _field(
              _emailCtrl,
              'Email Address',
              Icons.email_outlined,
              inputType: TextInputType.emailAddress,
              readOnly: context.read<CustomerAuthProvider>().firebaseUser?.email?.isNotEmpty ?? false,
            ),
          ],
        ),
      ),
      onNext: _nextStep,
      onBack: _prevStep,
      nextLabel: 'CONTINUE',
    );
  }

  // ── Step 3: Address ──────────────────────────────────────────────────────────
  Widget _buildStep3(bool isMobile) {
    return _stepWrapper(
      isMobile: isMobile,
      title: 'Primary Delivery Address',
      subtitle: 'Where should your wholesale orders be shipped?',
      form: UnifiedAddressForm(
        defaultFullName: _nameCtrl.text.trim(),
        defaultPhone: _phoneCtrl.text.trim(),
        defaultCompany: _companyCtrl.text.trim(),
        submitButtonText: 'COMPLETE SETUP',
        isSaving: _isSaving,
        onSave: (address) async {
          _doorCtrl.text = address.doorNumber;
          _roadCtrl.text = address.road;
          _areaCtrl.text = address.area;
          _cityCtrl.text = address.city;
          _landmarkCtrl.text = address.landmark;
          await _saveAndFinishWithAddress(address);
        },
      ),
      onNext: () {},
      onBack: _prevStep,
      nextLabel: null,
      isLoading: _isSaving,
    );
  }

  // ── Step 4: Completion ───────────────────────────────────────────────────────
  Widget _buildStep4(bool isMobile) {
    final name = _nameCtrl.text.trim().isNotEmpty
        ? _nameCtrl.text.trim().split(' ').first
        : 'there';

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: isMobile ? 24 : 48, vertical: 32),
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
              style: GoogleFonts.inter(fontSize: 14, color: Colors.black54, height: 1.7),
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
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: Text(
                  'START SHOPPING',
                  style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 1.4),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Step Wrapper ─────────────────────────────────────────────────────────────
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
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 24 : 48, vertical: 28),
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
                style: GoogleFonts.inter(fontSize: 13, color: Colors.black45, height: 1.5),
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
                          side: const BorderSide(color: Color(0xFFDDDDDD), width: 1.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                        ),
                        child: Text('BACK', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.8)),
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
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: isLoading
                            ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)))
                            : Text(
                                nextLabel ?? 'CONTINUE',
                                style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 1.2),
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
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: inputType,
      readOnly: readOnly,
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.inter(fontSize: 13, color: Colors.black54),
        prefixIcon: Icon(icon, size: 18, color: Colors.black54),
        filled: true,
        fillColor: readOnly ? const Color(0xFFF5F5F5) : const Color(0xFFFAFAFA),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFDDDDDD))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFDDDDDD))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.black, width: 1.5)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFD32F2F))),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFD32F2F), width: 1.5)),
        disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFEEEEEE))),
      ),
      validator: validator,
      style: GoogleFonts.inter(fontSize: 14, color: readOnly ? Colors.black45 : Colors.black87),
    );
  }
}
