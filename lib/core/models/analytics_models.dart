// 1. Topic Mastery Model [cite: 110-122]
class TopicMastery {
  final String topicId;
  final double currentScore; // 0-100
  final double confidenceInterval;
  final String trend; // 'improving', 'stable', 'declining'
  final List<String> contributingAssessments;

  TopicMastery({
    required this.topicId,
    required this.currentScore,
    required this.confidenceInterval,
    required this.trend,
    required this.contributingAssessments,
  });

  factory TopicMastery.fromJson(Map<String, dynamic> json) {
    return TopicMastery(
      topicId: json['topic_id'] ?? '',
      currentScore: (json['current_mastery_score'] ?? 0).toDouble(),
      confidenceInterval: (json['confidence_interval'] ?? 0).toDouble(),
      trend: json['trend'] ?? 'stable',
      contributingAssessments: List<String>.from(json['contributing_assessments'] ?? []),
    );
  }
}

// 2. Wellness/Fatigue Model [cite: 258-262, 271-278]
class StudentWellness {
  final double fatigueScore; // 0.0 - 1.0
  final String interpretation; // 'well_rested', 'moderate_fatigue', etc.
  final bool isOverloaded;
  final String? recommendation;

  StudentWellness({
    required this.fatigueScore,
    required this.interpretation,
    required this.isOverloaded,
    this.recommendation,
  });

  factory StudentWellness.fromJsons(Map<String, dynamic> fatigueJson, Map<String, dynamic> overloadJson) {
    return StudentWellness(
      fatigueScore: (fatigueJson['fatigue_score'] ?? 0.0).toDouble(),
      interpretation: fatigueJson['interpretation'] ?? 'unknown',
      isOverloaded: overloadJson['overload']?['isOverloaded'] ?? false,
      recommendation: overloadJson['overload']?['recommendation'],
    );
  }
}

// 3. Learning Curve Model [cite: 297-304]
class LearningCurvePoint {
  final DateTime date;
  final double mastery;

  LearningCurvePoint({required this.date, required this.mastery});

  factory LearningCurvePoint.fromJson(Map<String, dynamic> json) {
    return LearningCurvePoint(
      date: DateTime.parse(json['date']),
      mastery: (json['mastery'] ?? 0).toDouble(),
    );
  }
}