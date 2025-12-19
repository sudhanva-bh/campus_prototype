class Course {
  final String id;
  final String code;
  final String name;
  final String description;
  final int credits;
  final String instructorId;
  final List<String> schedule; 
  final List<String> enrolledStudents;

  Course({
    required this.id,
    required this.code,
    required this.name,
    required this.description,
    required this.credits,
    required this.instructorId,
    required this.schedule,
    required this.enrolledStudents,
  });

  factory Course.fromJson(Map<String, dynamic> json) {
    // Helper to safely get the first instructor from the list if present
    String getInstructor(dynamic facultyIds) {
      if (facultyIds is List && facultyIds.isNotEmpty) {
        return facultyIds.first.toString();
      }
      return '';
    }

    return Course(
      // FIX: Map 'course_id' from API to 'id' in model
      id: json['course_id'] ?? json['id'] ?? '',
      
      code: json['code'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      credits: json['credits'] ?? 0,
      
      // FIX: Map 'faculty_ids' list to single ID string
      instructorId: getInstructor(json['faculty_ids']),
      
      // FIX: Handle missing schedule
      schedule: List<String>.from(json['schedule'] ?? []),
      
      // FIX: Map 'enrolled_student_ids' to 'enrolledStudents'
      enrolledStudents: List<String>.from(json['enrolled_student_ids'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'name': name,
      'description': description,
      'credits': credits,
      'schedule': schedule,
    };
  }
}