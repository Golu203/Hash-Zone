// ─── CustomerAuthProvider ─────────────────────────────────────────────────────
// ChangeNotifier that tracks customer authentication state and Firestore profile.
// Completely separate from admin AuthService.

import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/customer_profile.dart';
import '../services/customer_auth_service.dart';

// Broadcasts uid (string) when signed in, null when signed out.
// Used by main.dart to wire CartProvider and AddressProvider.

enum CustomerAuthStatus { loading, authenticated, unauthenticated }

class CustomerAuthProvider extends ChangeNotifier {
  final CustomerAuthService _service;

  User? _firebaseUser;
  CustomerProfile? _profile;
  CustomerAuthStatus _status = CustomerAuthStatus.loading;
  StreamSubscription<User?>? _authSub;
  StreamSubscription<CustomerProfile?>? _profileSub;

  CustomerAuthProvider(this._service) {
    _init();
  }

  // ── Public Getters ──────────────────────────────────────────────────────────
  User? get firebaseUser => _firebaseUser;
  CustomerProfile? get profile => _profile;
  CustomerAuthStatus get status => _status;
  bool get isLoading => _status == CustomerAuthStatus.loading;

  /// True ONLY when Firebase session exists AND onboarding is fully complete.
  /// A user who signed up but didn't finish onboarding is NOT authenticated.
  bool get isAuthenticated =>
      _status == CustomerAuthStatus.authenticated &&
      _profile != null &&
      _profile!.onboardingComplete;

  /// True when Firebase has a session (regardless of onboarding).
  /// Used internally by the onboarding screen to know a Firebase user exists.
  bool get isFirebaseSignedIn => _firebaseUser != null;

  /// True when signed in via Firebase but onboarding is not yet complete.
  bool get needsOnboarding =>
      isFirebaseSignedIn && (_profile == null || !_profile!.onboardingComplete);

  /// Stream of uid (non-null) when signed in, null when signed out.
  /// Used by main.dart to wire CartProvider + AddressProvider.
  Stream<String?> get authStateStream => _service.authStateChanges.map((u) => u?.uid);


  // ── Init ────────────────────────────────────────────────────────────────────
  void _init() {
    _authSub = _service.authStateChanges.listen((user) async {
      _firebaseUser = user;
      _profileSub?.cancel();

      if (user == null) {
        _profile = null;
        _status = CustomerAuthStatus.unauthenticated;
        notifyListeners();
        return;
      }

      // Stream the Firestore profile in real-time
      _profileSub = _service.streamProfile(user.uid).listen((profile) async {
        if (profile == null) {
          await _service.createProfileIfMissing(user);
          return;
        }
        _profile = profile;
        // Set status to authenticated regardless – isAuthenticated getter
        // enforces onboardingComplete requirement on top of this.
        _status = CustomerAuthStatus.authenticated;
        notifyListeners();
      });
    });
  }

  // ── Auth Actions ────────────────────────────────────────────────────────────
  Future<void> signUpWithEmail(String email, String password) async {
    await _service.signUpWithEmail(email, password);
  }

  Future<void> signInWithEmail(String email, String password) async {
    await _service.signInWithEmail(email, password);
  }

  /// Returns true if the user is signing in for the first time (needs onboarding).
  Future<bool> signInWithGoogle() async {
    final result = await _service.signInWithGoogle();
    return result.isNewUser;
  }

  Future<void> sendPasswordReset(String email) async {
    await _service.sendPasswordResetEmail(email);
  }

  Future<void> signOut() async {
    await _service.signOut();
  }

  Future<void> completeOnboarding({
    required String displayName,
    required String companyName,
    required String phoneNumber,
    required String whatsAppNumber,
    required String businessIdType,
    required String businessIdValue,
    required CustomerAddress address,
    required bool termsAccepted,
    required bool privacyAccepted,
  }) async {
    if (_firebaseUser == null) return;
    await _service.completeOnboarding(
      _firebaseUser!.uid,
      displayName: displayName,
      companyName: companyName,
      phoneNumber: phoneNumber,
      whatsAppNumber: whatsAppNumber,
      businessIdType: businessIdType,
      businessIdValue: businessIdValue,
      address: address,
      termsAccepted: termsAccepted,
      privacyAccepted: privacyAccepted,
    );
    // Profile stream will automatically update notifying listeners.
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _profileSub?.cancel();
    super.dispose();
  }
}
