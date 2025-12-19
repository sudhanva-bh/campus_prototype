import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import '../core/constants/api_constants.dart';

enum AuthStatus { initial, authenticating, authenticated, unauthenticated, error }

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  AuthStatus _status = AuthStatus.initial;
  String? _errorMessage;
  String? _userRole;
  bool _isServerHealthy = true;

  AuthStatus get status => _status;
  String? get errorMessage => _errorMessage;
  String? get userRole => _userRole;
  bool get isServerHealthy => _isServerHealthy;
  User? get firebaseUser => _firebaseAuth.currentUser;

  // 1. Health Check
  Future<bool> checkHealth() async {
    try {
      final response = await http.get(Uri.parse(ApiConstants.healthEndpoint));
      if (response.statusCode == 200) {
        _isServerHealthy = true;
      } else {
        _isServerHealthy = false;
      }
    } catch (e) {
      _isServerHealthy = false;
      print("Health Check Failed: $e");
    }
    notifyListeners();
    return _isServerHealthy;
  }

  // 2. Check Session
  Future<void> checkSession() async {
    // Run health check in parallel or before
    await checkHealth();

    final user = _firebaseAuth.currentUser;
    if (user != null) {
      try {
        await user.getIdToken(true);
        await _fetchUserProfile(user);
        _status = AuthStatus.authenticated;
      } catch (e) {
        print("Session Check Error: $e");
        // Allow offline access if we have a user, even if profile fetch fails
        if (_firebaseAuth.currentUser != null) {
           _status = AuthStatus.authenticated;
        } else {
           _status = AuthStatus.unauthenticated;
        }
      }
    } else {
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  // 3. Login
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
        await _handleAuthSuccess(data);
      } else {
        _status = AuthStatus.error;
        _errorMessage = data['message'] ?? 'Login failed';
      }
    } catch (e) {
      _handleAuthException(e);
    }
    notifyListeners();
  }

  // 4. Register
  Future<void> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String role,
    required String institutionId,
    required Map<String, dynamic> roleInfo,
  }) async {
    _status = AuthStatus.authenticating;
    _errorMessage = null;
    notifyListeners();

    final Map<String, dynamic> body = {
      "email": email,
      "password": password,
      "first_name": firstName,
      "last_name": lastName,
      "role": role,
      "institution_id": institutionId,
    };

    // Attach role specific info
    if (role == 'student') {
      body['student_info'] = roleInfo;
    } else if (role == 'faculty') {
      body['faculty_info'] = roleInfo;
    }

    try {
      final response = await http.post(
        Uri.parse(ApiConstants.registerEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201 && data['success'] == true) {
        await _handleAuthSuccess(data);
      } else {
        _status = AuthStatus.error;
        _errorMessage = data['message'] ?? 'Registration failed';
      }
    } catch (e) {
      _handleAuthException(e);
    }
    notifyListeners();
  }

  // 5. Update Profile
  Future<bool> updateProfile(Map<String, dynamic> updates) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) return false;
      
      final idToken = await user.getIdToken();
      
      final response = await http.put(
        Uri.parse(ApiConstants.profileEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: jsonEncode(updates),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        // Update local role if changed (though rare for profile updates)
        if (data['user'] != null && data['user']['role'] != null) {
           _userRole = data['user']['role'];
        }
        notifyListeners();
        return true;
      } else {
        _errorMessage = data['message'] ?? 'Update failed';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Connection error during update.';
      notifyListeners();
      return false;
    }
  }

  // Helper: Handle Successful Auth Response (Login/Register)
  Future<void> _handleAuthSuccess(Map<String, dynamic> data) async {
    final customToken = data['user']['token'] ?? data['token'];
    final userPayload = data['user'];

    await _firebaseAuth.signInWithCustomToken(customToken);
    _userRole = userPayload['role'];
    _status = AuthStatus.authenticated;
  }

  // Helper: Handle Exceptions with recovery check
  void _handleAuthException(dynamic e) {
    print("Auth Exception: $e");
    if (_firebaseAuth.currentUser != null) {
      // Recovery: If firebase signed in but API parsing failed
      _status = AuthStatus.authenticated; 
    } else {
      _status = AuthStatus.error;
      _errorMessage = 'Connection error. Please try again.';
    }
  }

  // Fetch Profile
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
    }
  }

  Future<void> logout() async {
    await _firebaseAuth.signOut();
    _status = AuthStatus.unauthenticated;
    _userRole = null;
    notifyListeners();
  }
}