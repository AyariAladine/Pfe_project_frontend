import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../models/user_model.dart';

class LoginViewModel extends ChangeNotifier {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();

  bool _obscurePassword = true;
  bool _rememberMe = false;
  bool _isGoogleLoading = false;
  
  // Store pending Google sign-up data when role is required
  String? _pendingGoogleIdToken;
  String? _pendingGoogleEmail;
  String? _pendingGoogleDisplayName;
  String? _pendingGooglePhotoUrl;

  bool get obscurePassword => _obscurePassword;
  bool get rememberMe => _rememberMe;
  bool get isGoogleLoading => _isGoogleLoading;
  bool get hasPendingGoogleSignUp => _pendingGoogleIdToken != null;
  String? get pendingGoogleEmail => _pendingGoogleEmail;
  String? get pendingGoogleDisplayName => _pendingGoogleDisplayName;

  String get email => emailController.text.trim();
  String get password => passwordController.text;

  void togglePasswordVisibility() {
    _obscurePassword = !_obscurePassword;
    notifyListeners();
  }

  void toggleRememberMe() {
    _rememberMe = !_rememberMe;
    notifyListeners();
  }

  /// Sign in with Google
  /// Returns GoogleAuthResult which can indicate:
  /// - success: user is logged in
  /// - cancelled: user cancelled the flow
  /// - roleRequired: new user needs to select a role
  Future<GoogleAuthResult> signInWithGoogle() async {
    _isGoogleLoading = true;
    notifyListeners();
    
    try {
      final result = await _authService.signInWithGoogle();
      
      // If role is required, store the pending data
      if (result.needsRole) {
        _pendingGoogleIdToken = result.idToken;
        _pendingGoogleEmail = result.email;
        _pendingGoogleDisplayName = result.displayName;
        _pendingGooglePhotoUrl = result.photoUrl;
      }
      
      return result;
    } finally {
      _isGoogleLoading = false;
      notifyListeners();
    }
  }

  /// Complete Google sign-up with the selected role
  Future<GoogleAuthResult> completeGoogleSignUp(UserRole role) async {
    if (_pendingGoogleIdToken == null) {
      throw Exception('No pending Google sign-up');
    }
    
    _isGoogleLoading = true;
    notifyListeners();
    
    try {
      final result = await _authService.completeGoogleSignUp(
        idToken: _pendingGoogleIdToken!,
        role: role,
      );
      
      // Clear pending data on success
      if (result.isSuccess) {
        clearPendingGoogleSignUp();
      }
      
      return result;
    } finally {
      _isGoogleLoading = false;
      notifyListeners();
    }
  }

  /// Clear pending Google sign-up data
  void clearPendingGoogleSignUp() {
    _pendingGoogleIdToken = null;
    _pendingGoogleEmail = null;
    _pendingGoogleDisplayName = null;
    _pendingGooglePhotoUrl = null;
    notifyListeners();
  }

  bool validateForm() {
    return formKey.currentState?.validate() ?? false;
  }

  void clearForm() {
    emailController.clear();
    passwordController.clear();
    _obscurePassword = true;
    _rememberMe = false;
    notifyListeners();
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}
