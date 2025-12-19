import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import '../core/constants/api_constants.dart';
import '../core/models/course_model.dart';

class CourseProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<Course> _courses = [];
  bool _isLoading = false;
  String? _error;

  List<Course> get courses => _courses;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Helper to get headers
  Future<Map<String, String>> _getHeaders() async {
    final token = await _auth.currentUser?.getIdToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // 1. Fetch All Courses (With Debug Prints)
  Future<void> fetchCourses() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final url = Uri.parse(ApiConstants.coursesEndpoint);
      final headers = await _getHeaders();

      // --- DEBUG PRINT START ---
      print("🔵 [API REQUEST] GET $url");
      print("🔵 [HEADERS] $headers");
      // --- DEBUG PRINT END ---

      final response = await http.get(url, headers: headers);

      // --- DEBUG PRINT START ---
      print("🟢 [API RESPONSE] Status: ${response.statusCode}");
      print("🟢 [API RESPONSE] Body: ${response.body}");
      // --- DEBUG PRINT END ---

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        final List<dynamic> list;

        // FIX: Check for 'courses' key specifically as seen in logs
        if (data is Map && data.containsKey('courses')) {
          list = data['courses'];
        } else if (data is Map && data.containsKey('data')) {
          list = data['data'];
        } else if (data is List) {
          list = data;
        } else {
          print("⚠️ [API PARSING] Unexpected JSON structure: $data");
          list = [];
        }

        _courses = list.map((e) => Course.fromJson(e)).toList();
      } else {
        _error = "Failed to load courses (Status: ${response.statusCode})";
        print("🔴 [API ERROR] $_error");
      }
    } catch (e, stackTrace) {
      // Catch detailed error information
      print("🔴 [EXCEPTION] $e");
      print("🔴 [STACK TRACE] $stackTrace");
      _error = "Connection Error: $e";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ... (Keep existing createCourse, updateCourse, enrollStudent methods)
  // Ensure you add similar print statements to those if they fail too.

  // 2. Create Course
  Future<bool> createCourse(Map<String, dynamic> courseData) async {
    try {
      print("🔵 [API REQUEST] POST ${ApiConstants.coursesEndpoint}");
      print("🔵 [BODY] $courseData");

      final response = await http.post(
        Uri.parse(ApiConstants.coursesEndpoint),
        headers: await _getHeaders(),
        body: jsonEncode(courseData),
      );

      print("🟢 [API RESPONSE] Status: ${response.statusCode}");

      if (response.statusCode == 201) {
        await fetchCourses();
        return true;
      }
      return false;
    } catch (e) {
      print("🔴 [EXCEPTION] $e");
      return false;
    }
  }

  // 3. Update Course
  Future<bool> updateCourse(String id, Map<String, dynamic> updates) async {
    try {
      final response = await http.put(
        Uri.parse(ApiConstants.courseDetailEndpoint(id)),
        headers: await _getHeaders(),
        body: jsonEncode(updates),
      );

      if (response.statusCode == 200) {
        await fetchCourses();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // 4. Enroll Student (Admin)
  Future<bool> enrollStudent(String courseId, String studentId) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.enrollEndpoint(courseId)),
        headers: await _getHeaders(),
        body: jsonEncode({'student_id': studentId}),
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
