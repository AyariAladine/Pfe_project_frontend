import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'api_service.dart';
import 'token_service.dart';

class OcrService {
  TextRecognizer? _textRecognizer;
  final ImagePicker _imagePicker = ImagePicker();
  final ApiService _apiService = ApiService();

  OcrService() {
    // Only initialize ML Kit on non-web platforms
    if (!kIsWeb) {
      _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
    }
  }

  /// OCR is now available on all platforms (web uses backend API)
  bool get isAvailable => true;

  /// Pick image from camera and extract identity number
  /// Always uses backend API to scan and save CIN number
  Future<String?> scanIdentityCard({bool fromCamera = true}) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: fromCamera ? ImageSource.camera : ImageSource.gallery,
        preferredCameraDevice: CameraDevice.rear,
        imageQuality: 100,
      );

      if (image == null) return null;

      // Always send to backend API - this does OCR and saves the CIN number
      return await _scanWithBackend(image);
    } catch (e) {
      print('Error scanning identity card: $e');
      return null;
    }
  }

  /// Scan image using backend OCR API (for web)
  Future<String?> _scanWithBackend(XFile image) async {
    try {
      // Get user ID for the endpoint
      final userId = await TokenService.getUserId();
      if (userId == null) {
        print('User not logged in');
        return null;
      }

      final Uint8List bytes = await image.readAsBytes();
      final String fileName = image.name.isNotEmpty ? image.name : 'image.jpg';

      print('Uploading image to /users/$userId/scan-id-card');

      // Endpoint: /users/{userId}/scan-id-card
      final response = await _apiService.uploadFile(
        '/users/$userId/scan-id-card',
        fileBytes: bytes,
        fileName: fileName,
        fieldName: 'image',
        requiresAuth: true,
      );

      print('OCR Response: $response');

      // Backend returns { "success": true, "identityNumber": "12345678", "user": {...} }
      if (response.containsKey('identityNumber')) {
        return response['identityNumber'] as String?;
      }
      
      if (response.containsKey('cinNumber')) {
        return response['cinNumber'] as String?;
      }
      
      if (response.containsKey('idCardNumber')) {
        return response['idCardNumber'] as String?;
      }

      // If backend returns raw text, try to extract CIN from it
      if (response.containsKey('text')) {
        return _findIdentityNumber(response['text'] as String);
      }

      print('No identity number found in response');
      return null;
    } catch (e) {
      print('Error with backend OCR: $e');
      return null;
    }
  }

  /// Extract identity number from an image file (mobile only)
  Future<String?> extractIdentityNumber(File imageFile) async {
    if (_textRecognizer == null) return null;

    try {
      final inputImage = InputImage.fromFile(imageFile);
      final RecognizedText recognizedText = await _textRecognizer!.processImage(
        inputImage,
      );

      // Find potential identity numbers in the recognized text
      final identityNumber = _findIdentityNumber(recognizedText.text);
      return identityNumber;
    } catch (e) {
      print('Error extracting text: $e');
      return null;
    }
  }

  /// Find identity number pattern in text
  /// This looks for common Tunisian CIN patterns (8 digits)
  String? _findIdentityNumber(String text) {
    // Remove spaces and newlines for easier parsing
    final cleanText = text.replaceAll(RegExp(r'\s+'), ' ');

    // Pattern for Tunisian CIN: 8 consecutive digits
    final RegExp cinPattern = RegExp(r'\b(\d{8})\b');
    final match = cinPattern.firstMatch(cleanText);

    if (match != null) {
      return match.group(1);
    }

    // Try to find any sequence of 8 digits even if not word-bounded
    final RegExp relaxedPattern = RegExp(r'(\d{8})');
    final relaxedMatch = relaxedPattern.firstMatch(cleanText);

    if (relaxedMatch != null) {
      return relaxedMatch.group(1);
    }

    // Look for numbers with spaces between them (e.g., "12 34 56 78")
    final RegExp spacedPattern = RegExp(r'(\d{2}\s?\d{2}\s?\d{2}\s?\d{2})');
    final spacedMatch = spacedPattern.firstMatch(cleanText);

    if (spacedMatch != null) {
      return spacedMatch.group(1)?.replaceAll(RegExp(r'\s'), '');
    }

    return null;
  }

  /// Get all recognized text from image (useful for debugging)
  Future<String> getFullText(File imageFile) async {
    if (_textRecognizer == null) return 'OCR not available on web';

    try {
      final inputImage = InputImage.fromFile(imageFile);
      final RecognizedText recognizedText = await _textRecognizer!.processImage(
        inputImage,
      );
      return recognizedText.text;
    } catch (e) {
      return 'Error: $e';
    }
  }

  /// Extract text from image path (works on both web and mobile)
  Future<String?> extractTextFromImage(String imagePath) async {
    if (kIsWeb) {
      // On web, we can't use ML Kit - return null and let user enter manually
      return null;
    }

    if (_textRecognizer == null) return null;

    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final RecognizedText recognizedText = await _textRecognizer!.processImage(
        inputImage,
      );
      return recognizedText.text;
    } catch (e) {
      print('Error extracting text from image: $e');
      return null;
    }
  }

  void dispose() {
    _textRecognizer?.close();
  }
}
