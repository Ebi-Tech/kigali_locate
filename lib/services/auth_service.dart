import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'firestore_service.dart';
import '../models/user_profile_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestoreService;

  AuthService(this._firestoreService);

  Stream<User?> get authStateChanges => _auth.userChanges();

  User? get currentUser => _auth.currentUser;

  bool get isEmailVerified => _auth.currentUser?.emailVerified ?? false;

  Future<UserCredential> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      // Update display name
      await credential.user?.updateDisplayName(fullName.trim());

      // Send email verification
      await credential.user?.sendEmailVerification();

      // Create user profile in Firestore (non-blocking — auth succeeded regardless)
      try {
        final profile = UserProfileModel(
          uid: credential.user!.uid,
          fullName: fullName.trim(),
          email: email.trim(),
          createdAt: DateTime.now(),
        );
        await _firestoreService.createUserProfile(profile);
      } catch (e) {
        debugPrint('Warning: Failed to create Firestore user profile: $e');
        // Profile creation failure does not block auth success.
        // Fix Firestore security rules to allow authenticated users to write their own profile.
      }

      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> sendEmailVerification() async {
    await _auth.currentUser?.sendEmailVerification();
  }

  Future<void> reloadUser() async {
    await _auth.currentUser?.reload();
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  String _handleAuthException(FirebaseAuthException e) {
    debugPrint('FirebaseAuthException: ${e.code} - ${e.message}');
    switch (e.code) {
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Please check your connection.';
      default:
        return e.message ?? 'Authentication failed. Please try again.';
    }
  }
}
