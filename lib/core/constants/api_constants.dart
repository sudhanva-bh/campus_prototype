class ApiConstants {
  static const String baseUrl = "https://api.campus-in.com";
  
  // Auth
  static const String loginEndpoint = "$baseUrl/api/auth/login";
  static const String registerEndpoint = "$baseUrl/api/auth/register";
  static const String profileEndpoint = "$baseUrl/api/auth/profile";
  
  // System
  static const String healthEndpoint = "$baseUrl/health";
}