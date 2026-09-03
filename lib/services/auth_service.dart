import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  static bool _is2FAVerified = false;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;
  bool get isAuthenticated => _auth.currentUser != null;
  bool get is2FAVerified => _is2FAVerified;

  void set2FAVerified(bool val) {
    _is2FAVerified = val;
  }

  Future<UserCredential> signInWithEmailAndPassword(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );
  }

  /// Records a successful admin login to the adminAudit collection in Firestore
  Future<void> logAdminLogin({
    required String email,
    required String verifiedPhoneMasked,
  }) async {
    final userAgent = kIsWeb
        ? 'Web Browser (${defaultTargetPlatform.name})'
        : defaultTargetPlatform.name;

    try {
      await _db.collection('adminAudit').add({
        'adminEmail': email,
        'timestamp': FieldValue.serverTimestamp(),
        'userAgent': userAgent,
        'status': 'SUCCESS',
        'authMethod': 'EMAIL_PASSWORD_2FA_MINIMOTH',
        'verifiedPhone': verifiedPhoneMasked,
      });
    } catch (e) {
      debugPrint('[AuthService] Could not write admin audit record: $e');
    }
  }

  Future<void> signOut() async {
    _is2FAVerified = false;
    await _auth.signOut();
  }
}
