import '../core/constants/api_constants.dart';
import 'api_service.dart';

/// Service for SMS OTP verification
class OtpService {
  final ApiService _apiService = ApiService();

  /// Ensure phone number is in E.164 format (+216 for Tunisia)
  String _toE164(String phoneNumber) {
    final digits = phoneNumber.replaceAll(RegExp(r'[\s\-()]'), '');
    if (digits.startsWith('+')) return digits;
    if (digits.startsWith('00216')) return '+${digits.substring(2)}';
    if (digits.startsWith('216') && digits.length > 8) return '+$digits';
    return '+216$digits';
  }

  /// Send an OTP code to the given phone number
  /// Returns true if the code was sent successfully
  Future<bool> sendOtp(String phoneNumber) async {
    try {
      await _apiService.post(
        ApiConstants.sendOtp,
        body: {'phoneNumber': _toE164(phoneNumber)},
        requiresAuth: true,
      );
      return true;
    } on ApiException {
      rethrow;
    }
  }

  /// Verify the OTP code entered by the user
  /// Returns true if the code is valid
  Future<bool> verifyOtp(String phoneNumber, String code) async {
    try {
      final response = await _apiService.post(
        ApiConstants.verifyOtp,
        body: {'phoneNumber': _toE164(phoneNumber), 'code': code},
        requiresAuth: true,
      );
      return response['verified'] == true;
    } on ApiException {
      rethrow;
    }
  }
}
