import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/ocr_service.dart';
import '../../services/auth_service.dart';

enum OnboardingStep {
  welcome,
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
  
  // Biometrics
  bool _biometricsEnabled = false;
  bool _biometricsAvailable = false;
  List<BiometricType> _availableBiometrics = [];
  
  // Device Info
  String? _deviceId;
  String? _deviceModel;
  String? _devicePlatform;
  
  // Loading state for initial check
  bool _initialLoading = true;
  
  final LocalAuthentication _localAuth = LocalAuthentication();
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  final OcrService _ocrService = OcrService();
  final AuthService _authService = AuthService();

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
  String? get deviceId => _deviceId;
  String? get deviceModel => _deviceModel;
  String? get devicePlatform => _devicePlatform;

  OnboardingViewModel() {
    _initialize();
  }

  Future<void> _initialize() async {
    _initialLoading = true;
    notifyListeners();
    
    await _initDeviceInfo();
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
      
      debugPrint('User identity number: "${user.identityNumber}"');
      debugPrint('Identity number length: ${user.identityNumber.length}');
      
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
      final prefs = await SharedPreferences.getInstance();
      _biometricsEnabled = prefs.getBool('biometrics_enabled') ?? false;
      
      debugPrint('Biometrics enabled: $_biometricsEnabled');
      
      // Determine which step to start from
      if (_cinVerified && _biometricsEnabled) {
        // All done - go to complete
        _currentStep = OnboardingStep.complete;
        debugPrint('Skipping to complete step');
      } else if (_cinVerified) {
        // CIN done, skip to biometrics
        _currentStep = OnboardingStep.biometrics;
        debugPrint('Skipping to biometrics step');
      } else {
        debugPrint('Starting from welcome step');
      }
      // Otherwise start from welcome
      
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
    switch (_currentStep) {
      case OnboardingStep.welcome:
        _currentStep = OnboardingStep.cinScan;
        break;
      case OnboardingStep.cinScan:
        _currentStep = OnboardingStep.biometrics;
        break;
      case OnboardingStep.biometrics:
        _currentStep = OnboardingStep.complete;
        break;
      case OnboardingStep.complete:
        break;
    }
    notifyListeners();
  }

  void previousStep() {
    switch (_currentStep) {
      case OnboardingStep.welcome:
        break;
      case OnboardingStep.cinScan:
        _currentStep = OnboardingStep.welcome;
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

  // Device Info
  Future<void> _initDeviceInfo() async {
    try {
      if (kIsWeb) {
        // On web, generate a simple device ID from timestamp
        _deviceId = 'web_${DateTime.now().millisecondsSinceEpoch}';
        _deviceModel = 'Web Browser';
        _devicePlatform = 'web';
      } else {
        final deviceData = await _deviceInfo.deviceInfo;
        if (deviceData is AndroidDeviceInfo) {
          _deviceId = deviceData.id;
          _deviceModel = '${deviceData.manufacturer} ${deviceData.model}';
          _devicePlatform = 'android';
        } else if (deviceData is IosDeviceInfo) {
          _deviceId = deviceData.identifierForVendor;
          _deviceModel = deviceData.model;
          _devicePlatform = 'ios';
        } else if (deviceData is WindowsDeviceInfo) {
          _deviceId = deviceData.deviceId;
          _deviceModel = deviceData.computerName;
          _devicePlatform = 'windows';
        } else if (deviceData is MacOsDeviceInfo) {
          _deviceId = deviceData.systemGUID;
          _deviceModel = deviceData.model;
          _devicePlatform = 'macos';
        } else if (deviceData is LinuxDeviceInfo) {
          _deviceId = deviceData.machineId;
          _deviceModel = deviceData.prettyName;
          _devicePlatform = 'linux';
        }
      }
      notifyListeners();
    } catch (e) {
      // Fallback for any platform issues
      debugPrint('Error getting device info: $e');
      _deviceId = 'unknown_${DateTime.now().millisecondsSinceEpoch}';
      _deviceModel = 'Unknown Device';
      _devicePlatform = kIsWeb ? 'web' : 'unknown';
      notifyListeners();
    }
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
          biometricOnly: true,
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
      'cinNumber': _cinNumber,
      'cinVerified': _cinVerified,
      'biometricsEnabled': _biometricsEnabled,
      'deviceId': _deviceId,
      'deviceModel': _deviceModel,
      'devicePlatform': _devicePlatform,
    };
  }
}
