/// API Constants for the NestJS backend
class ApiConstants {
 
  static const String baseUrl = 'http://10.72.57.118:3000';

  /// Python RAG / Gemini micro-service (Flask on port 6000)
  static const String chatbotBaseUrl = 'http://localhost:7001';
  
  // Auth endpoints
  static const String login = '/auth/login';
  static const String signup = '/auth/signup';
  static const String logout = '/auth/logout';
  static const String refresh = '/auth/refresh';
  static const String profile = '/auth/profile';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';
  static const String googleAuth = '/auth/google';
  
 
  static const String users = '/users';

  static const String properties = '/property';

  static const String nominatimBaseUrl = 'https://nominatim.openstreetmap.org';
  
  static String getGeocodingUrl(String address) {
    return '$nominatimBaseUrl/search?q=${Uri.encodeComponent(address)}&format=json&limit=1';
  }
  
  static String getReverseGeocodingUrl(double lat, double lng) {
    return '$nominatimBaseUrl/reverse?lat=$lat&lon=$lng&format=json';
  }
  
  static String getGoogleMapsUrl(double lat, double lng) {
    return 'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
  }
  
  static String getImageUrl(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) return '';
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return imagePath;
    }
    final filename = imagePath.split('/').last;
    return '$baseUrl/uploads/properties/images/$filename';
  }
  
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
