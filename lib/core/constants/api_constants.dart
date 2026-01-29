/// API Constants for the NestJS backend
class ApiConstants {
 
  static const String baseUrl = 'http://10.62.231.95:3000';
  
  // Auth endpoints
  static const String login = '/auth/login';
  static const String signup = '/auth/signup';
  static const String logout = '/auth/logout';
  static const String refresh = '/auth/refresh';
  static const String profile = '/auth/profile';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';
  static const String googleAuth = '/auth/google';
  
  // User endpoints
  static const String users = '/users';
  // OCR: POST /users/{userId}/scan-id-card (requires auth)
  
  // Headers
  static Map<String, String> get headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
  
  static Map<String, String> authHeaders(String token) => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'Authorization': 'Bearer $token',
  };
}
