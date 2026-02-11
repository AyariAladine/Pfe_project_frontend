import 'package:flutter/material.dart';
import 'package:pfe_project/services/token_service.dart';
import '../../services/auth_service.dart';
import '../../models/user_model.dart' hide GoogleAuthResult;

class LoginViewModel extends ChangeNotifier {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();

  bool _obscurePassword = true;
  bool _isGoogleLoading = false;
  bool _isInitialized = false;
  
  // ⭐ Store pending Google sign-up data when role is required
  String? _pendingGoogleIdToken;
  String? _pendingGoogleAccessToken;  // Added for web support
  String? _pendingGoogleEmail;
  String? _pendingGoogleDisplayName;
  bool? _pendingGoogleIsWeb;  // Track platform

  bool get obscurePassword => _obscurePassword;
  bool get isGoogleLoading => _isGoogleLoading;
  bool get isInitialized => _isInitialized;
  bool get hasPendingGoogleSignUp => _pendingGoogleIdToken != null || _pendingGoogleAccessToken != null;
  String? get pendingGoogleEmail => _pendingGoogleEmail;
  String? get pendingGoogleDisplayName => _pendingGoogleDisplayName;

  String get email => emailController.text.trim();
  String get password => passwordController.text;

  /// Initialize - load saved email if exists
  Future<void> init() async {
    final savedEmail = await TokenService.getSavedEmail();
    if (savedEmail != null && savedEmail.isNotEmpty) {
      emailController.text = savedEmail;
    }
    _isInitialized = true;
    notifyListeners();
  }

  void togglePasswordVisibility() {
    _obscurePassword = !_obscurePassword;
    notifyListeners();
  }

  /// Sign in with Google
  /// Returns GoogleAuthResult which can indicate:
  /// - success: user is logged in
  /// - cancelled: user cancelled the flow
  /// - needsRole: new user needs to select a role
  Future<GoogleAuthResult> signInWithGoogle() async {
    _isGoogleLoading = true;
    notifyListeners();
    
    try {
      final result = await _authService.signInWithGoogle();
      
      // ⭐ If role is required, store the pending data (including accessToken for web)
      if (result.needsRole) {
        _pendingGoogleIdToken = result.idToken;
        _pendingGoogleAccessToken = result.accessToken;
        _pendingGoogleEmail = result.email;
        _pendingGoogleDisplayName = result.displayName;
        _pendingGoogleIsWeb = result.isWeb;
      }
      
      return result;
    } finally {
      _isGoogleLoading = false;
      notifyListeners();
    }
  }

  /// Complete Google sign-up with the selected role
  Future<GoogleAuthResult> completeGoogleSignUp(UserRole role) async {
    if (_pendingGoogleIdToken == null && _pendingGoogleAccessToken == null) {
      throw Exception('No pending Google sign-up');
    }
    
    _isGoogleLoading = true;
    notifyListeners();
    
    try {
      // ⭐ Pass both idToken and accessToken to support both web and mobile
      final result = await _authService.completeGoogleSignUp(
        idToken: _pendingGoogleIdToken,
        accessToken: _pendingGoogleAccessToken,
        role: role,
        isWeb: _pendingGoogleIsWeb,
      );
      
      // Clear pending data on success
      if (result.success) {
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
    _pendingGoogleAccessToken = null;
    _pendingGoogleEmail = null;
    _pendingGoogleDisplayName = null;
    _pendingGoogleIsWeb = null;
    notifyListeners();
  }

  bool validateForm() {
    return formKey.currentState?.validate() ?? false;
  }

  void clearForm() {
    emailController.clear();
    passwordController.clear();
    _obscurePassword = true;
    notifyListeners();
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}