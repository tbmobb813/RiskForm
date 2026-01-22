import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../exceptions/app_exceptions.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

/// Provides the current auth state as a stream.
final authStateProvider = StreamProvider<User?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges;
});

/// Provides the current user ID or null if not authenticated.
final currentUserIdProvider = Provider<String?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.whenData((user) => user?.uid).value;
});

class AuthService {
  final FirebaseAuth? _auth;
  final bool _noop;

  static FirebaseAuth? _tryResolve(FirebaseAuth? auth) {
    try {
      return auth ?? FirebaseAuth.instance;
    } catch (_) {
      return null;
    }
  }

  /// Default constructor tries to use the provided [auth] or the default
  /// `FirebaseAuth.instance`. If the Firebase native platform isn't
  /// available (desktop dev), the constructor will fall back to a noop
  /// mode so the app can run without a native Firebase implementation.
  AuthService([FirebaseAuth? auth]) : _auth = _tryResolve(auth), _noop = _tryResolve(auth) == null;
  /// Explicit noop constructor for development where Firebase is not
  /// available. Methods will return empty/default values.
  AuthService.noop()
      : _auth = null,
        _noop = true;

  /// Current user ID or null if not authenticated.
  String? get currentUserId => _auth?.currentUser?.uid;

  /// Current user or null if not authenticated.
  User? get currentUser => _auth?.currentUser;

  /// Whether a user is currently signed in.
  bool get isAuthenticated => _auth?.currentUser != null;

  /// Stream of auth state changes.
  Stream<User?> get authStateChanges => _auth?.authStateChanges() ?? Stream.value(null);

  /// Signs in with email and password.
  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      if (_auth == null) throw FirebaseAuthException(code: 'no-app', message: 'No Firebase');
      return await _auth!.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _mapFirebaseAuthException(e);
    }
  }

  /// Creates a new account with email and password.
  Future<UserCredential> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      if (_auth == null) throw FirebaseAuthException(code: 'no-app', message: 'No Firebase');
      return await _auth!.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _mapFirebaseAuthException(e);
    }
  }

  /// Signs out the current user.
  Future<void> signOut() async {
    if (_auth == null) return;
    await _auth!.signOut();
  }

  /// Sends a password reset email.
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      if (_auth == null) throw FirebaseAuthException(code: 'no-app', message: 'No Firebase');
      await _auth!.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _mapFirebaseAuthException(e);
    }
  }

  /// Requires authentication - throws if not authenticated.
  /// Returns the current user ID.
  String requireAuth() {
    final uid = currentUserId;
    if (uid == null) {
      throw AuthenticationException.notLoggedIn();
    }
    return uid;
  }

  /// Maps Firebase auth exceptions to app exceptions.
  AuthenticationException _mapFirebaseAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return const AuthenticationException('No account found with this email');
      case 'wrong-password':
        return const AuthenticationException('Incorrect password');
      case 'email-already-in-use':
        return const AuthenticationException('An account already exists with this email');
      case 'weak-password':
        return const AuthenticationException('Password is too weak');
      case 'invalid-email':
        return const AuthenticationException('Invalid email address');
      case 'user-disabled':
        return const AuthenticationException('This account has been disabled');
      case 'too-many-requests':
        return const AuthenticationException('Too many attempts. Please try again later');
      case 'network-request-failed':
        return const AuthenticationException('Network error. Check your connection');
      default:
        return AuthenticationException('Authentication failed: ${e.message}');
    }
  }
}
