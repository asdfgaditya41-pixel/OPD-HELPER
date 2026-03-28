import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../models/app_user.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthService _authService = AuthService();
  
  User? _firebaseUser;
  AppUser? _appUser;
  bool _isLoading = true;

  User? get firebaseUser => _firebaseUser;
  AppUser? get appUser => _appUser;
  bool get isLoggedIn => _firebaseUser != null;
  bool get isLoading => _isLoading;

  AuthViewModel() {
    _initAuthListener();
  }

  void _initAuthListener() {
    _authService.authStateChanges.listen((User? user) async {
      _firebaseUser = user;
      if (user != null) {
        _appUser = await _authService.getUserProfile(user.uid);
      } else {
        _appUser = null;
      }
      _isLoading = false;
      notifyListeners();
    });
  }

  Future<void> signInWithGoogle() async {
    _setLoading(true);
    try {
      await _authService.signInWithGoogle();
      // Auth listener handles the rest
    } catch (e) {
      _setLoading(false);
      rethrow;
    }
  }

  Future<void> signUpWithEmail(String email, String password, String name) async {
    _setLoading(true);
    try {
      await _authService.signUpWithEmail(email, password, name);
    } catch (e) {
      _setLoading(false);
      rethrow;
    }
  }

  Future<void> loginWithEmail(String email, String password) async {
    _setLoading(true);
    try {
      await _authService.loginWithEmail(email, password);
    } catch (e) {
      _setLoading(false);
      rethrow;
    }
  }

  Future<void> signOut() async {
    _setLoading(true);
    await _authService.signOut();
  }

  void _setLoading(bool val) {
    _isLoading = val;
    notifyListeners();
  }
  
  String parseAuthError(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found': return 'No user found for that email.';
        case 'wrong-password': return 'Wrong password provided.';
        case 'email-already-in-use': return 'The account already exists for that email.';
        case 'invalid-email': return 'The email address is badly formatted.';
        case 'weak-password': return 'The password provided is too weak.';
        default: return error.message ?? 'An unknown authentication error occurred.';
      }
    }
    return error.toString();
  }
}
