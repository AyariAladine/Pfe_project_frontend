import 'package:flutter/foundation.dart' show kIsWeb;
import '../core/constants/api_constants.dart';
import '../models/user_model.dart';
import 'api_service.dart';
import 'token_service.dart';
import 'google_auth_service.dart';

/// Authentication service for NestJS backend
class AuthService {
  final ApiService _apiService = ApiService();
  final GoogleAuthService _googleAuthService = GoogleAuthService();

  UserModel? _currentUser;

  /// Get current logged-in user
  UserModel? get currentUser => _currentUser;

  /// Check if user is logged in
  Future<bool> isLoggedIn() async {
    return await TokenService.hasTokens();
  }

  /// Sign in with Google
  /// For existing users: automatically logs in
  /// For new users: throws RoleRequiredException which should be caught to show role selection
  Future<GoogleAuthResult> signInWithGoogle({UserRole? role}) async {
    try {
      final response = await _googleAuthService.signInWithGoogle(role: role);
      if (response == null) {
        return GoogleAuthResult.cancelled();
      }

      _currentUser = response.user;

      return GoogleAuthResult.success(
        user: response.user,
        isNewUser: response.isNewUser,
        accountLinked: response.accountLinked,
        message: response.message,
      );
    } on RoleRequiredException catch (e) {
      // ⭐ CRITICAL FIX: Pass all necessary data including idToken, accessToken, and isWeb flag
      return GoogleAuthResult.roleRequired(
        idToken: e.idToken,
        accessToken: e.accessToken,
        email: e.email,
        displayName: e.displayName,
        photoUrl: e.photoUrl,
        isWeb: e.isWeb,
      );
    }
  }

  /// Complete Google sign-up with role for new users
  /// ⭐ CRITICAL FIX: Accept both idToken and accessToken, determine platform automatically
  Future<GoogleAuthResult> completeGoogleSignUp({
    String? idToken,
    String? accessToken,
    required UserRole role,
    bool? isWeb, // Optional - will auto-detect if not provided
  }) async {
    try {
      // Auto-detect platform if not explicitly provided
      final platformIsWeb = isWeb ?? kIsWeb;

      final response = await _googleAuthService.completeGoogleSignUp(
        idToken: idToken,
        accessToken: accessToken,
        role: role,
        isWeb: platformIsWeb,
      );

      _currentUser = response.user;

      return GoogleAuthResult.success(
        user: response.user,
        isNewUser: response.isNewUser,
        accountLinked: response.accountLinked,
        message: response.message,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Sign up with email and password
  Future<UserModel> signUp({
    required String name,
    required String lastName,
    required String email,
    required String password,
    required UserRole role,
    required String phoneNumber,
  }) async {
    try {
      final createUserDto = CreateUserDto(
        name: name,
        lastName: lastName,
        email: email,
        password: password,
        role: role,
        phoneNumber: phoneNumber,
      );

      final response = await _apiService.post(
        ApiConstants.signup,
        body: createUserDto.toJson(),
      );

      // After signup, user needs to login to get tokens
      return UserModel.fromJson(response['user'] as Map<String, dynamic>);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('فشل في إنشاء الحساب: $e');
    }
  }

  /// Sign in with email and password
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final loginDto = LoginDto(email: email, password: password);

      final response = await _apiService.post(
        ApiConstants.login,
        body: loginDto.toJson(),
      );

      final authResponse = AuthResponse.fromJson(response);

      // Save tokens
      await TokenService.saveTokens(
        accessToken: authResponse.accessToken,
        refreshToken: authResponse.refreshToken,
        userId: authResponse.user.id,
      );

      _currentUser = authResponse.user;

      return authResponse;
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('فشل في تسجيل الدخول: $e');
    }
  }

  /// Get user profile
  Future<UserModel> getProfile() async {
    try {
      // Get user ID to fetch from /users/{userId}
      final userId = await TokenService.getUserId();
      if (userId == null) {
        throw ApiException('User not logged in');
      }

      final response = await _apiService.get(
        '${ApiConstants.users}/$userId',
        requiresAuth: true,
      );

      print('Profile response: $response');

      // Response is the user object directly, not wrapped in 'user'
      _currentUser = UserModel.fromJson(response);
      return _currentUser!;
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        // Try to refresh token
        final refreshed = await _apiService.refreshToken();
        if (refreshed) {
          return getProfile();
        }
      }
      rethrow;
    }
  }

  /// Send forgot password email
  Future<String> forgotPassword(String email) async {
    try {
      final response = await _apiService.post(
        ApiConstants.forgotPassword,
        body: {'email': email},
      );

      return response['message'] as String? ?? 'تم إرسال رمز التحقق';
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('فشل في إرسال رمز التحقق: $e');
    }
  }

  /// Reset password with verification code
  Future<String> resetPassword({
    required String code,
    required String newPassword,
  }) async {
    try {
      final response = await _apiService.post(
        ApiConstants.resetPassword,
        body: {'code': code, 'newPassword': newPassword},
      );

      return response['message'] as String? ?? 'تم تغيير كلمة المرور بنجاح';
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('فشل في تغيير كلمة المرور: $e');
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      final refreshToken = await TokenService.getRefreshToken();

      if (refreshToken != null) {
        await _apiService.post(
          ApiConstants.logout,
          body: {'refreshToken': refreshToken},
          requiresAuth: true,
        );
      }

      // Also sign out from Google
      await _googleAuthService.signOut();
    } catch (e) {
      // Ignore logout errors, just clear tokens
    } finally {
      await TokenService.clearTokens();
      _currentUser = null;
    }
  }

  /// Refresh access token
  Future<bool> refreshToken() async {
    return await _apiService.refreshToken();
  }

  /// Initialize auth state on app start
  Future<void> initializeAuth() async {
    try {
      if (await TokenService.hasTokens()) {
        await getProfile();
      }
    } catch (e) {
      await TokenService.clearTokens();
      _currentUser = null;
    }
  }

  void dispose() {
    _apiService.dispose();
  }
}

/// ⭐ GoogleAuthResult class - Result from Google authentication
class GoogleAuthResult {
  final bool success;
  final bool cancelled;
  final bool needsRole;
  final UserModel? user;
  final bool? isNewUser;
  final bool? accountLinked;
  final String? message;
  
  // Fields for role selection
  final String? idToken;
  final String? accessToken;
  final String? email;
  final String? displayName;
  final String? photoUrl;
  final bool? isWeb;

  GoogleAuthResult._({
    required this.success,
    required this.cancelled,
    required this.needsRole,
    this.user,
    this.isNewUser,
    this.accountLinked,
    this.message,
    this.idToken,
    this.accessToken,
    this.email,
    this.displayName,
    this.photoUrl,
    this.isWeb,
  });

  factory GoogleAuthResult.success({
    required UserModel user,
    bool? isNewUser,
    bool? accountLinked,
    String? message,
  }) {
    return GoogleAuthResult._(
      success: true,
      cancelled: false,
      needsRole: false,
      user: user,
      isNewUser: isNewUser,
      accountLinked: accountLinked,
      message: message,
    );
  }

  factory GoogleAuthResult.cancelled() {
    return GoogleAuthResult._(
      success: false,
      cancelled: true,
      needsRole: false,
    );
  }

  factory GoogleAuthResult.roleRequired({
    String? idToken,
    String? accessToken,
    required String email,
    String? displayName,
    String? photoUrl,
    required bool isWeb,
  }) {
    return GoogleAuthResult._(
      success: false,
      cancelled: false,
      needsRole: true,
      idToken: idToken,
      accessToken: accessToken,
      email: email,
      displayName: displayName,
      photoUrl: photoUrl,
      isWeb: isWeb,
    );
  }
}

// Supporting DTOs
class CreateUserDto {
  final String name;
  final String lastName;
  final String email;
  final String password;
  final UserRole role;
  final String phoneNumber;

  CreateUserDto({
    required this.name,
    required this.lastName,
    required this.email,
    required this.password,
    required this.role,
    required this.phoneNumber,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'lastName': lastName,
        'email': email,
        'password': password,
        'role': role.name,
        'phoneNumber': phoneNumber,
      };
}

class LoginDto {
  final String email;
  final String password;

  LoginDto({required this.email, required this.password});

  Map<String, dynamic> toJson() => {
        'email': email,
        'password': password,
      };
}

class AuthResponse {
  final String accessToken;
  final String refreshToken;
  final UserModel user;

  AuthResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String,
      user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}