import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'api_service.dart';
import 'token_service.dart';
import '../core/constants/api_constants.dart';

class OcrService {
  final ImagePicker _imagePicker = ImagePicker();
  final ApiService _apiService = ApiService();

  bool get isAvailable => true;

  /// Pick image and return the 8-digit identity number, or null.
  Future<String?> scanIdentityCard({bool fromCamera = true}) async {
    final scanData = await scanIdentityCardData(
      side: 'front',
      fromCamera: fromCamera,
    );
    final fields =
        scanData?['extractedFields'] as Map<String, dynamic>? ?? const {};
    return fields['identityNumber']?.toString();
  }

  /// Pick an ID card image and return a structured payload from the backend.
  ///
  /// Result shape (mirrors what the Python Gemini service returns):
  ///   rawText              `String`
  ///   extractedFields      `Map<String, dynamic>`
  ///   fieldConfidences     `Map<String, double>` (0.0–1.0 per field)
  ///   missingFields        `List<String>`
  ///   requiresManualReview `bool`
  ///   error                `String?` — set when the backend returned an error
  Future<Map<String, dynamic>?> scanIdentityCardData({
    required String side,
    bool fromCamera = true,
  }) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: fromCamera ? ImageSource.camera : ImageSource.gallery,
        preferredCameraDevice: CameraDevice.rear,
        imageQuality: 90,
      );
      if (image == null) return null;
      return await _scanWithBackend(image, side: side);
    } catch (e) {
      debugPrint('OcrService.scanIdentityCardData error: $e');
      return {'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>?> _scanWithBackend(
    XFile image, {
    required String side,
  }) async {
    final userId = await TokenService.getUserId();
    if (userId == null) return null;

    final Uint8List bytes = await image.readAsBytes();
    final String fileName = image.name.isNotEmpty ? image.name : 'image.jpg';

    final response = await _apiService.uploadFile(
      ApiConstants.scanIdCard(userId),
      fileBytes: bytes,
      fileName: fileName,
      fieldName: 'image',
      fields: {'side': side},
      requiresAuth: true,
    );

    final extractedFields = response['extractedFields'];
    if (extractedFields is! Map) return null;

    final rawConfidences = response['fieldConfidences'];
    final Map<String, double> fieldConfidences = rawConfidences is Map
        ? Map.fromEntries(
            rawConfidences.entries.map(
              (e) => MapEntry(
                e.key.toString(),
                (e.value as num?)?.toDouble() ?? 0.0,
              ),
            ),
          )
        : {};

    final rawMissing = response['missingFields'];
    final List<String> missingFields = rawMissing is List
        ? rawMissing.map((e) => e.toString()).toList()
        : [];

    return {
      'side': side,
      'imageName': fileName,
      'rawText': response['rawText']?.toString() ?? '',
      'extractedFields': Map<String, dynamic>.from(extractedFields),
      'fieldConfidences': fieldConfidences,
      'missingFields': missingFields,
      'requiresManualReview': response['requiresManualReview'] == true,
    };
  }

  void dispose() {}
}
