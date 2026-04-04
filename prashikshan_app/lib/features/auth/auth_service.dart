import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'auth_clients.dart';

/// Exception for authentication errors with user-friendly messages
class AuthException implements Exception {
  AuthException({
    required this.code,
    required this.message,
    this.userMessage,
  });

  final String code;
  final String message;
  final String? userMessage;

  @override
  String toString() => userMessage ?? message;
}

/// Service for handling all authentication operations
class AuthService {
  static final AuthService _instance = AuthService._internal();

  factory AuthService() {
    return _instance;
  }

  AuthService._internal();

  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get current user
  User? get currentUser => _firebaseAuth.currentUser;

  /// Stream of auth state changes
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  /// Parses FirebaseAuthException into user-friendly AuthException
  AuthException _parseException(FirebaseAuthException e) {
    String userMessage = 'An error occurred during authentication';

    switch (e.code) {
      case 'user-not-found':
        userMessage = 'Email not found. Please sign up first.';
        break;
      case 'wrong-password':
        userMessage = 'Incorrect password. Please try again.';
        break;
      case 'email-already-in-use':
        userMessage = 'This email is already registered.';
        break;
      case 'weak-password':
        userMessage = 'Password is too weak. Use at least 6 characters.';
        break;
      case 'invalid-email':
        userMessage = 'Invalid email address.';
        break;
      case 'operation-not-allowed':
        userMessage = 'This operation is not allowed.';
        break;
      case 'too-many-requests':
        userMessage = 'Too many login attempts. Please try again later.';
        break;
      default:
        userMessage = e.message ?? 'Authentication failed';
    }

    return AuthException(
      code: e.code,
      message: e.message ?? '',
      userMessage: userMessage,
    );
  }

  /// Login with email and password
  Future<UserCredential> loginWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential credential =
          await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return credential;
    } on FirebaseAuthException catch (e) {
      throw _parseException(e);
    } catch (e) {
      throw AuthException(
        code: 'unknown-error',
        message: e.toString(),
        userMessage: 'An unexpected error occurred',
      );
    }
  }

  /// Signup with email and password
  Future<UserCredential> signupWithEmail({
    required String email,
    required String password,
    required String fullName,
    required String userType, // 'student', 'university', 'company'
  }) async {
    try {
      final UserCredential credential =
          await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      // Update user profile
      await credential.user?.updateDisplayName(fullName);

      // Create user document in Firestore with 'role' field for AppRouter
      await _firestore.collection('users').doc(credential.user!.uid).set(
        {
          'uid': credential.user!.uid,
          'email': email.trim(),
          'name': fullName,
          'role': userType, // ✅ CRITICAL: Must be 'role' for AppRouter routing
          'isOnboarded': false,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
      );

      debugPrint('✅ [SIGNUP] Created user doc | role: $userType | email: $email');

      return credential;
    } on FirebaseAuthException catch (e) {
      throw _parseException(e);
    } catch (e) {
      throw AuthException(
        code: 'unknown-error',
        message: e.toString(),
        userMessage: 'An unexpected error occurred',
      );
    }
  }

  /// Google Sign-In
  Future<UserCredential> signInWithGoogle() async {
    try {
      // Sign out first to show account picker
      await googleSignInClient.signOut();

      // Trigger Google Sign-In
      final GoogleSignInAccount? googleUser = await googleSignInClient.signIn();

      if (googleUser == null) {
        throw AuthException(
          code: 'cancelled',
          message: 'Google sign-in was cancelled',
          userMessage: 'Sign-in cancelled',
        );
      }

      // Get authentication details
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create Firebase credential
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase
      final UserCredential userCredential =
          await _firebaseAuth.signInWithCredential(credential);

      // Check if user exists in Firestore
      final DocumentSnapshot<Map<String, dynamic>> userDoc = await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      // If new user, create Firestore document
      // Google Sign-In always defaults to 'student' role.
      // Users signing up via email+password get the role they selected on the auth screen.
      if (!userDoc.exists) {
        debugPrint('✅ [GOOGLE SIGNUP] Creating new user doc | role: student');
        await _firestore.collection('users').doc(userCredential.user!.uid).set(
          {
            'uid': userCredential.user!.uid,
            'email': userCredential.user!.email,
            'name': userCredential.user!.displayName ?? 'User',
            'photoUrl': userCredential.user!.photoURL,
            'role': 'student', // ✅ FIXED: Use 'role' key (not 'userType') so AppRouter reads it correctly
            'isOnboarded': false,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          },
        );
      }

      return userCredential;
    } on AuthException {
      rethrow;
    } on FirebaseAuthException catch (e) {
      throw _parseException(e);
    } catch (e) {
      throw AuthException(
        code: 'google-sign-in-error',
        message: e.toString(),
        userMessage: 'Google sign-in failed',
      );
    }
  }

  /// Logout
  Future<void> logout() async {
    try {
      await Future.wait([
        _firebaseAuth.signOut(),
        googleSignInClient.signOut(),
      ]);
    } catch (e) {
      throw AuthException(
        code: 'logout-error',
        message: e.toString(),
        userMessage: 'Logout failed',
      );
    }
  }

  /// Password reset
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(
        email: email.trim(),
      );
    } on FirebaseAuthException catch (e) {
      throw _parseException(e);
    } catch (e) {
      throw AuthException(
        code: 'reset-error',
        message: e.toString(),
        userMessage: 'Failed to send reset email',
      );
    }
  }

  /// Check if user is authenticated
  bool get isAuthenticated => currentUser != null;

  /// Get current user UID
  String? get currentUserUID => currentUser?.uid;
}
