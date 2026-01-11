class Topic {
  final String id;
  final String moduleId;
  final String name;
  final String description;
  final int sequenceOrder;
  final int estimatedDurationMinutes;
  final String difficultyLevel;
  final String bloomLevel;
  final List<String> skillsMapped;

  Topic({
    required this.id,
    required this.moduleId,
    required this.name,
    required this.description,
    required this.sequenceOrder,
    required this.estimatedDurationMinutes,
    required this.difficultyLevel,
    required this.bloomLevel,
    required this.skillsMapped,
  });

  factory Topic.fromJson(Map<String, dynamic> json) {
    return Topic(
      // [cite: 2113-2122]
      id: json['topic_id']?.toString() ?? '',
      moduleId: json['module_id']?.toString() ?? '',
      name: json['topic_name'] ?? '',
      description: json['topic_description'] ?? '',
      sequenceOrder: json['sequence_order'] ?? 0,
      estimatedDurationMinutes: json['estimated_duration_minutes'] ?? 60,
      difficultyLevel: json['difficulty_level'] ?? 'intermediate',
      bloomLevel: json['bloom_taxonomy_level'] ?? 'application',
      skillsMapped: List<String>.from(json['skills_mapped'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'module_id': moduleId,
      'topic_name': name,
      'topic_description': description,
      'sequence_order': sequenceOrder,
      'estimated_duration_minutes': estimatedDurationMinutes,
      'difficulty_level': difficultyLevel,
      'bloom_taxonomy_level': bloomLevel,
      'skills_mapped': skillsMapped,
    };
  }
}