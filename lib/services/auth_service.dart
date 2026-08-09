import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  late final FirebaseAuth _auth;

  AuthService() {
    FirebaseAuth authInstance;
    try {
      final app = Firebase.app('AdminApp');
      authInstance = FirebaseAuth.instanceFor(app: app);
    } catch (_) {
      authInstance = FirebaseAuth.instance;
    }
    _auth = authInstance;
  }

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;
  bool get isAuthenticated => _auth.currentUser != null;

  Future<UserCredential> signInWithEmailAndPassword(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
