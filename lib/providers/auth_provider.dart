import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import '../core/constants/api_constants.dart';

enum AuthStatus {
  initial,
  authenticating,
  authenticated,
  unauthenticated,
  error,
}

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  AuthStatus _status = AuthStatus.initial;
  String? _errorMessage;
  String? _userRole; // 'student', 'faculty', 'admin'

  AuthStatus get status => _status;
  String? get errorMessage => _errorMessage;
  String? get userRole => _userRole;
  User? get firebaseUser => _firebaseAuth.currentUser;

  // 1. Check current session on Startup
  Future<void> checkSession() async {
    final user = _firebaseAuth.currentUser;
    if (user != null) {
      try {
        // Refresh the ID token to ensure it's valid
        await user.getIdToken(true);
        await _fetchUserProfile(user);
        _status = AuthStatus.authenticated;
      } catch (e) {
        print("Session Check Error: $e");
        // If profile fetch fails, we might be offline or token expired
        // Try to keep them logged in if we have a role, otherwise force logout
        if (_userRole != null) {
          _status = AuthStatus.authenticated;
        } else {
          // Optional: You can choose to keep them logged in and retry later
          // For now, let's allow them to stay if firebaseUser exists
          _status = AuthStatus.authenticated;
        }
      }
    } else {
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  // 2. Login Flow
  Future<void> login(String email, String password) async {
    _status = AuthStatus.authenticating;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse(ApiConstants.loginEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final customToken =
            data['user']['token']; // Check if token is inside user or root
        final tokenToUse = customToken ?? data['token']; // Fallback

        final userPayload = data['user'];

        // B. Exchange Custom Token for Firebase Session
        await _firebaseAuth.signInWithCustomToken(tokenToUse);

        // C. Set Role
        _userRole = userPayload['role'];
        _status = AuthStatus.authenticated;
      } else {
        _status = AuthStatus.error;
        _errorMessage = data['message'] ?? 'Login failed';
      }
    } catch (e) {
      print("Login Exception: $e"); // View this in your debug console!

      // FIX: Check if Firebase actually signed in despite the error
      // (e.g. if the HTTP connection dropped AFTER auth but BEFORE response parsing)
      if (_firebaseAuth.currentUser != null) {
        try {
          // Attempt to recover profile if we missed the payload
          await _fetchUserProfile(_firebaseAuth.currentUser!);
          _status = AuthStatus.authenticated;
          _errorMessage = null;
        } catch (profileError) {
          _status = AuthStatus.error;
          _errorMessage =
              'Login succeeded, but failed to load profile. Please refresh.';
        }
      } else {
        _status = AuthStatus.error;
        _errorMessage = 'Connection error. Please try again.';
      }
    }
    notifyListeners();
  }

  // 3. Fetch Profile
  Future<void> _fetchUserProfile(User user) async {
    final idToken = await user.getIdToken();

    final response = await http.get(
      Uri.parse(ApiConstants.profileEndpoint),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      _userRole = data['user']['role'];
      notifyListeners();
    } else {
      throw Exception("Failed to fetch profile: ${response.statusCode}");
    }
  }

  Future<void> logout() async {
    await _firebaseAuth.signOut();
    _status = AuthStatus.unauthenticated;
    _userRole = null;
    notifyListeners();
  }
}
