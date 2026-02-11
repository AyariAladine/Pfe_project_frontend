import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../core/constants/api_constants.dart';
import 'token_service.dart';

/// Error codes for localization
class ErrorCodes {
  static const String noInternet = 'NO_INTERNET';
  static const String unexpectedError = 'UNEXPECTED_ERROR';
  static const String loginRequired = 'LOGIN_REQUIRED';
  static const String invalidCredentials = 'INVALID_CREDENTIALS';
  static const String unauthorized = 'UNAUTHORIZED';
  static const String notFound = 'NOT_FOUND';
  static const String serverError = 'SERVER_ERROR';
  static const String emailExists = 'EMAIL_EXISTS';
}

/// Exception for API errors
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  
  ApiException(this.message, {this.statusCode});
  
  @override
  String toString() => message;
}

/// Service for making HTTP requests to the NestJS backend
class ApiService {
  final http.Client _client = http.Client();
  
  /// Make a POST request
  Future<Map<String, dynamic>> post(
    String endpoint, {
    Map<String, dynamic>? body,
    bool requiresAuth = false,
  }) async {
    try {
      final headers = await _getHeaders(requiresAuth);
      
      final response = await _client.post(
        Uri.parse('${ApiConstants.baseUrl}$endpoint'),
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      );
      
      return _handleResponse(response);
    } on SocketException {
      throw ApiException(ErrorCodes.noInternet);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(ErrorCodes.unexpectedError);
    }
  }
  
  /// Make a GET request
  Future<dynamic> get(
    String endpoint, {
    bool requiresAuth = false,
  }) async {
    try {
      final headers = await _getHeaders(requiresAuth);
      
      final response = await _client.get(
        Uri.parse('${ApiConstants.baseUrl}$endpoint'),
        headers: headers,
      );
      
      return _handleResponseDynamic(response);
    } on SocketException {
      throw ApiException(ErrorCodes.noInternet);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(ErrorCodes.unexpectedError);
    }
  }
  
  /// Make a PATCH request
  Future<Map<String, dynamic>> patch(
    String endpoint, {
    Map<String, dynamic>? body,
    bool requiresAuth = true,
  }) async {
    try {
      final headers = await _getHeaders(requiresAuth);
      
      final response = await _client.patch(
        Uri.parse('${ApiConstants.baseUrl}$endpoint'),
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      );
      
      return _handleResponse(response);
    } on SocketException {
      throw ApiException(ErrorCodes.noInternet);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(ErrorCodes.unexpectedError);
    }
  }
  
  /// Make a DELETE request
  Future<Map<String, dynamic>> delete(
    String endpoint, {
    bool requiresAuth = true,
  }) async {
    try {
      final headers = await _getHeaders(requiresAuth);
      
      final response = await _client.delete(
        Uri.parse('${ApiConstants.baseUrl}$endpoint'),
        headers: headers,
      );
      
      return _handleResponse(response);
    } on SocketException {
      throw ApiException(ErrorCodes.noInternet);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(ErrorCodes.unexpectedError);
    }
  }
  
  /// Make a POST request with multipart/form-data (form fields + optional file)
  Future<Map<String, dynamic>> postMultipart(
    String endpoint, {
    Map<String, String>? fields,
    Uint8List? fileBytes,
    String? fileName,
    String fieldName = 'file',
    bool requiresAuth = false,
  }) async {
    try {
      final uri = Uri.parse('${ApiConstants.baseUrl}$endpoint');
      final request = http.MultipartRequest('POST', uri);

      // Add auth header if required
      if (requiresAuth) {
        final token = await TokenService.getAccessToken();
        if (token == null) {
          throw ApiException(ErrorCodes.loginRequired);
        }
        request.headers['Authorization'] = 'Bearer $token';
      }

      // Add form fields
      if (fields != null) {
        request.fields.addAll(fields);
      }

      // Add file if provided
      if (fileBytes != null && fileName != null) {
        final ext = fileName.split('.').last.toLowerCase();
        MediaType? contentType;
        switch (ext) {
          case 'jpg':
          case 'jpeg':
            contentType = MediaType('image', 'jpeg');
            break;
          case 'png':
            contentType = MediaType('image', 'png');
            break;
          case 'webp':
            contentType = MediaType('image', 'webp');
            break;
          case 'pdf':
            contentType = MediaType('application', 'pdf');
            break;
          default:
            contentType = MediaType('application', 'octet-stream');
        }

        request.files.add(http.MultipartFile.fromBytes(
          fieldName,
          fileBytes,
          filename: fileName,
          contentType: contentType,
        ));
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      return _handleResponse(response);
    } on SocketException {
      throw ApiException(ErrorCodes.noInternet);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(ErrorCodes.unexpectedError);
    }
  }

  /// Upload a file using multipart/form-data (works on both web and mobile)
  Future<Map<String, dynamic>> uploadFile(
    String endpoint, {
    required Uint8List fileBytes,
    required String fileName,
    String fieldName = 'file',
    bool requiresAuth = false,
  }) async {
    try {
      final uri = Uri.parse('${ApiConstants.baseUrl}$endpoint');
      print('Uploading to: $uri');
      final request = http.MultipartRequest('POST', uri);
      
      // Add auth header if required
      if (requiresAuth) {
        final token = await TokenService.getAccessToken();
        if (token == null) {
          throw ApiException(ErrorCodes.loginRequired);
        }
        request.headers['Authorization'] = 'Bearer $token';
        print('Auth header added');
      }
      
      // Determine MIME type from file extension
      final extension = fileName.split('.').last.toLowerCase();
      MediaType? contentType;
      switch (extension) {
        case 'jpg':
        case 'jpeg':
          contentType = MediaType('image', 'jpeg');
          break;
        case 'png':
          contentType = MediaType('image', 'png');
          break;
        case 'webp':
          contentType = MediaType('image', 'webp');
          break;
        default:
          contentType = MediaType('image', 'jpeg'); // Default to JPEG
      }
      
      print('File: $fileName, ContentType: $contentType, Size: ${fileBytes.length} bytes');
      
      // Add the file with content type
      request.files.add(http.MultipartFile.fromBytes(
        fieldName,
        fileBytes,
        filename: fileName,
        contentType: contentType,
      ));
      
      // Send the request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
      
      return _handleResponse(response);
    } on SocketException catch (e) {
      print('SocketException: $e');
      throw ApiException(ErrorCodes.noInternet);
    } catch (e) {
      print('Upload error: $e');
      if (e is ApiException) rethrow;
      throw ApiException(ErrorCodes.unexpectedError);
    }
  }
  
  /// Get headers with optional auth token
  Future<Map<String, String>> _getHeaders(bool requiresAuth) async {
    if (requiresAuth) {
      final token = await TokenService.getAccessToken();
      if (token == null) {
        throw ApiException(ErrorCodes.loginRequired);
      }
      return ApiConstants.authHeaders(token);
    }
    return ApiConstants.headers;
  }
  
  /// Handle HTTP response (returns Map)
  Map<String, dynamic> _handleResponse(http.Response response) {
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }
    
    // Handle error responses - use error codes instead of hardcoded messages
    final message = body['message'];
    final rawMessage = message is List 
        ? message.first.toString()
        : message?.toString() ?? '';
    
    switch (response.statusCode) {
      case 400:
        throw ApiException(rawMessage.isNotEmpty ? rawMessage : ErrorCodes.unexpectedError, statusCode: 400);
      case 401:
        throw ApiException(ErrorCodes.invalidCredentials, statusCode: 401);
      case 403:
        throw ApiException(ErrorCodes.unauthorized, statusCode: 403);
      case 404:
        throw ApiException(ErrorCodes.notFound, statusCode: 404);
      case 409:
        // Check if it's an email conflict
        if (rawMessage.toLowerCase().contains('email') || 
            rawMessage.contains('مسجل') ||
            rawMessage.contains('exist')) {
          throw ApiException(ErrorCodes.emailExists, statusCode: 409);
        }
        throw ApiException(rawMessage.isNotEmpty ? rawMessage : ErrorCodes.unexpectedError, statusCode: 409);
      case 500:
        throw ApiException(ErrorCodes.serverError, statusCode: 500);
      default:
        throw ApiException(rawMessage.isNotEmpty ? rawMessage : ErrorCodes.unexpectedError, statusCode: response.statusCode);
    }
  }
  
  /// Handle HTTP response (returns dynamic - can be Map or List)
  dynamic _handleResponseDynamic(http.Response response) {
    final body = jsonDecode(response.body);
    
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }
    
    // Handle error responses
    if (body is Map<String, dynamic>) {
      final message = body['message'];
      final rawMessage = message is List 
          ? message.first.toString()
          : message?.toString() ?? '';
      
      switch (response.statusCode) {
        case 400:
          throw ApiException(rawMessage.isNotEmpty ? rawMessage : ErrorCodes.unexpectedError, statusCode: 400);
        case 401:
          throw ApiException(ErrorCodes.invalidCredentials, statusCode: 401);
        case 403:
          throw ApiException(ErrorCodes.unauthorized, statusCode: 403);
        case 404:
          throw ApiException(ErrorCodes.notFound, statusCode: 404);
        case 500:
          throw ApiException(ErrorCodes.serverError, statusCode: 500);
        default:
          throw ApiException(rawMessage.isNotEmpty ? rawMessage : ErrorCodes.unexpectedError, statusCode: response.statusCode);
      }
    }
    
    throw ApiException(ErrorCodes.unexpectedError, statusCode: response.statusCode);
  }
  
  /// Refresh access token using refresh token
  Future<bool> refreshToken() async {
    try {
      final refreshToken = await TokenService.getRefreshToken();
      if (refreshToken == null) return false;
      
      final response = await post(
        ApiConstants.refresh,
        body: {'refreshToken': refreshToken},
      );
      
      await TokenService.saveAccessToken(response['access_token']);
      await TokenService.saveRefreshToken(response['refresh_token']);
      
      return true;
    } catch (e) {
      await TokenService.clearTokens();
      return false;
    }
  }
  
  void dispose() {
    _client.close();
  }
}
