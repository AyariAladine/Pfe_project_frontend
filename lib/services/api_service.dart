import 'dart:async';
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

  // ── Static refresh coordination (shared across all instances) ──
  static Completer<bool>? _refreshCompleter;

  /// Decode JWT payload to check token expiry (without verifying signature)
  static bool _isTokenExpired(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return true;
      // Base64-decode the payload
      String payload = parts[1];
      // Add padding if needed
      switch (payload.length % 4) {
        case 2: payload += '=='; break;
        case 3: payload += '='; break;
      }
      final decoded = utf8.decode(base64Url.decode(payload));
      final map = jsonDecode(decoded) as Map<String, dynamic>;
      final exp = map['exp'] as int?;
      if (exp == null) return true;
      // Consider expired if less than 30 seconds remaining
      final expiry = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
      return DateTime.now().isAfter(expiry.subtract(const Duration(seconds: 30)));
    } catch (_) {
      return false; // If we can't decode, let the server decide
    }
  }

  /// Proactively refresh the token if it's expired or about to expire.
  /// Returns true if token is valid (either already valid or refreshed).
  Future<bool> _ensureValidToken() async {
    final token = await TokenService.getAccessToken();
    if (token == null) return false;
    if (!_isTokenExpired(token)) return true;
    // Token is expired or about to expire — refresh it
    return _coordinatedRefresh();
  }

  /// Coordinate refresh across all ApiService instances.
  /// If a refresh is already in progress, wait for it instead of firing another.
  Future<bool> _coordinatedRefresh() async {
    if (_refreshCompleter != null) {
      // Another request is already refreshing — wait for it
      return _refreshCompleter!.future;
    }
    _refreshCompleter = Completer<bool>();
    try {
      final result = await _doRefreshToken();
      _refreshCompleter!.complete(result);
      return result;
    } catch (e) {
      _refreshCompleter!.complete(false);
      return false;
    } finally {
      _refreshCompleter = null;
    }
  }

  /// Retry an authenticated request once after refreshing the token on 401
  Future<T> _withTokenRetry<T>(bool requiresAuth, Future<T> Function() request) async {
    if (requiresAuth) {
      await _ensureValidToken();
    }
    try {
      return await request();
    } on ApiException catch (e) {
      if (e.statusCode == 401 && requiresAuth) {
        final refreshed = await _coordinatedRefresh();
        if (refreshed) {
          return await request();
        }
      }
      rethrow;
    }
  }

  /// Make a POST request
  Future<Map<String, dynamic>> post(
    String endpoint, {
    Map<String, dynamic>? body,
    bool requiresAuth = false,
  }) async {
    return _withTokenRetry(requiresAuth, () async {
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
    });
  }
  
  /// Make a GET request
  Future<dynamic> get(
    String endpoint, {
    bool requiresAuth = false,
  }) async {
    return _withTokenRetry(requiresAuth, () async {
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
    });
  }
  
  /// Make a PATCH request
  Future<Map<String, dynamic>> patch(
    String endpoint, {
    Map<String, dynamic>? body,
    bool requiresAuth = true,
  }) async {
    return _withTokenRetry(requiresAuth, () async {
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
    });
  }
  
  /// Make a DELETE request
  Future<Map<String, dynamic>> delete(
    String endpoint, {
    bool requiresAuth = true,
  }) async {
    return _withTokenRetry(requiresAuth, () async {
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
    });
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
    return _withTokenRetry(requiresAuth, () async {
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
    });
  }

  /// Upload a file using multipart/form-data (works on both web and mobile)
  Future<Map<String, dynamic>> uploadFile(
    String endpoint, {
    required Uint8List fileBytes,
    required String fileName,
    String fieldName = 'file',
    Map<String, String>? fields,
    bool requiresAuth = false,
  }) async {
    return uploadMultipleFiles(
      endpoint,
      allFileBytes: [fileBytes],
      allFileNames: [fileName],
      fieldName: fieldName,
      fields: fields,
      requiresAuth: requiresAuth,
    );
  }

  /// Upload one or more files using multipart/form-data
  Future<Map<String, dynamic>> uploadMultipleFiles(
    String endpoint, {
    required List<Uint8List> allFileBytes,
    required List<String> allFileNames,
    String fieldName = 'file',
    Map<String, String>? fields,
    bool requiresAuth = false,
  }) async {
    return _withTokenRetry(requiresAuth, () async {
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

        if (fields != null && fields.isNotEmpty) {
          request.fields.addAll(fields);
        }
        
        // Determine MIME type from file extension
        for (int i = 0; i < allFileBytes.length; i++) {
          final fileName = allFileNames[i];
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
              contentType = MediaType('image', 'jpeg');
          }

          request.files.add(http.MultipartFile.fromBytes(
            fieldName,
            allFileBytes[i],
            filename: fileName,
            contentType: contentType,
          ));
        }
        
        // Send the request
        final streamedResponse = await request.send();
        final response = await http.Response.fromStream(streamedResponse);
        
        return _handleResponse(response);
      } on SocketException {
        throw ApiException(ErrorCodes.noInternet);
      } catch (e) {
        if (e is ApiException) rethrow;
        throw ApiException(ErrorCodes.unexpectedError);
      }
    });
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
    // Handle empty body (e.g. 204 No Content)
    if (response.body.isEmpty) {
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {};
      }
      throw ApiException(ErrorCodes.unexpectedError, statusCode: response.statusCode);
    }

    Map<String, dynamic> body;
    try {
      body = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {};
      }
      throw ApiException(ErrorCodes.unexpectedError, statusCode: response.statusCode);
    }

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
  
  /// Public method for explicit token refresh (e.g. from AuthService)
  Future<bool> refreshToken() => _coordinatedRefresh();

  /// Internal: actually refresh the access token using the refresh token
  Future<bool> _doRefreshToken() async {
    try {
      final refreshToken = await TokenService.getRefreshToken();
      if (refreshToken == null) return false;
      
      final headers = {'Content-Type': 'application/json'};
      final response = await _client.post(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.refresh}'),
        headers: headers,
        body: jsonEncode({'refreshToken': refreshToken}),
      );
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        await TokenService.saveAccessToken(body['access_token']);
        await TokenService.saveRefreshToken(body['refresh_token']);
        return true;
      }
      
      await TokenService.clearTokens();
      return false;
    } catch (e) {
      await TokenService.clearTokens();
      return false;
    }
  }
  
  void dispose() {
    _client.close();
  }
}
