// ─── CustomerAuthService ──────────────────────────────────────────────────────
// Handles customer authentication only (completely separate from AdminAuthService).
// Uses Firebase Auth: Email/Password + Google (web popup).

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/customer_profile.dart';

class CustomerAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── Auth State ──────────────────────────────────────────────────────────────
  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();
  bool get isSignedIn => _auth.currentUser != null;

  // ── Email / Password Sign-Up ────────────────────────────────────────────────
  Future<UserCredential> signUpWithEmail(String email, String password) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );
    await _createProfile(credential.user!, authProvider: 'email');
    return credential;
  }

  // ── Email / Password Sign-In ────────────────────────────────────────────────
  Future<UserCredential> signInWithEmail(String email, String password) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );
    await _updateLastLogin(credential.user!.uid);
    return credential;
  }

  // ── Google Sign-In (web popup) ──────────────────────────────────────────────
  Future<({UserCredential credential, bool isNewUser})> signInWithGoogle() async {
    final provider = GoogleAuthProvider();
    provider.addScope('email');
    provider.addScope('profile');

    final credential = await _auth.signInWithPopup(provider);
    final user = credential.user!;
    final isNew = credential.additionalUserInfo?.isNewUser ?? false;

    if (isNew) {
      await _createProfile(
        user,
        authProvider: 'google',
        displayName: user.displayName ?? '',
        photoUrl: user.photoURL ?? '',
      );
    } else {
      await _updateLastLogin(user.uid);
    }

    return (credential: credential, isNewUser: isNew);
  }

  // ── Forgot Password ─────────────────────────────────────────────────────────
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  // ── Sign Out ────────────────────────────────────────────────────────────────
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // ── Firestore Profile ───────────────────────────────────────────────────────
  Future<CustomerProfile?> getProfile(String uid) async {
    final doc = await _db.collection('customers').doc(uid).get();
    if (!doc.exists || doc.data() == null) return null;
    return CustomerProfile.fromMap(doc.data()!);
  }

  Stream<CustomerProfile?> streamProfile(String uid) {
    return _db.collection('customers').doc(uid).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return CustomerProfile.fromMap(doc.data()!);
    });
  }

  Future<void> updateProfile(CustomerProfile profile) async {
    await _db.collection('customers').doc(profile.uid).update({
      'displayName': profile.displayName,
      'photoUrl': profile.photoUrl,
      'phoneNumber': profile.phoneNumber,
      'whatsAppNumber': profile.whatsAppNumber,
      'companyName': profile.companyName,
      'address': profile.address.toMap(),
      'onboardingComplete': profile.onboardingComplete,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> completeOnboarding(
    String uid, {
    required String displayName,
    required String companyName,
    required String phoneNumber,
    required String whatsAppNumber,
    required CustomerAddress address,
  }) async {
    await _db.collection('customers').doc(uid).update({
      'displayName': displayName,
      'companyName': companyName,
      'phoneNumber': phoneNumber,
      'whatsAppNumber': whatsAppNumber,
      'address': address.toMap(),
      'onboardingComplete': true,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ── Private Helpers ─────────────────────────────────────────────────────────
  Future<void> _createProfile(
    User user, {
    required String authProvider,
    String displayName = '',
    String photoUrl = '',
  }) async {
    final ref = _db.collection('customers').doc(user.uid);
    final existing = await ref.get();
    if (existing.exists) {
      await _updateLastLogin(user.uid);
      return;
    }

    final profile = CustomerProfile(
      uid: user.uid,
      email: user.email ?? '',
      displayName: displayName.isNotEmpty ? displayName : (user.displayName ?? ''),
      photoUrl: photoUrl.isNotEmpty ? photoUrl : (user.photoURL ?? ''),
      authProvider: authProvider,
      onboardingComplete: false,
      createdAt: DateTime.now(),
    );

    await ref.set({
      ...profile.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'lastLogin': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _updateLastLogin(String uid) async {
    try {
      await _db.collection('customers').doc(uid).update({
        'lastLogin': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      // Profile might not exist yet for legacy users — ignore
    }
  }
}
