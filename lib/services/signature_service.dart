import 'dart:typed_data';
import '../core/constants/api_constants.dart';
import 'api_service.dart';

/// Service for managing user electronic signatures.
/// Uploads signature PNG to the backend and retrieves the URL.
class SignatureService {
  final ApiService _apiService = ApiService();

  /// Upload a signature image for a user.
  /// Returns the signature URL from the backend response.
  Future<String?> uploadSignature({
    required String userId,
    required Uint8List signatureBytes,
    required bool isLawyer,
  }) async {
    final endpoint = isLawyer
        ? ApiConstants.lawyerSignature(userId)
        : ApiConstants.userSignature(userId);

    final response = await _apiService.postMultipart(
      endpoint,
      fileBytes: signatureBytes,
      fileName: 'signature.png',
      fieldName: 'signature',
      requiresAuth: true,
    );

    return response['signatureUrl'] as String?;
  }

  /// Delete the user's signature.
  Future<void> deleteSignature({
    required String userId,
    required bool isLawyer,
  }) async {
    final endpoint = isLawyer
        ? ApiConstants.lawyerSignature(userId)
        : ApiConstants.userSignature(userId);

    await _apiService.delete(endpoint, requiresAuth: true);
  }
}
