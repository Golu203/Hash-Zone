import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/admin_session_service.dart';
import '../../services/auth_service.dart';
import '../../services/minimoth_service.dart';

class AdminLoginScreen extends StatefulWidget {
  final String? reason;
  const AdminLoginScreen({super.key, this.reason});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _authService = AuthService();
  final _sessionService = AdminSessionService();
  final _minMothService = MinMothService();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _otpController = TextEditingController();

  // Step 1 = Email & Password, Step 2 = MinMoth 2FA OTP
  int _step = 1;

  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  // Brute-force lockout state
  int _lockoutSecondsRemaining = 0;
  Timer? _lockoutTimer;

  // 2FA state
  List<String> _authorizedPhones = [];
  String? _selectedPhone;
  bool _otpSent = false;
  int _resendCooldownSeconds = 0;
  Timer? _resendTimer;
  String? _authenticatedEmail;

  @override
  void initState() {
    super.initState();
    _checkLockoutStatus();
    if (widget.reason == 'idle_timeout') {
      _errorMessage = 'Session expired due to 30 minutes of inactivity. Please sign in again.';
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _otpController.dispose();
    _lockoutTimer?.cancel();
    _resendTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkLockoutStatus() async {
    final remaining = await _sessionService.getRemainingLockoutSeconds();
    if (remaining > 0) {
      _startLockoutCountdown(remaining);
    }
  }

  void _startLockoutCountdown(int seconds) {
    _lockoutTimer?.cancel();
    setState(() {
      _lockoutSecondsRemaining = seconds;
    });

    _lockoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_lockoutSecondsRemaining <= 1) {
        timer.cancel();
        setState(() {
          _lockoutSecondsRemaining = 0;
          _errorMessage = null;
        });
      } else {
        setState(() {
          _lockoutSecondsRemaining--;
        });
      }
    });
  }

  void _startResendCooldown() {
    _resendTimer?.cancel();
    setState(() {
      _resendCooldownSeconds = 30;
    });

    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCooldownSeconds <= 1) {
        timer.cancel();
        setState(() {
          _resendCooldownSeconds = 0;
        });
      } else {
        setState(() {
          _resendCooldownSeconds--;
        });
      }
    });
  }

  String _formatLockoutTime(int seconds) {
    final m = (seconds / 60).floor().toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  // ── STEP 1: VERIFY EMAIL & PASSWORD ─────────────────────────────────────────
  Future<void> _handlePasswordStep() async {
    if (_lockoutSecondsRemaining > 0) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter both admin email and password.';
      });
      return;
    }

    final cleanEmail = email.toLowerCase();
    if (!cleanEmail.endsWith('@hashzone.com') && !cleanEmail.endsWith('@hashzone.co.in')) {
      setState(() {
        _errorMessage = 'Access restricted strictly to authorized HashZone staff.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      await _authService.signInWithEmailAndPassword(email, password);

      // Password successful: reset failed attempt counter
      await _sessionService.resetFailedAttempts();

      // Fetch authorized 2FA phone numbers from Firestore
      final phones = await _minMothService.getAuthorizedPhones();

      setState(() {
        _authenticatedEmail = email;
        _authorizedPhones = phones;
        _selectedPhone = phones.isNotEmpty ? phones.first : null;
        _step = 2; // Transition to 2FA step
        _errorMessage = null;
      });
    } on FirebaseAuthException catch (e) {
      // Record failed attempt for brute-force defense
      final lockoutDuration = await _sessionService.recordFailedAttempt();
      if (lockoutDuration > 0) {
        _startLockoutCountdown(lockoutDuration);
        setState(() {
          _errorMessage =
              'Account locked for 15 minutes due to 5 consecutive failed login attempts.';
        });
        return;
      }

      String msg;
      switch (e.code) {
        case 'user-not-found':
          msg = 'No admin user found with this email. Please check credentials.';
          break;
        case 'wrong-password':
        case 'invalid-credential':
          msg = 'Invalid email or password. Attempt has been recorded for security.';
          break;
        case 'invalid-email':
          msg = 'Invalid email address format.';
          break;
        case 'user-disabled':
          msg = 'This admin account has been disabled.';
          break;
        case 'too-many-requests':
          msg = 'Firebase has temporarily blocked requests from this device. Please wait.';
          break;
        default:
          msg = e.message ?? 'Authentication failed.';
          break;
      }
      setState(() {
        _errorMessage = msg;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Authentication error: ${e.toString()}';
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── STEP 2A: SEND 2FA OTP ───────────────────────────────────────────────────
  Future<void> _handleSendOtp() async {
    if (_selectedPhone == null || _selectedPhone!.isEmpty) {
      setState(() {
        _errorMessage = 'Please select a phone number for 2FA verification.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      await _minMothService.sendOtp(_selectedPhone!);
      _startResendCooldown();
      setState(() {
        _otpSent = true;
        _successMessage =
            'Security code sent to ${MinMothService.maskPhoneNumber(_selectedPhone!)}. Please check WhatsApp / SMS.';
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── STEP 2B: VERIFY 2FA OTP & ENTER ADMIN PANEL ─────────────────────────────
  Future<void> _handleVerifyOtp() async {
    final code = _otpController.text.trim();
    if (code.length < 6) {
      setState(() {
        _errorMessage = 'Please enter the complete 6-digit security code.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final isValid = await _minMothService.verifyOtp(
        phone: _selectedPhone!,
        code: code,
      );

      if (isValid) {
        // Mark 2FA verified for the active session
        _authService.set2FAVerified(true);

        // Record audit trail in Firestore
        await _authService.logAdminLogin(
          email: _authenticatedEmail ?? 'admin@hashzone.com',
          verifiedPhoneMasked: MinMothService.maskPhoneNumber(_selectedPhone!),
        );

        if (mounted) {
          context.go('/admin/dashboard');
        }
      } else {
        setState(() {
          _errorMessage = 'Invalid security code. Please check and re-enter.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── CANCEL 2FA & RETURN TO STEP 1 ──────────────────────────────────────────
  Future<void> _handleCancel2FA() async {
    _resendTimer?.cancel();
    await _authService.signOut();
    setState(() {
      _step = 1;
      _otpSent = false;
      _otpController.clear();
      _errorMessage = null;
      _successMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isLocked = _lockoutSecondsRemaining > 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F8),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
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
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF000000)),
                      image: const DecorationImage(
                        image: AssetImage('assets/images/logo.jpg'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'HASH ZONE',
                    style: GoogleFonts.cormorantGaramond(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 3.0,
                      color: const Color(0xFF000000),
                    ),
                  ),
                  Text(
                    _step == 1 ? 'ADMIN PORTAL LOGIN' : 'TWO-FACTOR VERIFICATION',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2.0,
                      color: _step == 1 ? const Color(0xFF666666) : const Color(0xFF0066CC),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Lockout Banner
                  if (isLocked)
                    Container(
                      padding: const EdgeInsets.all(14),
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF0F0),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE53935)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.lock_clock, color: Color(0xFFE53935), size: 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Portal Locked for Security',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFFD32F2F),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '5 consecutive failed attempts. Try again in ${_formatLockoutTime(_lockoutSecondsRemaining)}',
                                  style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF555555)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Error Message Banner
                  if (_errorMessage != null && !isLocked)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 18),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.red.withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.redAccent, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: GoogleFonts.inter(fontSize: 11, color: Colors.redAccent, height: 1.3),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Success Message Banner
                  if (_successMessage != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 18),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.green.withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle_outline, color: Colors.green, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _successMessage!,
                              style: GoogleFonts.inter(fontSize: 11, color: Colors.green.shade800, height: 1.3),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // ── VIEW 1: EMAIL & PASSWORD ──────────────────────────────────
                  if (_step == 1) ...[
                    TextFormField(
                      controller: _emailController,
                      enabled: !isLocked && !_isLoading,
                      keyboardType: TextInputType.emailAddress,
                      style: GoogleFonts.inter(color: Colors.black, fontSize: 13),
                      decoration: const InputDecoration(
                        labelText: 'Admin Email',
                        hintText: 'admin@hashzone.com',
                        prefixIcon: Icon(Icons.email_outlined, color: Color(0xFF555555)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      enabled: !isLocked && !_isLoading,
                      obscureText: true,
                      style: GoogleFonts.inter(color: Colors.black, fontSize: 13),
                      decoration: const InputDecoration(
                        labelText: 'Password',
                        prefixIcon: Icon(Icons.lock_outline, color: Color(0xFF555555)),
                      ),
                      onFieldSubmitted: (_) => _handlePasswordStep(),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: isLocked || _isLoading ? null : _handlePasswordStep,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : Text(
                                'CONTINUE TO 2FA VERIFICATION →',
                                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                      ),
                    ),
                  ],

                  // ── VIEW 2: 2FA MINIMOTH OTP ──────────────────────────────────
                  if (_step == 2) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9F9FB),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE5E5EA)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Authorized 2FA Security Number',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF333333),
                            ),
                          ),
                          const SizedBox(height: 8),

                          // If OTP is NOT yet sent, allow picking number from dropdown
                          if (!_otpSent) ...[
                            DropdownButtonFormField<String>(
                              initialValue: _selectedPhone,
                              items: _authorizedPhones.map((phone) {
                                return DropdownMenuItem<String>(
                                  value: phone,
                                  child: Text(
                                    MinMothService.maskPhoneNumber(phone),
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black,
                                    ),
                                  ),
                                );
                              }).toList(),
                              onChanged: _isLoading
                                  ? null
                                  : (val) {
                                      setState(() {
                                        _selectedPhone = val;
                                      });
                                    },
                              decoration: InputDecoration(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                prefixIcon: const Icon(Icons.phone_android, size: 20, color: Colors.black54),
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              height: 44,
                              child: ElevatedButton.icon(
                                onPressed: _isLoading ? null : _handleSendOtp,
                                icon: const Icon(Icons.send_rounded, size: 16),
                                label: Text(
                                  'SEND OTP (WHATSAPP / SMS)',
                                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0066CC),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                              ),
                            ),
                          ] else ...[
                            // OTP is sent: Show masked number + option to change number
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.verified_user, size: 18, color: Colors.green),
                                    const SizedBox(width: 8),
                                    Text(
                                      MinMothService.maskPhoneNumber(_selectedPhone ?? ''),
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ],
                                ),
                                TextButton(
                                  onPressed: _isLoading
                                      ? null
                                      : () {
                                          setState(() {
                                            _otpSent = false;
                                            _otpController.clear();
                                            _errorMessage = null;
                                            _successMessage = null;
                                          });
                                        },
                                  child: Text(
                                    'Change Number',
                                    style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF0066CC)),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),

                    if (_otpSent) ...[
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _otpController,
                        enabled: !_isLoading,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 22,
                          letterSpacing: 8.0,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                        decoration: InputDecoration(
                          counterText: '',
                          hintText: '------',
                          labelText: 'Enter 6-Digit Code',
                          hintStyle: GoogleFonts.inter(letterSpacing: 8.0, color: Colors.black26),
                          prefixIcon: const Icon(Icons.pin_outlined, color: Colors.black54),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onFieldSubmitted: (_) => _handleVerifyOtp(),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleVerifyOtp,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : Text(
                                  'VERIFY & ENTER ADMIN PORTAL',
                                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (_resendCooldownSeconds > 0)
                            Text(
                              'Resend code in ${_resendCooldownSeconds}s',
                              style: GoogleFonts.inter(fontSize: 12, color: Colors.black45),
                            )
                          else
                            TextButton.icon(
                              onPressed: _isLoading ? null : _handleSendOtp,
                              icon: const Icon(Icons.refresh, size: 14),
                              label: Text(
                                'Resend Code',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF0066CC),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: _isLoading ? null : _handleCancel2FA,
                      child: Text(
                        '← Cancel & Sign In as Different User',
                        style: GoogleFonts.inter(fontSize: 11, color: Colors.black54),
                      ),
                    ),
                  ],

                  if (_step == 1) ...[
                    const SizedBox(height: 20),
                    TextButton(
                      onPressed: () => context.go('/'),
                      child: Text(
                        '← Return to Public Website',
                        style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF666666)),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
