import 'package:beanbloss/services/user_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;

  bool get isSignedIn => currentUser != null;

  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    await UserService.instance.loadCurrentUser(forceRefresh: true);
    return cred;
  }

  Future<UserCredential> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final displayName = name.trim();
    if (displayName.isNotEmpty) {
      await cred.user?.updateDisplayName(displayName);
      await cred.user?.reload();
    }
    final uid = cred.user?.uid;
    if (uid != null) {
      await UserService.instance.createUserProfile(
        uid: uid,
        name: displayName.isNotEmpty ? displayName : 'Guest',
        email: email,
      );
    }
    return cred;
  }

  Future<void> signOut() async {
    UserService.instance.clear();
    await _auth.signOut();
  }

  static String messageFor(Object error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found':
          return 'No account found for that email.';
        case 'wrong-password':
          return 'Incorrect password. Please try again.';
        case 'invalid-credential':
          return 'Email or password is incorrect.';
        case 'email-already-in-use':
          return 'An account already exists for that email.';
        case 'weak-password':
          return 'Password is too weak. Use at least 8 characters.';
        case 'invalid-email':
          return 'Please enter a valid email address.';
        case 'user-disabled':
          return 'This account has been disabled.';
        case 'too-many-requests':
          return 'Too many attempts. Please try again later.';
        case 'network-request-failed':
          return 'Network error. Check your connection.';
        case 'operation-not-allowed':
          return 'Email/password sign-in is not enabled in Firebase.';
        default:
          return error.message ?? 'Authentication failed. Please try again.';
      }
    }
    return 'Something went wrong. Please try again.';
  }
}
