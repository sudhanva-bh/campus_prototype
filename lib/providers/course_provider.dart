import 'dart:convert';
import 'package:campus_gemini_2/core/models/module_model.dart';
import 'package:campus_gemini_2/core/models/topic_model.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/api_constants.dart';
import '../core/models/course_model.dart';

class CourseProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<Course> _courses = [];
  bool _isLoading = false;
  String? _error;

  List<Course> get courses => _courses;
  bool get isLoading => _isLoading;
  String? get error => _error; // Cache for syllabus management

  List<Module> _currentModules = [];
  List<Module> get currentModules => _currentModules;

  // Map to store topics for each module: {moduleId: List<Topic>}
  Map<String, List<Topic>> _moduleTopics = {};

  // Helper to get headers
  Future<Map<String, String>> _getHeaders() async {
    final token = await _auth.currentUser?.getIdToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<bool> isAttendanceActive(String cid, String sid) async {
    try {
      final headers = await _getHeaders();
      Uri uri = Uri.parse(ApiConstants.attendanceActiveSessionEndpoint);
      DateTime date = DateTime.now();
      final dateStr =
          "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
      uri = uri.replace(queryParameters: {'date': dateStr, 'course_id': cid});

      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final Map<String, dynamic> data = jsonDecode(response.body);

        // 1. Check if "sessions" exists
        if (data['sessions'] != null && (data['sessions'] as List).isNotEmpty) {
          final List sessions = data['sessions'];
          for (var session in sessions) {
            if (session['session_id'].toString().startsWith(sid) &&
                session['status'] == 'active') {
              return true;
            }
          }
          return false;
        }
      }
      return false;
    } catch (e) {
      print("Error checking attendance status: $e");
      return false;
    }
  }

  Future<List<Map<String, String>?>?> identifyCurrentClass() async {
    try {
      final headers = await _getHeaders();
      // Construct URI with query parameter if date is provided
      DateTime date = DateTime.now();
      Uri uri = Uri.parse(ApiConstants.attendanceActiveSessionEndpoint);
      final dateStr =
          "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
      uri = uri.replace(queryParameters: {'date': dateStr});

      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final Map<String, dynamic> data = jsonDecode(response.body);

        // 1. Check if "sessions" exists and is not empty
        if (data['sessions'] != null && (data['sessions'] as List).isNotEmpty) {
          List<Map<String, String>> acList = [];
          if (data['sessions'] != null) {
            for (var session in data['sessions']) {
              if (session != null &&
                  session['course_id'] != null &&
                  session['session_id'] != null) {
                acList.add({
                  'courseId': session['course_id'],
                  'sessionId': session['session_id'],
                });
              }
            }
          }

          return acList;
        } else {
          print("No active sessions found in the list.");
        }
      }
    } catch (e) {
      debugPrint("Error fetching session IDs: $e");
    }
    return null;
  }

  // 1. Fetch All Courses (With Debug Prints)
  Future<void> fetchCourses() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final url = Uri.parse(ApiConstants.coursesEndpoint);
      final headers = await _getHeaders();

      final response = await http.get(url, headers: headers);

      print("🟢 [API RESPONSE] Status: ${response.statusCode}");
      print("🟢 [API RESPONSE] Body: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        final List<dynamic> list;

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
      print("🔴 [EXCEPTION] $e");
      print("🔴 [STACK TRACE] $stackTrace");
      _error = "Connection Error: $e";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

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

  // --- Phase 1: Module Management [cite: 2097, 2076] ---

  Future<void> fetchModulesForCourse(String courseId) async {
    _isLoading = true;
    notifyListeners();
    try {
      final url = Uri.parse(ApiConstants.courseModulesEndpoint(courseId));
      final headers = await _getHeaders();
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Handle response wrapper if present (e.g., {"modules": [...]})
        final List<dynamic> list = data['modules'] ?? [];
        _currentModules = list.map((e) => Module.fromJson(e)).toList();

        // Sort by sequence
        _currentModules.sort(
          (a, b) => a.sequenceOrder.compareTo(b.sequenceOrder),
        );
      } else {
        print("Error fetching modules: ${response.statusCode}");
      }
    } catch (e) {
      print("Exception fetching modules: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createModule(Module module) async {
    try {
      final url = Uri.parse(ApiConstants.modulesEndpoint);
      final headers = await _getHeaders();
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(module.toJson()),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        await fetchModulesForCourse(module.courseId); // Refresh list
        return true;
      }
      return false;
    } catch (e) {
      print("Error creating module: $e");
      return false;
    }
  }

  // --- Phase 1: Topic Management [cite: 2125, 2110] ---

  List<Topic> getTopicsForModule(String moduleId) {
    return _moduleTopics[moduleId] ?? [];
  }

  Future<void> fetchTopicsForModule(String moduleId) async {
    // Note: If you want to avoid loading individually, you could optimize to fetch all for course
    // But per API docs, endpoint is /modules/:id/topics
    try {
      final url = Uri.parse(ApiConstants.moduleTopicsEndpoint(moduleId));
      final headers = await _getHeaders();
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> list = data['topics'] ?? (data is List ? data : []);
        final topics = list.map((e) => Topic.fromJson(e)).toList();

        // Sort
        topics.sort((a, b) => a.sequenceOrder.compareTo(b.sequenceOrder));

        _moduleTopics[moduleId] = topics;
        notifyListeners();
      }
    } catch (e) {
      print("Exception fetching topics: $e");
    }
  }

  Future<bool> createTopic(Topic topic) async {
    try {
      final url = Uri.parse(ApiConstants.topicsEndpoint);
      final headers = await _getHeaders();
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(topic.toJson()),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        await fetchTopicsForModule(topic.moduleId); // Refresh specific module
        return true;
      }
      return false;
    } catch (e) {
      print("Error creating topic: $e");
      return false;
    }
  }
}
