import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import '../core/constants/api_constants.dart';
import '../core/models/micro_survey_model.dart';

class SurveyProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = false;

  bool get isLoading => _isLoading;

  Future<Map<String, String>> _getHeaders() async {
    final token = await _auth.currentUser?.getIdToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // Check if a session has an active survey (Pre or Post)
  Future<MicroSurvey?> fetchActiveSurveyForSession(String sessionId) async {
    _isLoading = true;
    notifyListeners();
    try {
      // Endpoint logic: Backend determines if a survey is open based on time
      final url = Uri.parse(ApiConstants.sessionActiveSurveyEndpoint(sessionId));
      final headers = await _getHeaders();
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data != null && data['survey_id'] != null) {
           return MicroSurvey.fromJson(data);
        }
      }
    } catch (e) {
      print("Error fetching active survey: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return null;
  }

  // Submit responses [cite: 160-168]
  Future<bool> submitSurveyResponse(String surveyId, Map<String, dynamic> responses) async {
    _isLoading = true;
    notifyListeners();
    try {
      final url = Uri.parse(ApiConstants.surveyResponseEndpoint(surveyId));
      final headers = await _getHeaders();
      
      final body = {
        'student_id': _auth.currentUser?.uid, // Typically handled by backend from Token, but adding for safety
        'response_data': responses,
        'submitted_at': DateTime.now().toIso8601String(),
      };

      print("Submitting Survey: $body");

      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(body),
      );

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print("Error submitting survey: $e");
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}