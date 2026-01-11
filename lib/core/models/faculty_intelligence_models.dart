// file: lib/core/models/faculty_intelligence_models.dart

class PacingRecommendation {
  final String action; // 'SPEED_UP', 'SLOW_DOWN', 'MAINTAIN'
  final String reasoning;
  final double unpreparedPercentage; // 0.0 - 1.0

  PacingRecommendation({
    required this.action,
    required this.reasoning,
    required this.unpreparedPercentage,
  });

  factory PacingRecommendation.fromJson(Map<String, dynamic> json) {
    return PacingRecommendation(
      action: json['action'] ?? 'MAINTAIN',
      reasoning: json['reasoning'] ?? 'Cohort appears ready.',
      unpreparedPercentage: (json['unprepared_percentage'] ?? 0.0).toDouble(),
    );
  }
}

class CohortInsight {
  final String metric; // e.g., "Top Confusion"
  final String value;  // e.g., "Recursion"
  final String trend;  // "rising", "falling"

  CohortInsight({required this.metric, required this.value, required this.trend});

  factory CohortInsight.fromJson(Map<String, dynamic> json) {
    return CohortInsight(
      metric: json['metric'] ?? '',
      value: json['value'] ?? '',
      trend: json['trend'] ?? 'stable',
    );
  }
}