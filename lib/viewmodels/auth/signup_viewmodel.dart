import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';

class SignupViewModel extends ChangeNotifier {
  // Controllers for all required backend fields
  final TextEditingController nameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreeToTerms = false;
  bool _isGoogleLoading = false;
  UserRole? _selectedUserRole;
  int _currentStep = 0;
  
  // Store pending Google sign-up data when role is required
  String? _pendingGoogleIdToken;
  String? _pendingGoogleEmail;
  String? _pendingGoogleDisplayName;
  String? _pendingGooglePhotoUrl;

  bool get obscurePassword => _obscurePassword;
  bool get obscureConfirmPassword => _obscureConfirmPassword;
  bool get agreeToTerms => _agreeToTerms;
  bool get isGoogleLoading => _isGoogleLoading;
  UserRole? get selectedUserRole => _selectedUserRole;
  int get currentStep => _currentStep;
  bool get hasPendingGoogleSignUp => _pendingGoogleIdToken != null;
  String? get pendingGoogleEmail => _pendingGoogleEmail;
  String? get pendingGoogleDisplayName => _pendingGoogleDisplayName;
  String? get pendingGooglePhotoUrl => _pendingGooglePhotoUrl;

  // Getters for form values
  String get name => nameController.text.trim();
  String get lastName => lastNameController.text.trim();
  String get email => emailController.text.trim();
  String get phone => phoneController.text.trim();
  String get password => passwordController.text;
  String get confirmPassword => confirmPasswordController.text;
  String get fullName => '$name $lastName';

  /// Sign up with Google
  /// Returns GoogleAuthResult which can indicate:
  /// - success: user is logged in (existing user)
  /// - cancelled: user cancelled the flow
  /// - roleRequired: new user needs to select a role
  Future<GoogleAuthResult> signUpWithGoogle() async {
    _isGoogleLoading = true;
    notifyListeners();
    
    try {
      // If we already have a selected role, use it
      final result = await _authService.signInWithGoogle(role: _selectedUserRole);
      
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

  void togglePasswordVisibility() {
    _obscurePassword = !_obscurePassword;
    notifyListeners();
  }

  void toggleConfirmPasswordVisibility() {
    _obscureConfirmPassword = !_obscureConfirmPassword;
    notifyListeners();
  }

  void toggleAgreeToTerms() {
    _agreeToTerms = !_agreeToTerms;
    notifyListeners();
  }

  void setUserRole(UserRole role) {
    _selectedUserRole = role;
    notifyListeners();
  }

  void setCurrentStep(int step) {
    _currentStep = step;
    notifyListeners();
  }

  void nextStep() {
    if (_currentStep < 1) {
      _currentStep++;
      notifyListeners();
    }
  }

  void previousStep() {
    if (_currentStep > 0) {
      _currentStep--;
      notifyListeners();
    }
  }

  bool validateForm() {
    return formKey.currentState?.validate() ?? false;
  }

  bool canProceedFromStep1() {
    return _selectedUserRole != null;
  }

  void clearForm() {
    nameController.clear();
    lastNameController.clear();
    emailController.clear();
    phoneController.clear();
    passwordController.clear();
    confirmPasswordController.clear();
    _obscurePassword = true;
    _obscureConfirmPassword = true;
    _agreeToTerms = false;
    _selectedUserRole = null;
    _currentStep = 0;
    notifyListeners();
  }

  @override
  void dispose() {
    nameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }
}
