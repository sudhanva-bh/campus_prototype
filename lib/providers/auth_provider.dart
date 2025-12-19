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
  String? _userRole;
  Map<String, dynamic>? _userProfile; // Store full profile data
  bool _isServerHealthy = true;

  AuthStatus get status => _status;
  String? get errorMessage => _errorMessage;
  String? get userRole => _userRole;
  Map<String, dynamic>? get userProfile => _userProfile;
  bool get isServerHealthy => _isServerHealthy;
  User? get firebaseUser => _firebaseAuth.currentUser;

  // 1. Health Check
  Future<bool> checkHealth() async {
    try {
      print("🔵 [API REQUEST] GET ${ApiConstants.healthEndpoint}");
      final response = await http.get(Uri.parse(ApiConstants.healthEndpoint));
      print("🟢 [API RESPONSE] Status: ${response.statusCode}");

      _isServerHealthy = response.statusCode == 200;
    } catch (e) {
      print("🔴 [EXCEPTION] Health Check: $e");
      _isServerHealthy = false;
    }
    notifyListeners();
    return _isServerHealthy;
  }

  // 2. Check Session
  Future<void> checkSession() async {
    await checkHealth();
    final user = _firebaseAuth.currentUser;
    if (user != null) {
      try {
        await user.getIdToken(true);
        await _fetchUserProfile(user);
        _status = AuthStatus.authenticated;
      } catch (e) {
        print("🔴 [SESSION ERROR] $e");
        // Maintain session if firebase user exists, even if API fails
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
      print("🔵 [API REQUEST] POST ${ApiConstants.loginEndpoint}");

      final response = await http.post(
        Uri.parse(ApiConstants.loginEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      print("🟢 [API RESPONSE] Status: ${response.statusCode}");
      print("🟢 [API RESPONSE] Body: ${response.body}");

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

    if (role == 'student') {
      body['student_info'] = roleInfo;
    } else if (role == 'faculty') {
      body['faculty_info'] = roleInfo;
    }

    try {
      print("🔵 [API REQUEST] POST ${ApiConstants.registerEndpoint}");
      print("🔵 [BODY] $body");

      final response = await http.post(
        Uri.parse(ApiConstants.registerEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      print("🟢 [API RESPONSE] Status: ${response.statusCode}");
      print("🟢 [API RESPONSE] Body: ${response.body}");

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

      print("🔵 [API REQUEST] PUT ${ApiConstants.profileEndpoint}");
      print("🔵 [BODY] $updates");

      final response = await http.put(
        Uri.parse(ApiConstants.profileEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: jsonEncode(updates),
      );

      print("🟢 [API RESPONSE] Status: ${response.statusCode}");
      print("🟢 [API RESPONSE] Body: ${response.body}");

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        if (data['user'] != null) {
          _userProfile = data['user']; // Update local cache
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
      print("🔴 [EXCEPTION] Update Profile: $e");
      _errorMessage = 'Connection error during update.';
      notifyListeners();
      return false;
    }
  }

  // 6. Fetch Profile
  Future<void> fetchProfile() async {
    if (_firebaseAuth.currentUser != null) {
      await _fetchUserProfile(_firebaseAuth.currentUser!);
    }
  }

  // Helper: Fetch Profile Internal
  Future<void> _fetchUserProfile(User user) async {
    try {
      final idToken = await user.getIdToken();

      print("🔵 [API REQUEST] GET ${ApiConstants.profileEndpoint}");

      final response = await http.get(
        Uri.parse(ApiConstants.profileEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
      );

      print("🟢 [API RESPONSE] Status: ${response.statusCode}");
      print("🟢 [API RESPONSE] Body: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _userProfile = data['user']; // Store the full profile object
        _userRole = data['user']['role'];
        notifyListeners();
      } else {
        print(
          "⚠️ [API WARNING] Failed to fetch profile: ${response.statusCode}",
        );
      }
    } catch (e) {
      print("🔴 [EXCEPTION] Fetch Profile: $e");
      rethrow;
    }
  }

  Future<void> _handleAuthSuccess(Map<String, dynamic> data) async {
    final customToken = data['user']['token'] ?? data['token'];
    final userPayload = data['user'];

    await _firebaseAuth.signInWithCustomToken(customToken);

    _userProfile = userPayload;
    _userRole = userPayload['role'];
    _status = AuthStatus.authenticated;
  }

  void _handleAuthException(dynamic e) {
    print("🔴 [AUTH EXCEPTION] $e");
    if (_firebaseAuth.currentUser != null) {
      _status = AuthStatus.authenticated;
    } else {
      _status = AuthStatus.error;
      _errorMessage = 'Connection error. Please try again.';
    }
  }

  Future<void> logout() async {
    await _firebaseAuth.signOut();
    _status = AuthStatus.unauthenticated;
    _userRole = null;
    _userProfile = null;
    notifyListeners();
  }
}
