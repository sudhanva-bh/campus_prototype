class MicroSurvey {
  final String id;
  final String sessionId;
  final String type; // 'pre_session' or 'post_session'
  final List<SurveyQuestion> questions;

  MicroSurvey({
    required this.id,
    required this.sessionId,
    required this.type,
    required this.questions,
  });

  factory MicroSurvey.fromJson(Map<String, dynamic> json) {
    var qList = json['question_schema']?['questions'] as List? ?? [];
    
    return MicroSurvey(
      id: json['survey_id']?.toString() ?? '',
      sessionId: json['session_id']?.toString() ?? '',
      type: json['survey_type'] ?? 'pre_session',
      questions: qList.map((q) => SurveyQuestion.fromJson(q)).toList(),
    );
  }
}

class SurveyQuestion {
  final String id;
  final String type; // 'scale', 'text', 'choice'
  final String text;
  final int minScale;
  final int maxScale;
  final List<String> options;

  SurveyQuestion({
    required this.id,
    required this.type,
    required this.text,
    this.minScale = 1,
    this.maxScale = 5,
    this.options = const [],
  });

  factory SurveyQuestion.fromJson(Map<String, dynamic> json) {
    return SurveyQuestion(
      id: json['id']?.toString() ?? '',
      type: json['type'] ?? 'text',
      text: json['text'] ?? '',
      minScale: json['scale']?['min'] ?? 1,
      maxScale: json['scale']?['max'] ?? 5,
      options: List<String>.from(json['options'] ?? []),
    );
  }
}