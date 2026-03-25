import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../core/constants/api_constants.dart';
import '../models/user_model.dart';
import 'api_service.dart';
import 'token_service.dart';

/// Service for fetching lawyer data from the backend
class LawyerService {
  final ApiService _apiService = ApiService();

  /// Get all lawyers
  Future<List<UserModel>> getAllLawyers() async {
    final response = await _apiService.get(
      ApiConstants.lawyers,
      requiresAuth: false,
    );

    if (response is List) {
      return response
          .map((json) => UserModel.fromJson(json as Map<String, dynamic>))
          .toList();
    }

    return [];
  }

  /// Get a single lawyer by ID
  Future<UserModel> getLawyerById(String id) async {
    final response = await _apiService.get(
      ApiConstants.lawyerById(id),
      requiresAuth: true,
    );

    return UserModel.fromJson(response as Map<String, dynamic>);
  }

  /// Verify a lawyer by checking the Tunisian Bar Association database
  Future<Map<String, dynamic>> verifyLawyer({
    required String fullName,
    required String cin,
    required String phone,
  }) async {
    final response = await http.post(
      Uri.parse(ApiConstants.verifyLawyerUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': fullName,
        'cin': cin,
        'phone': phone,
      }),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    throw ApiException(
      'Verification service unavailable',
      statusCode: response.statusCode,
    );
  }

  /// Persist verification status to the backend
  Future<UserModel> setVerified(String id, bool isVerified) async {
    final response = await _apiService.patch(
      ApiConstants.lawyerVerify(id),
      body: {'isVerified': isVerified},
      requiresAuth: true,
    );
    return UserModel.fromJson(response);
  }

  /// Update lawyer profile (picture, text fields, location) via multipart PATCH
  Future<UserModel> updateLawyerProfile(
    String id, {
    Uint8List? pictureBytes,
    String? pictureFileName,
    String? name,
    String? lastName,
    String? email,
    String? phoneNumber,
    String? identitynumber,
    double? latitude,
    double? longitude,
  }) async {
    final uri = Uri.parse(
        '${ApiConstants.baseUrl}${ApiConstants.lawyerProfile(id)}');
    final request = http.MultipartRequest('PATCH', uri);

    // Auth header
    final token = await TokenService.getAccessToken();
    if (token == null) throw ApiException(ErrorCodes.loginRequired);
    request.headers['Authorization'] = 'Bearer $token';

    // Text fields
    if (name != null && name.isNotEmpty) {
      request.fields['name'] = name;
    }
    if (lastName != null && lastName.isNotEmpty) {
      request.fields['lastName'] = lastName;
    }
    if (email != null && email.isNotEmpty) {
      request.fields['email'] = email;
    }
    if (phoneNumber != null && phoneNumber.isNotEmpty) {
      request.fields['phoneNumber'] = phoneNumber;
    }
    if (identitynumber != null && identitynumber.isNotEmpty) {
      request.fields['identitynumber'] = identitynumber;
    }

    // Optional form fields
    if (latitude != null) {
      request.fields['latitude'] = latitude.toString();
    }
    if (longitude != null) {
      request.fields['longitude'] = longitude.toString();
    }

    // Picture file
    if (pictureBytes != null && pictureFileName != null) {
      request.files.add(http.MultipartFile.fromBytes(
        'picture',
        pictureBytes,
        filename: pictureFileName,
        contentType: _mediaType(pictureFileName),
      ));
    }

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return UserModel.fromJson(body);
    }

    throw ApiException(
      'Failed to update profile',
      statusCode: response.statusCode,
    );
  }

  MediaType _mediaType(String filename) {
    final ext = filename.split('.').last.toLowerCase();
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return MediaType('image', 'jpeg');
      case 'png':
        return MediaType('image', 'png');
      case 'webp':
        return MediaType('image', 'webp');
      case 'pdf':
        return MediaType('application', 'pdf');
      default:
        return MediaType('application', 'octet-stream');
    }
  }
}
