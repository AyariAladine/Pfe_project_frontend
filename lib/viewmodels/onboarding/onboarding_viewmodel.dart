import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:pfe_project/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/ocr_service.dart';
import '../../services/auth_service.dart';
import '../../services/otp_service.dart';

enum OnboardingStep {
  welcome,
  phoneVerification,
  cinScan,
  biometrics,
  complete,
}

class OnboardingViewModel extends ChangeNotifier {
  OnboardingStep _currentStep = OnboardingStep.welcome;
  bool _isLoading = false;
  String? _error;
  
  // CIN Data
  String? _cinNumber;
  String? _cinImagePath;
  bool _cinVerified = false;
  
  // Phone verification
  String? _phoneNumber;
  bool _phoneVerified = false;
  bool _otpSent = false;
  String? _otpCode;
  
  // Biometrics
  bool _biometricsEnabled = false;
  bool _biometricsAvailable = false;
  List<BiometricType> _availableBiometrics = [];
  
  // Loading state for initial check
  bool _initialLoading = true;
  
  final LocalAuthentication _localAuth = LocalAuthentication();
  final OcrService _ocrService = OcrService();
  final AuthService _authService = AuthService();
  final OtpService _otpService = OtpService();

  // Getters
  OnboardingStep get currentStep => _currentStep;
  bool get isLoading => _isLoading;
  bool get initialLoading => _initialLoading;
  String? get error => _error;
  String? get cinNumber => _cinNumber;
  String? get cinImagePath => _cinImagePath;
  bool get cinVerified => _cinVerified;
  bool get biometricsEnabled => _biometricsEnabled;
  bool get biometricsAvailable => _biometricsAvailable;
  List<BiometricType> get availableBiometrics => _availableBiometrics;
  String? get phoneNumber => _phoneNumber;
  bool get phoneVerified => _phoneVerified;
  bool get otpSent => _otpSent;
  bool get allComplete => _phoneVerified && _cinVerified && (_biometricsEnabled || kIsWeb);

  OnboardingViewModel() {
    _initialize();
  }

  Future<void> _initialize() async {
    _initialLoading = true;
    notifyListeners();
    
    await _checkBiometrics();
    await _checkExistingProgress();
    
    _initialLoading = false;
    notifyListeners();
  }

  /// Check if user has already completed some steps
  Future<void> _checkExistingProgress() async {
    try {
      // Get user profile to check if CIN is already set
      final user = await _authService.getProfile();
      
      // Check if phone is already verified (stored locally after OTP success)
      final prefs = await SharedPreferences.getInstance();
      _phoneVerified = prefs.getBool('phone_verified') ?? false;
      _phoneNumber = user.phoneNumber;
      
      debugPrint('Phone verified: $_phoneVerified');
      
      // Check if CIN is already verified (not empty and not placeholder)
      if (user.identityNumber.isNotEmpty && 
          user.identityNumber != '00000000' &&
          user.identityNumber.length == 8) {
        _cinNumber = user.identityNumber;
        _cinVerified = true;
        debugPrint('CIN verified: $_cinNumber');
      } else {
        debugPrint('CIN not verified - empty or placeholder');
      }
      
      // Check if biometrics were previously enabled (stored locally)
      _biometricsEnabled = prefs.getBool('biometrics_enabled') ?? false;
      
      debugPrint('Biometrics enabled: $_biometricsEnabled');
      
      // Determine which step to start from — jump to first incomplete
      if (_phoneVerified && _cinVerified && (_biometricsEnabled || kIsWeb)) {
        _currentStep = OnboardingStep.complete;
        debugPrint('All steps done — showing summary');
      } else {
        // Start from welcome, nextStep() will skip completed ones
        _currentStep = OnboardingStep.welcome;
        debugPrint('Starting from welcome, will skip completed steps');
      }
      
    } catch (e) {
      debugPrint('Error checking existing progress: $e');
      // Start from beginning if there's an error
    }
  }

  /// Save biometrics enabled state locally
  Future<void> _saveBiometricsState(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('biometrics_enabled', enabled);
  }

  void nextStep() {
    _currentStep = _nextIncompleteStep(_currentStep);
    notifyListeners();
  }

  /// Find the next step that hasn't been completed yet.
  /// If all are done, go to complete.
  OnboardingStep _nextIncompleteStep(OnboardingStep from) {
    final order = [
      OnboardingStep.phoneVerification,
      OnboardingStep.cinScan,
      OnboardingStep.biometrics,
      OnboardingStep.complete,
    ];

    // Start searching from the step after `from`
    final fromIndex = order.indexOf(from);
    final startIndex = fromIndex < 0 ? 0 : fromIndex + 1;

    for (var i = startIndex; i < order.length; i++) {
      final step = order[i];
      if (!_isStepDone(step)) return step;
    }
    return OnboardingStep.complete;
  }

  bool _isStepDone(OnboardingStep step) {
    switch (step) {
      case OnboardingStep.welcome:
        return true; // welcome is always "done" once seen
      case OnboardingStep.phoneVerification:
        return _phoneVerified;
      case OnboardingStep.cinScan:
        return _cinVerified;
      case OnboardingStep.biometrics:
        return _biometricsEnabled || kIsWeb;
      case OnboardingStep.complete:
        return false; // always show summary
    }
  }

  void previousStep() {
    switch (_currentStep) {
      case OnboardingStep.welcome:
        break;
      case OnboardingStep.phoneVerification:
        _currentStep = OnboardingStep.welcome;
        break;
      case OnboardingStep.cinScan:
        _currentStep = OnboardingStep.phoneVerification;
        break;
      case OnboardingStep.biometrics:
        _currentStep = OnboardingStep.cinScan;
        break;
      case OnboardingStep.complete:
        _currentStep = OnboardingStep.biometrics;
        break;
    }
    notifyListeners();
  }

  void goToStep(OnboardingStep step) {
    _currentStep = step;
    notifyListeners();
  }

  // Biometrics
  Future<void> _checkBiometrics() async {
    if (kIsWeb) {
      _biometricsAvailable = false;
      notifyListeners();
      return;
    }
    
    try {
      _biometricsAvailable = await _localAuth.canCheckBiometrics;
      if (_biometricsAvailable) {
        _availableBiometrics = await _localAuth.getAvailableBiometrics();
      }
      notifyListeners();
    } on PlatformException catch (e) {
      debugPrint('Biometrics check error: $e');
      _biometricsAvailable = false;
      notifyListeners();
    }
  }

  Future<bool> authenticateWithBiometrics(String reason) async {
    if (kIsWeb || !_biometricsAvailable) {
      _biometricsEnabled = true;
      await _saveBiometricsState(true);
      notifyListeners();
      return true;
    }
    
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final authenticated = await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );

      _biometricsEnabled = authenticated;
      if (authenticated) {
        await _saveBiometricsState(true);
      }
      _isLoading = false;
      notifyListeners();
      return authenticated;
    } on PlatformException catch (e) {
      _error = 'Biometric authentication failed: ${e.message}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Skip biometrics setup
  Future<void> skipBiometrics() async {
    _biometricsEnabled = false;
    await _saveBiometricsState(false);
    notifyListeners();
  }

  // OCR - CIN Scanning
  Future<void> scanCinFromCamera() async {
    await _scanCin(fromCamera: true);
  }

  Future<void> scanCinFromGallery() async {
    await _scanCin(fromCamera: false);
  }

  // ── Phone OTP Verification ──

  /// Send OTP to user's phone number
  Future<bool> sendOtp() async {
    if (_phoneNumber == null || _phoneNumber!.isEmpty) {
      _error = 'Phone number not available';
      notifyListeners();
      return false;
    }
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _otpService.sendOtp(_phoneNumber!);
      _otpSent = true;
      _isLoading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Failed to send code: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Verify the OTP code entered by the user
  Future<bool> verifyOtp(String code) async {
    if (_phoneNumber == null) return false;
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final verified = await _otpService.verifyOtp(_phoneNumber!, code);
      if (verified) {
        _phoneVerified = true;
        _otpCode = code;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('phone_verified', true);
      } else {
        _error = 'Invalid code. Please try again.';
      }
      _isLoading = false;
      notifyListeners();
      return verified;
    } on ApiException catch (e) {
      _error = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Verification failed: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Reset OTP state (e.g. to resend)
  void resetOtp() {
    _otpSent = false;
    _otpCode = null;
    _error = null;
    notifyListeners();
  }

  Future<void> _scanCin({required bool fromCamera}) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Use scanIdentityCard which handles both mobile (ML Kit) and web (backend API)
      final cinNumber = await _ocrService.scanIdentityCard(fromCamera: fromCamera);

      if (cinNumber == null) {
        // User cancelled or no CIN found
        _error = 'Could not read text from image. Please try again.';
        _cinVerified = false;
      } else if (cinNumber.length == 8 && RegExp(r'^\d{8}$').hasMatch(cinNumber)) {
        _cinNumber = cinNumber;
        _cinVerified = true;
        _error = null;
      } else {
        _error = 'Could not detect CIN number. Please try again.';
        _cinVerified = false;
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Error scanning CIN: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  void setCinManually(String cin) {
    if (cin.length == 8 && RegExp(r'^\d{8}$').hasMatch(cin)) {
      _cinNumber = cin;
      _cinVerified = true;
      _error = null;
    } else {
      _error = 'CIN must be exactly 8 digits';
      _cinVerified = false;
    }
    notifyListeners();
  }

  void clearCin() {
    _cinNumber = null;
    _cinImagePath = null;
    _cinVerified = false;
    _error = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Get all collected data for API submission
  Map<String, dynamic> getOnboardingData() {
    return {
      'phoneNumber': _phoneNumber,
      'phoneVerified': _phoneVerified,
      'cinNumber': _cinNumber,
      'cinVerified': _cinVerified,
      'biometricsEnabled': _biometricsEnabled,
    };
  }
}
