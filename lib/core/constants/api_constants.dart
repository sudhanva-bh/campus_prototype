class ApiConstants {
  static const String baseUrl = "https://api.campus-in.com";
  
  // Auth
  static const String loginEndpoint = "$baseUrl/api/auth/login";
  static const String registerEndpoint = "$baseUrl/api/auth/register";
  static const String profileEndpoint = "$baseUrl/api/auth/profile";
  
  // System
  static const String healthEndpoint = "$baseUrl/health";

  // Courses
  static const String coursesEndpoint = "$baseUrl/api/courses";
  static String courseDetailEndpoint(String id) => "$baseUrl/api/courses/$id";
  static String enrollEndpoint(String id) => "$baseUrl/api/courses/$id/enroll";

  // Modules & Topics (Phase 1)
  static const String modulesEndpoint = "$baseUrl/modules"; 
  static String courseModulesEndpoint(String courseId) => "$baseUrl/courses/$courseId/modules";
  static const String topicsEndpoint = "$baseUrl/topics";
  static String moduleTopicsEndpoint(String moduleId) => "$baseUrl/modules/$moduleId/topics";

  // --- SCMS Phase 2: Micro-Surveys ---
  static const String surveysEndpoint = "$baseUrl/api/scms/surveys";
  
  // Submit Response [cite: 157-158]
  static String surveyResponseEndpoint(String surveyId) => 
      "$baseUrl/api/scms/surveys/$surveyId/responses";
      
  // Helper to fetch active survey for a session (inferred from system logic)
  static String sessionActiveSurveyEndpoint(String sessionId) => 
      "$baseUrl/api/scms/sessions/$sessionId/active-survey";

  // Schedule
  static const String sessionsEndpoint = "$baseUrl/api/schedule/sessions";
  static const String generateTimetableEndpoint = "$baseUrl/api/schedule/timetable";

  // Attendance
  static const String attendanceVerifyEndpoint = "$baseUrl/api/attendance/verify";
  static const String attendanceStartSessionEndpoint =  "$baseUrl/api/attendance/sessions/start";
  static const String attendanceActiveSessionEndpoint =  "$baseUrl/api/attendance/sessions/active";
  static const String attendanceMarkEndpoint = "$baseUrl/api/attendance/mark";
  static const String attendanceVerifyFaceEndpoint ="$baseUrl/api/attendance/verify-face";

  static String closeSessionUrl(String sid){
    return "$baseUrl/api/attendance/sessions/$sid/close";
  }
  
  // --- SCMS Phase 3: Analytics & Intelligence ---

  // Topic Mastery [cite: 105]
  static String topicMasteryEndpoint(String studentId) => 
      "$baseUrl/api/scms/students/$studentId/topic-mastery";

  // Learning Curve [cite: 294]
  static String learningCurveEndpoint(String studentId, String topicId) => 
      "$baseUrl/api/scms/students/$studentId/topics/$topicId/learning-curve";

  // Fatigue & Wellness [cite: 253, 268]
  static String fatigueEndpoint(String studentId) => 
      "$baseUrl/api/scms/students/$studentId/fatigue";
  
  static String overloadEndpoint(String studentId) => 
      "$baseUrl/api/scms/students/$studentId/overload";
}
