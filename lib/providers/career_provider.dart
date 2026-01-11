import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import '../core/constants/api_constants.dart';

class CareerProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isLoading = false;
  String _selectedGoal = "Data Scientist";
  bool _isSurveyCompleted = false;

  // --- REAL DATA STATE ---
  List<Map<String, dynamic>> _activeRecommendations = [];
  List<Map<String, dynamic>> _skillGaps = [];
  Map<String, dynamic> _forecastData = {};
  Map<String, dynamic>? _lastSimulationReport;

  // --- GETTERS ---
  bool get isLoading => _isLoading;
  String get selectedGoal => _selectedGoal;
  bool get isSurveyCompleted => _isSurveyCompleted;

  List<Map<String, dynamic>> get currentRecommendations => _activeRecommendations;
  List<Map<String, dynamic>> get currentSkillGaps => _skillGaps;
  Map<String, dynamic> get currentForecast => _forecastData;
  Map<String, dynamic>? get lastSimulationReport => _lastSimulationReport;
  
  // Keep comparison data mock for now (or replace if you have an endpoint)
  Map<String, dynamic> get comparisonData => _mockComparisonToolOutput;

  // Static content resources (can be moved to API later)
  List<Map<String, dynamic>> get currentResources => _mockResources;

  CareerProvider() {
    // Optionally auto-fetch on init if user is logged in
    // fetchRecommendations();
  }

  // --- API HELPER ---
  Future<Map<String, String>> _getHeaders() async {
    final token = await _auth.currentUser?.getIdToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // --- ACTIONS ---

  void setGoal(String newGoal) async {
    _selectedGoal = newGoal;
    await fetchRecommendations(); // Fetch fresh data for the new goal
  }

  void submitSurvey(int confidenceScore) {
    _isSurveyCompleted = true;
    notifyListeners();
  }

  // PHASE 5: FEEDBACK LOOP (Local update + API sync could be added here)
  void submitFeedback(String recId, int type) {
    final index = _activeRecommendations.indexWhere((r) => r['id'] == recId);
    if (index != -1) {
      _activeRecommendations[index]['user_feedback'] = type;
      notifyListeners();
      // TODO: Call API to persist feedback
    }
  }

  // --- API METHODS ---

  // 1. Fetch Skill Inventory & Gaps
  Future<void> fetchSkillInventory() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    try {
      final url = Uri.parse(ApiConstants.skillInventoryEndpoint(uid));
      final response = await http.get(url, headers: await _getHeaders());

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Expecting { "skills": [...] }
        _skillGaps = List<Map<String, dynamic>>.from(data['skills'] ?? []);
        notifyListeners();
      }
    } catch (e) {
      print("Error fetching skills: $e");
    }
  }

  // 2. Fetch Career Recommendations
  Future<void> fetchRecommendations() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      // 1. Fetch Recommendations
      final urlRecs = Uri.parse(ApiConstants.careerRecommendationsEndpoint(uid));
      final response = await http.get(urlRecs, headers: await _getHeaders());

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Parse recommendations
        _activeRecommendations = List<Map<String, dynamic>>.from(
          data['recommendations'] ?? []
        );

        // Parse forecast if included in the same response
        if (data['forecast'] != null) {
          _forecastData = data['forecast'];
        }
      }

      // 2. Fetch Skill Gaps (Parallel or Sequential)
      await fetchSkillInventory();

    } catch (e) {
      print("Error fetching career data: $e");
      // Fallback to empty or error state handling
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 3. Simulation Engine (Hybrid: API with Local Fallback)
  Future<void> simulateEvent(String eventType) async {
    _isLoading = true;
    notifyListeners();

    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      _isLoading = false;
      return;
    }

    try {
      final url = Uri.parse(ApiConstants.careerSimulationEndpoint(uid));
      final body = {
        'event_type': eventType,
        'current_goal': _selectedGoal,
      };

      final response = await http.post(
        url,
        headers: await _getHeaders(),
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        _lastSimulationReport = jsonDecode(response.body);
        // Refresh main data to reflect the simulation's impact
        await fetchRecommendations();
      } else {
        throw Exception("Simulation API failed");
      }
    } catch (e) {
      print("Simulation API error: $e. Using local fallback.");
      _runLocalSimulationFallback(eventType);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- LOCAL FALLBACK LOGIC (For Demo Stability) ---
  void _runLocalSimulationFallback(String eventType) {
    if (_activeRecommendations.isNotEmpty) {
       // Deep copy the first recommendation to modify it
       var topRec = Map<String, dynamic>.from(_activeRecommendations[0]);
       
       double confidenceDelta = 0.0;
       String decision = "MAINTAIN";
       String rationale = "Simulated local impact due to connection error.";

       switch (eventType) {
        case "exam_fail":
          confidenceDelta = -0.15;
          decision = "ADJUST";
          rationale = "Recent academic slip detected. Confidence lowered locally.";
          break;
        case "internship_offer":
          confidenceDelta = 0.12;
          decision = "REINFORCE";
          rationale = "Internship verified. Confidence boosted locally.";
          break;
        case "market_crash":
          confidenceDelta = -0.20;
          decision = "REDIRECT";
          rationale = "Market instability detected. Viability score penalized.";
          break;
      }

       // Update State
      double oldConf = topRec['confidence'] is double 
          ? topRec['confidence'] 
          : double.tryParse(topRec['confidence'].toString()) ?? 0.5;
          
      double newConf = (oldConf + confidenceDelta).clamp(0.0, 1.0);
      topRec['confidence'] = newConf;

      // Update the list with the modified recommendation
      _activeRecommendations[0] = topRec;

       _lastSimulationReport = {
        "event": eventType,
        "decision": decision,
        "rationale": rationale,
        "old_confidence": oldConf,
        "new_confidence": newConf,
        "rec_title": topRec['title'],
      };
    }
  }

  // --- STATIC RESOURCES (Content) ---
  final List<Map<String, dynamic>> _mockResources = [
    {
      "type": "Course",
      "title": "Math for ML: Linear Algebra",
      "tag": "Critical Gap",
      "time": "6 weeks",
      "color": Colors.redAccent,
    },
    {
      "type": "Project",
      "title": "Build a Sentiment Analysis API",
      "tag": "Portfolio Builder",
      "time": "2 weeks",
      "color": Colors.blueAccent,
    },
    {
      "type": "Mentor",
      "title": "Sarah Chen (Senior DS)",
      "tag": "Industry Insight",
      "time": "30 min",
      "color": Colors.purpleAccent,
    },
  ];

  final Map<String, dynamic> _mockComparisonToolOutput = {
    "skill_alignment": {"a": 0.78, "b": 0.65},
    "market_viability": {"a": 0.85, "b": 0.72},
    "time_to_readiness": {"a": "8 months", "b": "6 months"},
    "pros_cons": {
      "career_a": {"pros": ["High Demand"], "cons": ["High Barrier"]},
      "career_b": {"pros": ["Faster Entry"], "cons": ["Lower Ceiling"]},
    },
  };
}