import 'package:flutter/material.dart';

enum ForgotPasswordStep {
  enterEmail,
  enterCode,
  enterNewPassword,
}

class ForgotPasswordViewModel extends ChangeNotifier {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController codeController = TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  ForgotPasswordStep _currentStep = ForgotPasswordStep.enterEmail;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  ForgotPasswordStep get currentStep => _currentStep;
  bool get obscurePassword => _obscurePassword;
  bool get obscureConfirmPassword => _obscureConfirmPassword;
  
  String get email => emailController.text.trim();
  String get code => codeController.text.trim();
  String get newPassword => newPasswordController.text;
  String get confirmPassword => confirmPasswordController.text;

  void setStep(ForgotPasswordStep step) {
    _currentStep = step;
    notifyListeners();
  }

  void nextStep() {
    switch (_currentStep) {
      case ForgotPasswordStep.enterEmail:
        _currentStep = ForgotPasswordStep.enterCode;
        break;
      case ForgotPasswordStep.enterCode:
        _currentStep = ForgotPasswordStep.enterNewPassword;
        break;
      case ForgotPasswordStep.enterNewPassword:
        // Already at last step
        break;
    }
    notifyListeners();
  }

  void previousStep() {
    switch (_currentStep) {
      case ForgotPasswordStep.enterEmail:
        // Already at first step
        break;
      case ForgotPasswordStep.enterCode:
        _currentStep = ForgotPasswordStep.enterEmail;
        break;
      case ForgotPasswordStep.enterNewPassword:
        _currentStep = ForgotPasswordStep.enterCode;
        break;
    }
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

  bool validateForm() {
    return formKey.currentState?.validate() ?? false;
  }

  void clearForm() {
    emailController.clear();
    codeController.clear();
    newPasswordController.clear();
    confirmPasswordController.clear();
    _currentStep = ForgotPasswordStep.enterEmail;
    _obscurePassword = true;
    _obscureConfirmPassword = true;
    notifyListeners();
  }

  @override
  void dispose() {
    emailController.dispose();
    codeController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }
}
