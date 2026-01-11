class Module {
  final String id;
  final String courseId;
  final String name;
  final String description;
  final int sequenceOrder;
  final int estimatedHours;
  final List<String> skillsMapped;

  Module({
    required this.id,
    required this.courseId,
    required this.name,
    required this.description,
    required this.sequenceOrder,
    required this.estimatedHours,
    required this.skillsMapped,
  });

  factory Module.fromJson(Map<String, dynamic> json) {
    return Module(
      // [cite: 2091, 2106]
      id: json['module_id']?.toString() ?? '', 
      courseId: json['course_id']?.toString() ?? '',
      name: json['module_name'] ?? '',
      description: json['module_description'] ?? '',
      sequenceOrder: json['sequence_order'] ?? 0,
      estimatedHours: json['estimated_hours'] ?? 0,
      skillsMapped: List<String>.from(json['skills_mapped'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'course_id': courseId,
      'module_name': name,
      'module_description': description,
      'sequence_order': sequenceOrder,
      'estimated_hours': estimatedHours,
      'skills_mapped': skillsMapped,
    };
  }
}