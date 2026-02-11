/// API Constants for the NestJS backend
class ApiConstants {
 
  static const String baseUrl = 'http://10.64.158.95:3000';
  
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

  static const String properties = '/property';

  // OpenStreetMap Nominatim API (Free geocoding service)
  static const String nominatimBaseUrl = 'https://nominatim.openstreetmap.org';
  
  // Helper method to build geocoding URL (address -> coordinates)
  static String getGeocodingUrl(String address) {
    return '$nominatimBaseUrl/search?q=${Uri.encodeComponent(address)}&format=json&limit=1';
  }
  
  // Helper method to build reverse geocoding URL (coordinates -> address)
  static String getReverseGeocodingUrl(double lat, double lng) {
    return '$nominatimBaseUrl/reverse?lat=$lat&lon=$lng&format=json';
  }
  
  // Helper method to open location in Google Maps (external, no billing)
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
