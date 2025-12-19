import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import '../core/constants/api_constants.dart';
import '../core/models/session_model.dart';

class ScheduleProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<ClassSession> _sessionRules = []; // Raw rules from API
  bool _isLoading = false;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<Map<String, String>> _getHeaders() async {
    final token = await _auth.currentUser?.getIdToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // 1. Fetch Sessions (Stores Rules)
  Future<void> fetchSessions() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print("🔵 [API REQUEST] GET ${ApiConstants.sessionsEndpoint}");
      final response = await http.get(
        Uri.parse(ApiConstants.sessionsEndpoint),
        headers: await _getHeaders(),
      );

      print("🟢 [API RESPONSE] Status: ${response.statusCode}");
      print("🟢 [API RESPONSE] Body: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> list = data['sessions'] ?? data['data'] ?? [];
        
        _sessionRules = list.map((e) => ClassSession.fromJson(e)).toList();
      } else {
        _error = "Failed to load schedule";
      }
    } catch (e) {
      print("🔴 [EXCEPTION] Fetch Sessions: $e");
      _error = "Connection error";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 2. Get Sessions for Specific Date (Generates Instances)
  List<ClassSession> getSessionsForDate(DateTime date) {
    List<ClassSession> dailySessions = [];

    // Check every rule to see if it applies to this date
    for (var rule in _sessionRules) {
      final instance = rule.resolveForDate(date);
      if (instance != null) {
        dailySessions.add(instance);
      }
    }

    // Sort by time
    dailySessions.sort((a, b) {
      if (a.activeStartTime == null || b.activeStartTime == null) return 0;
      return a.activeStartTime!.compareTo(b.activeStartTime!);
    });

    return dailySessions;
  }

  // 3. Create Session
  Future<bool> createSession(Map<String, dynamic> sessionData) async {
    try {
      print("🔵 [API REQUEST] POST ${ApiConstants.sessionsEndpoint}");
      final response = await http.post(
        Uri.parse(ApiConstants.sessionsEndpoint),
        headers: await _getHeaders(),
        body: jsonEncode(sessionData),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        await fetchSessions(); 
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // 4. Generate Timetable
  Future<bool> generateTimetable() async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.generateTimetableEndpoint),
        headers: await _getHeaders(),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        await fetchSessions();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}