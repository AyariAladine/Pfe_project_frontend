import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../core/constants/api_constants.dart';

class FaceRecognitionResult {
  final bool success;
  final String message;
  final String? userId;
  final double? confidence;

  FaceRecognitionResult({
    required this.success,
    required this.message,
    this.userId,
    this.confidence,
  });
}

class FaceRecognitionService {
  final http.Client _client = http.Client();
  static const _timeout = Duration(seconds: 30);

  /// Register a face for the given user email
  Future<FaceRecognitionResult> registerFace({
    required String userEmail,
    required Uint8List imageBytes,
    String fileName = 'face.jpg',
  }) async {
    try {
      final uri = Uri.parse('${ApiConstants.faceRecognitionBaseUrl}/register/');
      final request = http.MultipartRequest('POST', uri);

      request.fields['user_id'] = userEmail;
      request.files.add(http.MultipartFile.fromBytes(
        'file',
        imageBytes,
        filename: fileName,
        contentType: MediaType('image', 'jpeg'),
      ));

      debugPrint('[FaceRecognition] POST $uri  user=$userEmail  bytes=${imageBytes.length}');
      final streamedResponse = await request.send().timeout(_timeout);
      final response = await http.Response.fromStream(streamedResponse);
      debugPrint('[FaceRecognition] register status=${response.statusCode} body=${response.body}');
      final body = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        return FaceRecognitionResult(
          success: true,
          message: body['message']?.toString() ?? 'Face registered',
        );
      } else {
        return FaceRecognitionResult(
          success: false,
          message: body['detail']?.toString() ?? 'Registration failed',
        );
      }
    } on TimeoutException {
      debugPrint('[FaceRecognition] register TIMEOUT');
      return FaceRecognitionResult(success: false, message: 'Request timed out');
    } catch (e) {
      debugPrint('[FaceRecognition] register ERROR: $e');
      return FaceRecognitionResult(
        success: false,
        message: e.toString(),
      );
    }
  }

  /// Recognize a face from the given image
  Future<FaceRecognitionResult> recognizeFace({
    required Uint8List imageBytes,
    String fileName = 'face.jpg',
  }) async {
    try {
      final uri =
          Uri.parse('${ApiConstants.faceRecognitionBaseUrl}/recognize/');
      final request = http.MultipartRequest('POST', uri);

      request.files.add(http.MultipartFile.fromBytes(
        'file',
        imageBytes,
        filename: fileName,
        contentType: MediaType('image', 'jpeg'),
      ));

      debugPrint('[FaceRecognition] POST $uri  bytes=${imageBytes.length}');
      final streamedResponse = await request.send().timeout(_timeout);
      final response = await http.Response.fromStream(streamedResponse);
      debugPrint('[FaceRecognition] recognize status=${response.statusCode} body=${response.body}');
      final body = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        return FaceRecognitionResult(
          success: true,
          message: body['message']?.toString() ?? 'Face recognized',
          userId: body['user_id']?.toString(),
          confidence: (body['confidence'] as num?)?.toDouble(),
        );
      } else {
        return FaceRecognitionResult(
          success: false,
          message: body['detail']?.toString() ?? 'Recognition failed',
        );
      }
    } on TimeoutException {
      debugPrint('[FaceRecognition] recognize TIMEOUT');
      return FaceRecognitionResult(success: false, message: 'Request timed out');
    } catch (e) {
      debugPrint('[FaceRecognition] recognize ERROR: $e');
      return FaceRecognitionResult(
        success: false,
        message: e.toString(),
      );
    }
  }

  /// Delete a registered face for the given user email
  Future<FaceRecognitionResult> deleteFace({
    required String userEmail,
  }) async {
    try {
      final uri = Uri.parse(
          '${ApiConstants.faceRecognitionBaseUrl}/users/${Uri.encodeComponent(userEmail)}');
      debugPrint('[FaceRecognition] DELETE $uri');
      final response = await _client.delete(uri).timeout(_timeout);
      debugPrint('[FaceRecognition] delete status=${response.statusCode} body=${response.body}');
      final body = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        return FaceRecognitionResult(
          success: true,
          message: body['message']?.toString() ?? 'Face deleted',
        );
      } else {
        return FaceRecognitionResult(
          success: false,
          message: body['detail']?.toString() ?? 'Delete failed',
        );
      }
    } on TimeoutException {
      debugPrint('[FaceRecognition] delete TIMEOUT');
      return FaceRecognitionResult(success: false, message: 'Request timed out');
    } catch (e) {
      debugPrint('[FaceRecognition] delete ERROR: $e');
      return FaceRecognitionResult(
        success: false,
        message: e.toString(),
      );
    }
  }
}
