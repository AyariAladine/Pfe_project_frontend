/// API Constants for the NestJS backend
class ApiConstants {
 
  static const String baseUrl = 'http://10.143.72.118:3000';

  static const String chatbotBaseUrl = 'http://10.100.21.118:7001';

  /// Face recognition API
  static const String faceRecognitionBaseUrl = 'http://10.100.21.118:8000';

  /// Lawyer verification scraper service
  static const String scraperBaseUrl = 'http://10.100.21.118:7002';
  static const String verifyLawyerUrl = '$scraperBaseUrl/verify-lawyer';
  
  // Auth endpoints
  static const String login = '/auth/login';
  static const String signup = '/auth/signup';
  static const String logout = '/auth/logout';
  static const String refresh = '/auth/refresh';
  static const String profile = '/auth/profile';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';
  static const String googleAuth = '/auth/google';

  // SMS OTP endpoints
  static const String sendOtp = '/auth/send-otp';
  static const String verifyOtp = '/auth/verify-otp';
  
 
  static const String users = '/users';
  static String userProfile(String id) => '/users/$id/profile';
  static String userSignature(String id) => '/users/$id/signature';
  static String scanIdCard(String id) => '/users/$id/scan-id-card';
  static String verification(String id) => '/users/$id/verification';
  static String verificationFrontConfirm(String id) =>
      '/users/$id/verification/front-confirm';
  static String verificationBackConfirm(String id) =>
      '/users/$id/verification/back-confirm';
  static String verificationFinalize(String id) =>
      '/users/$id/verification/finalize';

  // Lawyers endpoints
  static const String lawyers = '/lawyers';
  static String lawyerById(String id) => '/lawyers/$id';
  static String lawyerProfile(String id) => '/lawyers/$id/profile';
  static String lawyerVerify(String id) => '/lawyers/$id/verify';
  static String lawyerSignature(String id) => '/lawyers/$id/signature';

  static const String properties = '/property';

  // Application (postulation) endpoints
  static const String applications = '/applications';
  static const String myApplications = '/applications/my';
  static const String incomingApplications = '/applications/incoming';
  static String propertyApplications(String propertyId) =>
      '/applications/property/$propertyId';
  static String applicationById(String id) => '/applications/$id';
  static String applicationStatus(String id) => '/applications/$id/status';
  static String applicationCancel(String id) => '/applications/$id/cancel';
  static String applicationMessages(String id) => '/applications/$id/messages';
  static String applicationSetAmount(String id) => '/applications/$id/set-amount';
  static String applicationAssignLawyer(String id) => '/applications/$id/assign-lawyer';

  // Contract endpoints
  static const String contracts = '/contracts';
  static const String myContracts = '/contracts/my';
  static const String lawyerContracts = '/contracts/lawyer';
  static String contractById(String id) => '/contracts/$id';
  static String contractByApplication(String applicationId) =>
      '/contracts/application/$applicationId';
  static String contractUpdateStatus(String id) => '/contracts/$id/status';
  static String contractSign(String id) => '/contracts/$id/sign';

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

  /// Build URL for lawyer picture
  static String getLawyerPictureUrl(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) return '';
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return imagePath;
    }
    final filename = imagePath.split('/').last;
    return '$baseUrl/uploads/lawyers/pictures/$filename';
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
