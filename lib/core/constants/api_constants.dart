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
}
