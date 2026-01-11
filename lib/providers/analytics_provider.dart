import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import '../core/constants/api_constants.dart';
import '../core/models/analytics_models.dart';

class AnalyticsProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // Data Stores
  List<TopicMastery> _topicMasteryList = [];
  StudentWellness? _wellness;
  List<LearningCurvePoint> _learningCurve = [];

  List<TopicMastery> get topicMasteryList => _topicMasteryList;
  StudentWellness? get wellness => _wellness;
  List<LearningCurvePoint> get learningCurve => _learningCurve;

  Future<Map<String, String>> _getHeaders() async {
    final token = await _auth.currentUser?.getIdToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // 1. Fetch Topic Mastery [cite: 105]
  Future<void> fetchTopicMastery() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      final url = Uri.parse(ApiConstants.topicMasteryEndpoint(uid));
      final response = await http.get(url, headers: await _getHeaders());

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // API returns { "mastery": { ... } } for single or list for all. 
        // Assuming list based on "returns all topics" description.
        // If the API wraps it in a "topics" key, adjust accordingly.
        final List<dynamic> list = data['topics'] ?? []; 
        _topicMasteryList = list.map((e) => TopicMastery.fromJson(e)).toList();
      }
    } catch (e) {
      print("Error fetching mastery: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 2. Fetch Wellness (Fatigue + Overload) [cite: 253, 268]
  Future<void> fetchWellness() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    try {
      final headers = await _getHeaders();
      
      // Fetch Fatigue
      final fatigueRes = await http.get(
        Uri.parse(ApiConstants.fatigueEndpoint(uid)), 
        headers: headers
      );
      
      // Fetch Overload
      final overloadRes = await http.get(
        Uri.parse(ApiConstants.overloadEndpoint(uid)), 
        headers: headers
      );

      if (fatigueRes.statusCode == 200 && overloadRes.statusCode == 200) {
        final fatigueData = jsonDecode(fatigueRes.body);
        final overloadData = jsonDecode(overloadRes.body);
        
        _wellness = StudentWellness.fromJsons(fatigueData, overloadData);
        notifyListeners(); // Notify specifically for widget update
      }
    } catch (e) {
      print("Error fetching wellness: $e");
    }
  }

  // 3. Fetch Learning Curve for a Topic [cite: 294]
  Future<void> fetchLearningCurve(String topicId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    try {
      final url = Uri.parse(ApiConstants.learningCurveEndpoint(uid, topicId));
      final response = await http.get(url, headers: await _getHeaders());

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final curveData = data['learning_curve']?['data_points'] as List? ?? [];
        _learningCurve = curveData.map((e) => LearningCurvePoint.fromJson(e)).toList();
        notifyListeners();
      }
    } catch (e) {
      print("Error fetching learning curve: $e");
    }
  }
}