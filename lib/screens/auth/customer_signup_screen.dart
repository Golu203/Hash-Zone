import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/customer_auth_provider.dart';
import '../../widgets/smart_back_button.dart';

class CustomerSignupScreen extends StatefulWidget {
  final String? redirectTo;
  const CustomerSignupScreen({super.key, this.redirectTo});

  @override
  State<CustomerSignupScreen> createState() => _CustomerSignupScreenState();
}

class _CustomerSignupScreenState extends State<CustomerSignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();

  bool _isLoading = false;
  bool _googleLoading = false;
  bool _obscurePass = true;
  bool _obscureConfirm = true;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  String get _redirectTarget => widget.redirectTo ?? '/';

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; _error = null; });

    try {
      final auth = context.read<CustomerAuthProvider>();
      await auth.signUpWithEmail(_emailCtrl.text, _passCtrl.text);
      if (!mounted) return;
      // New signup always needs onboarding
      context.go('/onboarding?redirect=${Uri.encodeComponent(_redirectTarget)}');
    } on FirebaseAuthException catch (e) {
      setState(() => _error = _friendlyError(e.code));
    } catch (_) {
      setState(() => _error = 'Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleGoogle() async {
    setState(() { _googleLoading = true; _error = null; });
    try {
      final auth = context.read<CustomerAuthProvider>();
      final isNew = await auth.signInWithGoogle();
      if (!mounted) return;
      if (isNew) {
        context.go('/onboarding?redirect=${Uri.encodeComponent(_redirectTarget)}');
      } else {
        context.go(_redirectTarget);
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _error = _friendlyError(e.code));
    } catch (_) {
      setState(() => _error = 'Google Sign-In failed. Please try again.');
    } finally {
      if (mounted) setState(() => _googleLoading = false);
    }
  }

  String _friendlyError(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'An account with this email already exists. Try signing in instead.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      case 'operation-not-allowed':
        return 'Email/password accounts are not enabled. Please contact support.';
      case 'popup-closed-by-user':
        return 'Google Sign-In was cancelled.';
      default:
        return 'Registration failed. Please try again.';
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
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 24 : 0,
              vertical: 32,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: HZSmartBackButton(fallbackRoute: '/login'),
                    ),
                    const SizedBox(height: 12),
                    // Header
                    Column(
                      children: [
                        Text(
                          'HASH ZONE',
                          style: GoogleFonts.cormorantGaramond(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 4,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Create your account',
                          style: GoogleFonts.inter(fontSize: 14, color: Colors.black54),
                        ),
                      ],
                    ),
                    const SizedBox(height: 36),

                    if (_error != null) ...[
                      _buildErrorBanner(_error!),
                      const SizedBox(height: 16),
                    ],

                    // Google Button
                    _buildGoogleButton(),
                    const SizedBox(height: 20),

                    // Divider
                    Row(
                      children: [
                        const Expanded(child: Divider(color: Color(0xFFEEEEEE))),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text('or', style: GoogleFonts.inter(fontSize: 12, color: Colors.black38)),
                        ),
                        const Expanded(child: Divider(color: Color(0xFFEEEEEE))),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Email
                    TextFormField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: _inputDec('Email address', Icons.email_outlined),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Email is required';
                        if (!v.contains('@')) return 'Enter a valid email';
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    // Password
                    TextFormField(
                      controller: _passCtrl,
                      obscureText: _obscurePass,
                      textInputAction: TextInputAction.next,
                      decoration: _inputDec('Password', Icons.lock_outline).copyWith(
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePass ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                            color: Colors.black54, size: 20,
                          ),
                          onPressed: () => setState(() => _obscurePass = !_obscurePass),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Password is required';
                        if (v.length < 6) return 'Minimum 6 characters';
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    // Confirm Password
                    TextFormField(
                      controller: _confirmPassCtrl,
                      obscureText: _obscureConfirm,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _handleSignup(),
                      decoration: _inputDec('Confirm password', Icons.lock_outline).copyWith(
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirm ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                            color: Colors.black54, size: 20,
                          ),
                          onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Please confirm your password';
                        if (v != _passCtrl.text) return 'Passwords do not match';
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Create Account Button
                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleSignup,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.black38,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 22, height: 22,
                                child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)),
                              )
                            : Text('CREATE ACCOUNT', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 1.2)),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Sign In Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Already have an account? ', style: GoogleFonts.inter(fontSize: 13, color: Colors.black54)),
                        GestureDetector(
                          onTap: () => context.go('/login?redirect=${Uri.encodeComponent(_redirectTarget)}'),
                          child: Text(
                            'Sign in',
                            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black, decoration: TextDecoration.underline),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: TextButton(
                        onPressed: () => context.go('/'),
                        child: Text('← Continue browsing', style: GoogleFonts.inter(fontSize: 12, color: Colors.black54)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorBanner(String msg) {
    return Container(
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
          Expanded(child: Text(msg, style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFFD32F2F)))),
        ],
      ),
    );
  }

  Widget _buildGoogleButton() {
    return SizedBox(
      height: 52,
      child: OutlinedButton(
        onPressed: _googleLoading ? null : _handleGoogle,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          side: const BorderSide(color: Color(0xFFDDDDDD), width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: _googleLoading
            ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.black)))
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(width: 22, height: 22, child: _GoogleIcon()),
                  const SizedBox(width: 12),
                  Text('Continue with Google', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black87)),
                ],
              ),
      ),
    );
  }

  InputDecoration _inputDec(String label, IconData icon) {
    return InputDecoration(
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
}

class _GoogleIcon extends StatelessWidget {
  const _GoogleIcon();
  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _GoogleIconPainter());
  }
}

class _GoogleIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double scale = size.width / 24.0;
    canvas.scale(scale);

    final Paint paint = Paint()..style = PaintingStyle.fill;

    // 1. Blue path
    paint.color = const Color(0xFF4285F4);
    final Path bluePath = Path()
      ..moveTo(22.56, 12.25)
      ..cubicTo(22.56, 11.47, 22.49, 10.72, 22.36, 10.0)
      ..lineTo(12.0, 10.0)
      ..lineTo(12.0, 14.26)
      ..lineTo(17.92, 14.26)
      ..cubicTo(17.66, 15.63, 16.88, 16.79, 15.71, 17.57)
      ..lineTo(15.71, 20.34)
      ..lineTo(19.28, 20.34)
      ..cubicTo(21.36, 18.42, 22.56, 15.6, 22.56, 12.25)
      ..close();
    canvas.drawPath(bluePath, paint);

    // 2. Green path
    paint.color = const Color(0xFF34A853);
    final Path greenPath = Path()
      ..moveTo(12.0, 23.0)
      ..cubicTo(14.97, 23.0, 17.46, 22.02, 19.28, 20.34)
      ..lineTo(15.71, 17.57)
      ..cubicTo(14.73, 18.23, 13.48, 18.63, 12.0, 18.63)
      ..cubicTo(9.14, 18.63, 6.71, 16.7, 5.84, 14.1)
      ..lineTo(2.18, 14.1)
      ..lineTo(2.18, 16.94)
      ..cubicTo(3.99, 20.53, 7.7, 23.0, 12.0, 23.0)
      ..close();
    canvas.drawPath(greenPath, paint);

    // 3. Yellow path
    paint.color = const Color(0xFFFBBC05);
    final Path yellowPath = Path()
      ..moveTo(5.84, 14.1)
      ..cubicTo(5.62, 13.44, 5.49, 12.74, 5.49, 12.0)
      ..cubicTo(5.49, 11.26, 5.62, 10.56, 5.84, 9.9)
      ..lineTo(2.18, 9.9)
      ..lineTo(2.18, 7.06)
      ..cubicTo(1.43, 8.55, 1.0, 10.22, 1.0, 12.0)
      ..cubicTo(1.0, 13.78, 1.43, 15.45, 2.18, 16.94)
      ..lineTo(5.84, 14.1)
      ..close();
    canvas.drawPath(yellowPath, paint);

    // 4. Red path
    paint.color = const Color(0xFFEA4335);
    final Path redPath = Path()
      ..moveTo(12.0, 5.38)
      ..cubicTo(13.82, 5.38, 15.48, 6.01, 16.76, 7.02)
      ..lineTo(19.91, 3.87)
      ..cubicTo(17.9, 2.01, 15.15, 1.0, 12.0, 1.0)
      ..cubicTo(7.7, 1.0, 3.99, 3.47, 2.18, 7.06)
      ..lineTo(5.84, 9.9)
      ..cubicTo(6.71, 7.3, 9.14, 5.38, 12.0, 5.38)
      ..close();
    canvas.drawPath(redPath, paint);
  }

  @override
  bool shouldRepaint(_) => false;
}
