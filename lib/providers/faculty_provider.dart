// file: lib/providers/faculty_provider.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import '../core/constants/api_constants.dart';
import '../core/models/faculty_intelligence_models.dart';

class FacultyProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = false;

  // Cache for the active session's intelligence
  PacingRecommendation? _currentPacing;
  List<CohortInsight> _currentInsights = [];

  bool get isLoading => _isLoading;
  PacingRecommendation? get currentPacing => _currentPacing;
  List<CohortInsight> get currentInsights => _currentInsights;

  Future<Map<String, String>> _getHeaders() async {
    final token = await _auth.currentUser?.getIdToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // 1. Fetch Pre-Class Pacing
  Future<void> fetchPacing(String sessionId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final url = Uri.parse(ApiConstants.pacingRecommendation(sessionId));
      final response = await http.get(url, headers: await _getHeaders());

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _currentPacing = PacingRecommendation.fromJson(data);
      } else {
        // Fallback Mock for Demo if API isn't live yet
        _currentPacing = PacingRecommendation(
          action: "SLOW_DOWN",
          reasoning: "35% of cohort failed the 'Binary Trees' prerequisite quiz.",
          unpreparedPercentage: 0.35,
        );
      }
    } catch (e) {
      print("Error fetching pacing: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 2. Fetch Post-Class Insights
  Future<void> fetchSessionInsights(String sessionId) async {
    _isLoading = true;
    notifyListeners();
    
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 500));

    try {
      final url = Uri.parse(ApiConstants.postSessionInsights(sessionId));
      final response = await http.get(url, headers: await _getHeaders());

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final list = data['insights'] as List? ?? [];
        _currentInsights = list.map((e) => CohortInsight.fromJson(e)).toList();
      } else {
         // Fallback Mock
        _currentInsights = [
          CohortInsight(metric: "Avg. Grasping", value: "3.8/5", trend: "stable"),
          CohortInsight(metric: "Top Confusion", value: "Memory Allocation", trend: "rising"),
          CohortInsight(metric: "Attendance", value: "92%", trend: "falling"),
        ];
      }
    } catch (e) {
      print("Error fetching insights: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  void clearData() {
    _currentPacing = null;
    _currentInsights = [];
    notifyListeners();
  }
}