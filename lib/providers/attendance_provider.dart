import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import '../core/constants/api_constants.dart';

class AttendanceProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = false;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<bool> markAttendance({
    required String courseId, 
    required String sessionId,
    String? faceImageData, // Base64 image string
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final token = await _auth.currentUser?.getIdToken();
      final url = Uri.parse(ApiConstants.attendanceVerifyEndpoint);

      print("🔵 [API REQUEST] POST $url");
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'course_id': courseId,
          'session_id': sessionId,
          'timestamp': DateTime.now().toIso8601String(),
          'face_image': faceImageData, // Send captured image for server-side verification
        }),
      );

      print("🟢 [API RESPONSE] Status: ${response.statusCode}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        final data = jsonDecode(response.body);
        _error = data['message'] ?? "Verification Failed";
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      print("🔴 [EXCEPTION] Mark Attendance: $e");
      _error = "Connection Error";
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}