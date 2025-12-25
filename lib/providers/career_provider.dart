import 'package:flutter/material.dart';

class CareerProvider extends ChangeNotifier {
  bool _isLoading = false;
  String _selectedGoal = "Data Scientist";
  bool _isSurveyCompleted = false;

  bool get isLoading => _isLoading;
  String get selectedGoal => _selectedGoal;
  bool get isSurveyCompleted => _isSurveyCompleted;

  // --- STATE FOR PHASE 5 (Mutable Data) ---
  // We make the list mutable to simulate changes
  List<Map<String, dynamic>> _activeRecommendations = [];
  Map<String, dynamic>? _lastSimulationReport;

  CareerProvider() {
    _resetRecommendations();
  }

  void _resetRecommendations() {
    // Deep copy of initial mock data
    _activeRecommendations = List.from(
      _initialMockRecommendations[_selectedGoal]!.map(
        (e) => Map<String, dynamic>.from(e),
      ),
    );
  }

  // --- MOCK DATA SOURCE (Static) ---
  final Map<String, List<Map<String, dynamic>>> _initialMockRecommendations = {
    "Data Scientist": [
      {
        "id": "rec_67890",
        "title": "Data Scientist",
        "confidence": 0.82,
        "match_level": "High",
        "factors": [
          "Strong performance in ML",
          "High Python engagement",
          "Market growth",
        ],
        "ai_explanation": "Fits well due to ML scores (90th percentile).",
        "skill_gap": 0.22,
        "market_viability": 0.85,
        "user_feedback": 0, // 0: none, 1: like, -1: dislike
      },
      {
        "id": "rec_67891",
        "title": "Machine Learning Engineer",
        "confidence": 0.74,
        "match_level": "High",
        "factors": ["Solid algo foundation", "Pending: Deployment skills"],
        "ai_explanation":
            "Algorithmic foundation is strong, but needs deployment skills.",
        "skill_gap": 0.35,
        "market_viability": 0.90,
        "user_feedback": 0,
      },
    ],
    "Product Manager": [
      {
        "id": "rec_99887",
        "title": "Product Manager",
        "confidence": 0.63,
        "match_level": "Medium",
        "factors": ["Problem-solving skills", "Gap: Business Strategy"],
        "ai_explanation":
            "Pivot possible, but critical business strategy gaps exist.",
        "skill_gap": 0.45,
        "market_viability": 0.80,
        "user_feedback": 0,
      },
    ],
  };

  // --- PHASE 3 & 4 GETTERS ---
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

  final Map<String, Map<String, dynamic>> _mockForecasts = {
    "Data Scientist": {
      "short_term": {
        "best_case": "Junior DS @ Tier-1",
        "likely_case": "Data Analyst",
        "risk_case": "Delayed placement",
        "prob_best": 0.68,
        "prob_likely": 0.85,
      },
    },
    "Product Manager": {
      "short_term": {
        "best_case": "APM Program",
        "likely_case": "Product Analyst",
        "risk_case": "Project Coordinator",
        "prob_best": 0.55,
        "prob_likely": 0.80,
      },
    },
  };

  final Map<String, List<Map<String, dynamic>>> _mockSkillGaps = {
    "Data Scientist": [
      {"skill": "Deep Learning", "type": "High Impact", "progress": 0.4},
      {"skill": "Cloud (AWS)", "type": "Critical", "progress": 0.1},
    ],
    "Product Manager": [
      {"skill": "Agile", "type": "Critical", "progress": 0.2},
      {"skill": "User Research", "type": "High Impact", "progress": 0.5},
    ],
  };

  final Map<String, dynamic> _mockComparisonToolOutput = {
    "skill_alignment": {"a": 0.78, "b": 0.65},
    "market_viability": {"a": 0.85, "b": 0.72},
    "time_to_readiness": {"a": "8 months", "b": "6 months"},
    "pros_cons": {
      "career_a": {
        "pros": ["High Demand"],
        "cons": ["High Barrier"],
      },
      "career_b": {
        "pros": ["Faster Entry"],
        "cons": ["Lower Ceiling"],
      },
    },
  };

  // --- ACTIVE GETTERS ---
  List<Map<String, dynamic>> get currentRecommendations =>
      _activeRecommendations;
  List<Map<String, dynamic>> get currentResources => _mockResources;
  Map<String, dynamic> get currentForecast =>
      _mockForecasts[_selectedGoal] ?? _mockForecasts["Data Scientist"]!;
  List<Map<String, dynamic>> get currentSkillGaps =>
      _mockSkillGaps[_selectedGoal] ?? [];
  Map<String, dynamic> get comparisonData => _mockComparisonToolOutput;
  Map<String, dynamic>? get lastSimulationReport => _lastSimulationReport;

  // --- ACTIONS ---

  void setGoal(String newGoal) async {
    _isLoading = true;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 800));
    _selectedGoal = newGoal;
    _resetRecommendations();
    _isLoading = false;
    notifyListeners();
  }

  void submitSurvey(int confidenceScore) async {
    _isSurveyCompleted = true;
    notifyListeners();
  }

  // PHASE 5: FEEDBACK LOOP
  void submitFeedback(String recId, int type) {
    // type: 1 = like, -1 = dislike
    final index = _activeRecommendations.indexWhere((r) => r['id'] == recId);
    if (index != -1) {
      _activeRecommendations[index]['user_feedback'] = type;
      notifyListeners();
    }
  }

  // PHASE 5: SIMULATION ENGINE
  Future<void> simulateEvent(String eventType) async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(seconds: 1)); // Process simulation

    // Mock Logic for Event Impact
    double confidenceDelta = 0.0;
    String decision = "MAINTAIN";
    String rationale = "";

    // Apply logic to the first recommendation for demo purposes
    if (_activeRecommendations.isNotEmpty) {
      var topRec = _activeRecommendations[0];

      switch (eventType) {
        case "exam_fail":
          confidenceDelta = -0.15;
          decision = "ADJUST";
          rationale =
              "Recent academic slip in core math module detected. Confidence lowered. Remedial action suggested.";
          topRec['factors'].insert(0, "Alert: Recent Math Grade Drop");
          break;
        case "internship_offer":
          confidenceDelta = 0.12;
          decision = "REINFORCE";
          rationale =
              "Verified industry offer received. Pathway validation complete. Confidence boosted.";
          topRec['factors'].insert(0, "Success: Internship Secured");
          break;
        case "market_crash":
          confidenceDelta = -0.20;
          decision = "REDIRECT";
          rationale =
              "Sector instability detected (30% drop in hiring). Market viability score penalized.";
          topRec['market_viability'] =
              (topRec['market_viability'] as double) - 0.3;
          break;
      }

      // Update State
      double oldConf = topRec['confidence'];
      double newConf = (oldConf + confidenceDelta).clamp(0.0, 1.0);
      topRec['confidence'] = newConf;

      // Generate Report Data
      _lastSimulationReport = {
        "event": eventType,
        "decision": decision,
        "rationale": rationale,
        "old_confidence": oldConf,
        "new_confidence": newConf,
        "rec_title": topRec['title'],
      };
    }

    _isLoading = false;
    notifyListeners();
  }
}
