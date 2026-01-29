import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Service for securely storing and retrieving JWT tokens
class TokenService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );
  
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userIdKey = 'user_id';
  
  /// Save access token
  static Future<void> saveAccessToken(String token) async {
    await _storage.write(key: _accessTokenKey, value: token);
  }
  
  /// Get access token
  static Future<String?> getAccessToken() async {
    return await _storage.read(key: _accessTokenKey);
  }
  
  /// Save refresh token
  static Future<void> saveRefreshToken(String token) async {
    await _storage.write(key: _refreshTokenKey, value: token);
  }
  
  /// Get refresh token
  static Future<String?> getRefreshToken() async {
    return await _storage.read(key: _refreshTokenKey);
  }
  
  /// Save user ID
  static Future<void> saveUserId(String userId) async {
    await _storage.write(key: _userIdKey, value: userId);
  }
  
  /// Get user ID
  static Future<String?> getUserId() async {
    return await _storage.read(key: _userIdKey);
  }
  
  /// Save all tokens at once
  static Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    required String userId,
  }) async {
    await Future.wait([
      saveAccessToken(accessToken),
      saveRefreshToken(refreshToken),
      saveUserId(userId),
    ]);
  }
  
  /// Clear all tokens (on logout)
  static Future<void> clearTokens() async {
    await Future.wait([
      _storage.delete(key: _accessTokenKey),
      _storage.delete(key: _refreshTokenKey),
      _storage.delete(key: _userIdKey),
    ]);
  }
  
  /// Check if user is logged in (has tokens)
  static Future<bool> hasTokens() async {
    final accessToken = await getAccessToken();
    return accessToken != null && accessToken.isNotEmpty;
  }
}
