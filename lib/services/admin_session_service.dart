import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_service.dart';

/// Manages Admin Panel session security:
/// 1. Brute-force lockout (5 failed attempts = 15-minute lockout).
/// 2. Inactivity auto-logout (30 minutes of idle time).
class AdminSessionService {
  static final AdminSessionService _instance = AdminSessionService._internal();
  factory AdminSessionService() => _instance;
  AdminSessionService._internal();

  static const String _keyFailedAttempts = 'admin_failed_login_attempts';
  static const String _keyLockoutUntil = 'admin_lockout_until_epoch';
  static const int maxAttempts = 5;
  static const Duration lockoutDuration = Duration(minutes: 15);
  static const Duration idleTimeout = Duration(minutes: 30);

  /// Checks if admin login is currently locked out.
  /// Returns remaining seconds of lockout (0 if not locked).
  Future<int> getRemainingLockoutSeconds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lockoutUntilEpoch = prefs.getInt(_keyLockoutUntil) ?? 0;
      if (lockoutUntilEpoch == 0) return 0;

      final nowEpoch = DateTime.now().millisecondsSinceEpoch;
      final diffSeconds = ((lockoutUntilEpoch - nowEpoch) / 1000).ceil();
      if (diffSeconds > 0) {
        return diffSeconds;
      } else {
        // Lockout expired, reset counters
        await resetFailedAttempts();
        return 0;
      }
    } catch (_) {
      return 0;
    }
  }

  /// Records a failed login attempt and applies 15-min lockout if attempts reach 5
  Future<int> recordFailedAttempt() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentAttempts = (prefs.getInt(_keyFailedAttempts) ?? 0) + 1;
      await prefs.setInt(_keyFailedAttempts, currentAttempts);

      if (currentAttempts >= maxAttempts) {
        final lockoutUntil = DateTime.now().add(lockoutDuration).millisecondsSinceEpoch;
        await prefs.setInt(_keyLockoutUntil, lockoutUntil);
        return lockoutDuration.inSeconds;
      }
      return 0;
    } catch (_) {
      return 0;
    }
  }

  /// Resets failed login attempts counter after successful sign in
  Future<void> resetFailedAttempts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyFailedAttempts);
      await prefs.remove(_keyLockoutUntil);
    } catch (_) {}
  }
}

/// A wrapper widget that wraps all Admin Panel screens to monitor user activity.
/// Automatically logs out the admin if idle for 30 minutes.
class AdminInactivityWrapper extends StatefulWidget {
  final Widget child;
  const AdminInactivityWrapper({super.key, required this.child});

  @override
  State<AdminInactivityWrapper> createState() => _AdminInactivityWrapperState();
}

class _AdminInactivityWrapperState extends State<AdminInactivityWrapper> {
  Timer? _idleTimer;

  @override
  void initState() {
    super.initState();
    _resetIdleTimer();
  }

  @override
  void dispose() {
    _idleTimer?.cancel();
    super.dispose();
  }

  void _resetIdleTimer() {
    _idleTimer?.cancel();
    _idleTimer = Timer(AdminSessionService.idleTimeout, _handleSessionTimeout);
  }

  void _handleSessionTimeout() async {
    if (!mounted) return;
    debugPrint('[AdminSession] Inactivity limit reached (30 minutes). Logging out admin.');
    await AuthService().signOut();
    if (mounted) {
      context.go('/admin/login?reason=idle_timeout');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _resetIdleTimer(),
      onPointerMove: (_) => _resetIdleTimer(),
      onPointerHover: (_) => _resetIdleTimer(),
      onPointerSignal: (_) => _resetIdleTimer(),
      child: widget.child,
    );
  }
}
