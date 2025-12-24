import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart'; // Required for MediaType
import 'package:firebase_auth/firebase_auth.dart';
import '../core/constants/api_constants.dart';

class AttendanceProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = false;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;


  Future<bool> startSession({
    required String courseId,
    required String classSessionId,
  })
  async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final token = await _auth.currentUser?.getIdToken();
      final url = Uri.parse(ApiConstants.attendanceStartSessionEndpoint);

      final today = DateTime.now();
      final dateString =
          "${today.year.toString().padLeft(4, '0')}-"
          "${today.month.toString().padLeft(2, '0')}-"
          "${today.day.toString().padLeft(2, '0')}";

      print("🔵 [API REQUEST] POST $url");

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'course_id': courseId,
          'class_session_id': classSessionId,
          'date': dateString,
        }),
      );

      print("🟢 [API RESPONSE] Status: ${response.statusCode}");
      print("🟢 [API RESPONSE] Body: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        final data = jsonDecode(response.body);
        _error = data['message'] ?? "Session Start Failed";
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      print("🔴 [EXCEPTION] Start Session: $e");
      _error = "Connection Error";
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  Future<bool> closeSession({
    required String sessionId,
  })
  async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final token = await _auth.currentUser?.getIdToken();
      final url = Uri.parse(ApiConstants.closeSessionUrl(sessionId));
      print("🔵 [API REQUEST] POST $url");
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      print("🟢 [API RESPONSE] Status: ${response.statusCode}");
      print("🟢 [API RESPONSE] Body: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        final data = jsonDecode(response.body);
        _error = data['message'] ?? "Session End Failed";
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      print("🔴 [EXCEPTION] End Session: $e");
      _error = "Connection Error";
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }


  Future<bool> verifyFace(File imageFile) async  {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final token = await _auth.currentUser?.getIdToken();
      final url = Uri.parse(ApiConstants.attendanceVerifyFaceEndpoint);

      print("🔵 [API REQUEST] POST $url (Verify Face)");

      final request = http.MultipartRequest('POST', url);
      request.headers['Authorization'] = 'Bearer $token';
      // Explicitly set content type to ensure server recognizes it as an image
      request.files.add(await http.MultipartFile.fromPath(
        'image',
        imageFile.path,
        contentType: MediaType('image', 'jpeg'),
      ));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print("🟢 [API RESPONSE] Status: ${response.statusCode}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return true;
        } else {
          _error = data['message'] ?? "Face verification failed";
          _isLoading = false;
          notifyListeners();
          return false;
        }
      } else {
        print("🔴 [SERVER ERROR BODY]: ${response.body}");
        try {
          final data = jsonDecode(response.body);
          _error = data['message'] ?? "Server Error: ${response.statusCode}";
        } catch (_) {
          _error = "Server Internal Error (${response.statusCode}). Check logs.";
        }
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      print("🔴 [EXCEPTION] Verify Face: $e");
      _error = "Connection Error";
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }


  Future<bool> markAttendance({
    required String courseId,
    required String sessionId,
    File? imageFile,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final token = await _auth.currentUser?.getIdToken();
      final url = Uri.parse(ApiConstants.attendanceMarkEndpoint);

      print("🔵 [API REQUEST] POST $url (Mark Attendance)");
      print("C: "+ courseId);
      print("S:" + sessionId);
      final request = http.MultipartRequest('POST', url);
      request.headers['Authorization'] = 'Bearer $token';
      request.fields['course_id'] = courseId;
      request.fields['session_id'] = sessionId.substring(0,sessionId.lastIndexOf('_'));

      final today = DateTime.now();
      final dateString = "${today.year.toString().padLeft(4, '0')}-"
          "${today.month.toString().padLeft(2, '0')}-"
          "${today.day.toString().padLeft(2, '0')}";
      request.fields['date'] = dateString;

      if (imageFile != null) {
        request.files.add(await http.MultipartFile.fromPath(
          'image',
          imageFile.path,
          contentType: MediaType('image', 'jpeg'),
        ));
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print("🟢 [API RESPONSE] Mark Status: ${response.statusCode}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        print("🔴 [SERVER ERROR BODY]: ${response.body}");
        final data = jsonDecode(response.body);
        _error = data['message'] ?? "Marking Attendance Failed";
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