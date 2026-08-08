import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/customer_auth_service.dart';
import '../../widgets/smart_back_button.dart';

class ForgotPasswordScreen extends StatefulWidget {
  final String? redirectTo;
  const ForgotPasswordScreen({super.key, this.redirectTo});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _service = CustomerAuthService();

  bool _isLoading = false;
  bool _emailSent = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleReset() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; _error = null; });

    try {
      await _service.sendPasswordResetEmail(_emailCtrl.text);
      if (mounted) setState(() => _emailSent = true);
    } on FirebaseAuthException catch (e) {
      String msg;
      switch (e.code) {
        case 'user-not-found':
        case 'invalid-email':
          msg = 'No account found with this email address.';
          break;
        case 'too-many-requests':
          msg = 'Too many attempts. Please wait a moment.';
          break;
        default:
          msg = 'Failed to send reset email. Please try again.';
      }
      setState(() => _error = msg);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: isMobile ? 24 : 0, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: _emailSent ? _buildSuccessView() : _buildFormView(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormView() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Align(
            alignment: Alignment.centerLeft,
            child: HZSmartBackButton(fallbackRoute: '/login'),
          ),
          const SizedBox(height: 12),
          Text(
            'HASH ZONE',
            style: GoogleFonts.cormorantGaramond(fontSize: 30, fontWeight: FontWeight.bold, letterSpacing: 4, color: Colors.black),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Reset your password',
            style: GoogleFonts.inter(fontSize: 14, color: Colors.black54),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            "Enter your email address and we'll send you a link to reset your password.",
            style: GoogleFonts.inter(fontSize: 13, color: Colors.black45),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 36),

          if (_error != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3F3),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFFCDD2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Color(0xFFD32F2F), size: 18),
                  const SizedBox(width: 10),
                  Expanded(child: Text(_error!, style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFFD32F2F)))),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          TextFormField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _handleReset(),
            decoration: InputDecoration(
              labelText: 'Email address',
              labelStyle: GoogleFonts.inter(fontSize: 13, color: Colors.black54),
              prefixIcon: const Icon(Icons.email_outlined, size: 18, color: Colors.black54),
              filled: true,
              fillColor: const Color(0xFFFAFAFA),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFDDDDDD))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFDDDDDD))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.black, width: 1.5)),
              errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFD32F2F))),
              focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFD32F2F), width: 1.5)),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Email is required';
              if (!v.contains('@')) return 'Enter a valid email';
              return null;
            },
          ),
          const SizedBox(height: 24),

          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleReset,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.black38,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: _isLoading
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)))
                  : Text('SEND RESET LINK', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 1.2)),
            ),
          ),
          const SizedBox(height: 24),

          Center(
            child: TextButton(
              onPressed: () => context.go(
                '/login${widget.redirectTo != null ? "?redirect=${Uri.encodeComponent(widget.redirectTo!)}" : ""}',
              ),
              child: Text('← Back to Sign In', style: GoogleFonts.inter(fontSize: 13, color: Colors.black54)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 40),
        const Icon(Icons.mark_email_read_outlined, size: 72, color: Colors.black),
        const SizedBox(height: 24),
        Text(
          'Check your email',
          style: GoogleFonts.cormorantGaramond(fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: 1),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          'We\'ve sent a password reset link to:\n${_emailCtrl.text.trim()}',
          style: GoogleFonts.inter(fontSize: 14, color: Colors.black54, height: 1.6),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Please check your inbox and follow the instructions.',
          style: GoogleFonts.inter(fontSize: 13, color: Colors.black38),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 36),
        SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: () => context.go(
              '/login${widget.redirectTo != null ? "?redirect=${Uri.encodeComponent(widget.redirectTo!)}" : ""}',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: Text('BACK TO SIGN IN', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 1.2)),
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: TextButton(
            onPressed: () => setState(() { _emailSent = false; _emailCtrl.clear(); }),
            child: Text('Resend email', style: GoogleFonts.inter(fontSize: 13, color: Colors.black45, decoration: TextDecoration.underline)),
          ),
        ),
      ],
    );
  }
}
