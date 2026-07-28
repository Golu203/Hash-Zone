import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/auth_service.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _authService = AuthService();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter both admin email and password.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _authService.signInWithEmailAndPassword(email, password);
      if (mounted) context.go('/admin/dashboard');
    } on FirebaseAuthException catch (e) {
      String msg;
      switch (e.code) {
        case 'user-not-found':
          msg = 'No admin user found with this email. Please add the user in Firebase Console.';
          break;
        case 'wrong-password':
        case 'invalid-credential':
          msg = 'Invalid email or password. Please verify your admin credentials.';
          break;
        case 'invalid-email':
          msg = 'Invalid email address format.';
          break;
        case 'user-disabled':
          msg = 'This admin account has been disabled.';
          break;
        default:
          msg = e.message ?? 'Authentication failed. Please check Firebase Auth settings.';
          break;
      }
      setState(() {
        _errorMessage = msg;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Authentication failed: ${e.toString()}';
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F8),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Container(
              padding: const EdgeInsets.all(36),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFE5E5E5)),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 20)],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Brand Logo
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF000000)),
                      image: const DecorationImage(
                        image: AssetImage('assets/images/logo.jpg'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'HASH ZONE',
                    style: GoogleFonts.cormorantGaramond(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 3.0,
                      color: const Color(0xFF000000),
                    ),
                  ),
                  Text(
                    'ADMIN PORTAL LOGIN',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 2.0,
                      color: const Color(0xFF666666),
                    ),
                  ),
                  const SizedBox(height: 32),

                  if (_errorMessage != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.red.withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: GoogleFonts.inter(fontSize: 12, color: Colors.redAccent),
                      ),
                    ),

                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: GoogleFonts.inter(color: Colors.black),
                    decoration: const InputDecoration(
                      labelText: 'Admin Email',
                      hintText: 'admin@hashzone.com',
                      prefixIcon: Icon(Icons.email_outlined, color: Color(0xFF555555)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    style: GoogleFonts.inter(color: Colors.black),
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      prefixIcon: Icon(Icons.lock_outline, color: Color(0xFF555555)),
                    ),
                    onFieldSubmitted: (_) => _handleLogin(),
                  ),
                  const SizedBox(height: 28),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleLogin,
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('SIGN IN TO ADMIN PANEL'),
                    ),
                  ),

                  const SizedBox(height: 20),

                  TextButton(
                    onPressed: () => context.go('/'),
                    child: Text(
                      '← Return to Public Website',
                      style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF666666)),
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
}
