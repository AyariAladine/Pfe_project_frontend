import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../core/constants/api_constants.dart';
import '../models/user_model.dart';
import 'api_service.dart';
import 'token_service.dart';

/// Response from Google Auth endpoint
class GoogleAuthResponse {
  final String accessToken;
  final String refreshToken;
  final UserModel user;
  final bool isNewUser;
  final bool? accountLinked;
  final String message;

  GoogleAuthResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
    required this.isNewUser,
    this.accountLinked,
    required this.message,
  });

  factory GoogleAuthResponse.fromJson(Map<String, dynamic> json) {
    return GoogleAuthResponse(
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String,
      user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
      isNewUser: json['isNewUser'] as bool? ?? false,
      accountLinked: json['accountLinked'] as bool?,
      message: json['message'] as String? ?? '',
    );
  }
}

/// Exception thrown when role is required for new Google users
class RoleRequiredException implements Exception {
  final String idToken;
  final String email;
  final String? displayName;
  final String? photoUrl;

  RoleRequiredException({
    required this.idToken,
    required this.email,
    this.displayName,
    this.photoUrl,
  });

  @override
  String toString() => 'Role is required for new users signing up with Google';
}

/// Service for Google Sign-In authentication
class GoogleAuthService {
  static final GoogleAuthService _instance = GoogleAuthService._internal();
  factory GoogleAuthService() => _instance;
  GoogleAuthService._internal();

  // Web Client ID
  static const String _webClientId =
      '761230600985-tlh9veu4g4e9e13c2rs58ssr94j93h5l.apps.googleusercontent.com';

  // ✅ FIXED: Different configuration for web vs mobile
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    // ⭐ CRITICAL: On web, DO NOT use serverClientId (it's not supported)
    // On mobile, USE serverClientId to get idToken
    serverClientId: kIsWeb ? null : _webClientId,
  );

  final ApiService _apiService = ApiService();

  /// Check if user is signed in with Google
  Future<bool> isSignedIn() async {
    return await _googleSignIn.isSignedIn();
  }

  /// Get Google ID token for authentication
  /// Returns null if user cancels the sign-in
  Future<GoogleSignInResult?> getGoogleIdToken() async {
    try {
      debugPrint('🔵 Starting Google Sign-In...');
      debugPrint('Platform: ${kIsWeb ? "WEB" : "MOBILE"}');
      
      // Trigger Google Sign-In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        debugPrint('❌ Google sign-in cancelled by user');
        return null;
      }

      debugPrint('✅ Google user signed in: ${googleUser.email}');

      // Get authentication tokens
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      debugPrint('🔑 Access Token: ${googleAuth.accessToken != null ? "✅ Available" : "❌ Missing"}');
      debugPrint('🔑 ID Token: ${googleAuth.idToken != null ? "✅ Available" : "❌ Missing"}');

      // ⭐ On WEB: idToken might be null (this is expected behavior)
      // We'll use a different approach for web
      if (kIsWeb) {
        debugPrint('⚠️ Running on WEB - Using alternative authentication method');
        
        // On web, we can use the accessToken to get user info from Google
        // Then your backend can verify it
        if (googleAuth.accessToken == null) {
          throw ApiException('Failed to get Google access token');
        }

        return GoogleSignInResult(
          idToken: googleAuth.idToken, // May be null on web
          accessToken: googleAuth.accessToken!,
          email: googleUser.email,
          displayName: googleUser.displayName,
          photoUrl: googleUser.photoUrl,
          isWeb: true,
        );
      } else {
        // On MOBILE: We should have idToken
        if (googleAuth.idToken == null) {
          debugPrint('❌ CRITICAL: ID Token is null on mobile!');
          throw ApiException('Failed to get Google ID token. Please try again.');
        }

        debugPrint('✅ ID Token received successfully');
        return GoogleSignInResult(
          idToken: googleAuth.idToken!,
          accessToken: googleAuth.accessToken,
          email: googleUser.email,
          displayName: googleUser.displayName,
          photoUrl: googleUser.photoUrl,
          isWeb: false,
        );
      }
    } catch (e) {
      debugPrint('❌ Google sign-in error: $e');
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException('Google sign-in failed: ${e.toString()}');
    }
  }

  /// Sign in with Google and authenticate with backend
  /// For existing users, no role is needed
  /// For new users, role must be provided
  Future<GoogleAuthResponse?> signInWithGoogle({UserRole? role}) async {
    try {
      debugPrint('🔵 Starting Google Sign-In flow...');
      
      final googleResult = await getGoogleIdToken();
      if (googleResult == null) {
        debugPrint('⚠️ User cancelled Google Sign-In');
        return null;
      }

      debugPrint('🔵 Authenticating with backend...');
      
      return await authenticateWithBackend(
        idToken: googleResult.idToken,
        accessToken: googleResult.accessToken,
        role: role,
        email: googleResult.email,
        displayName: googleResult.displayName,
        photoUrl: googleResult.photoUrl,
        isWeb: googleResult.isWeb,
      );
    } catch (e) {
      debugPrint('❌ Google sign-in error: $e');
      rethrow;
    }
  }

  /// Authenticate with backend using Google token
  /// Throws RoleRequiredException if this is a new user and no role was provided
  Future<GoogleAuthResponse> authenticateWithBackend({
    String? idToken,
    String? accessToken,
    UserRole? role,
    String? email,
    String? displayName,
    String? photoUrl,
    bool isWeb = false,
  }) async {
    try {
      // Build request body
      final Map<String, dynamic> body = {};

      if (idToken != null) {
        body['idToken'] = idToken;
      }
      
      if (accessToken != null && isWeb) {
        // On web, send accessToken as fallback
        body['accessToken'] = accessToken;
      }

      if (role != null) {
        body['role'] = role.name;
      }

      debugPrint('📤 Sending Google auth request to backend...');
      debugPrint('📝 Request body keys: ${body.keys.join(", ")}');
      debugPrint('🌐 Is Web: $isWeb');

      final response = await _apiService.post(
        ApiConstants.googleAuth,
        body: body,
      );

      debugPrint('✅ Backend response received');

      final authResponse = GoogleAuthResponse.fromJson(response);

      // Save tokens
      await TokenService.saveTokens(
        accessToken: authResponse.accessToken,
        refreshToken: authResponse.refreshToken,
        userId: authResponse.user.id,
      );

      debugPrint('✅ Tokens saved successfully');
      debugPrint('👤 User: ${authResponse.user.email}');
      debugPrint('🆕 Is new user: ${authResponse.isNewUser}');

      return authResponse;
    } on ApiException catch (e) {
      debugPrint('❌ Backend error: ${e.message}');
      
      // Check if the error is because role is required for new users
      if (e.message.contains('Role is required') ||
          e.message.contains('role is required')) {
        debugPrint('⚠️ Role required for new user');
        throw RoleRequiredException(
          idToken: idToken ?? '',
          email: email ?? '',
          displayName: displayName,
          photoUrl: photoUrl,
        );
      }
      rethrow;
    } catch (e) {
      debugPrint('❌ Unexpected error during backend auth: $e');
      rethrow;
    }
  }

  /// Complete Google sign-up with role for new users
  Future<GoogleAuthResponse> completeGoogleSignUp({
    required String idToken,
    required UserRole role,
  }) async {
    debugPrint('🔵 Completing Google sign-up with role: ${role.name}');
    return await authenticateWithBackend(idToken: idToken, role: role);
  }

  /// Sign out from Google
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      debugPrint('✅ Google sign-out successful');
    } catch (e) {
      debugPrint('❌ Google sign-out error: $e');
    }
  }

  /// Disconnect Google account (revoke access)
  Future<void> disconnect() async {
    try {
      await _googleSignIn.disconnect();
      debugPrint('✅ Google disconnect successful');
    } catch (e) {
      debugPrint('❌ Google disconnect error: $e');
    }
  }
}

/// Result from Google Sign-In containing the ID token and user info
class GoogleSignInResult {
  final String? idToken; // Nullable for web
  final String? accessToken;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final bool isWeb;

  GoogleSignInResult({
    this.idToken,
    this.accessToken,
    required this.email,
    this.displayName,
    this.photoUrl,
    required this.isWeb,
  });
}