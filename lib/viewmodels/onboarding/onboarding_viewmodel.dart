import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import '../../core/constants/api_constants.dart';
import 'package:pfe_project/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/ocr_service.dart';
import '../../services/auth_service.dart';
import '../../services/otp_service.dart';
import '../../services/token_service.dart';

enum OnboardingStep {
  welcome,
  cinFrontScan,
  cinBackScan,
  phoneVerification,
  biometrics,
  complete,
}

class OnboardingViewModel extends ChangeNotifier {
  OnboardingStep _currentStep = OnboardingStep.welcome;
  bool _isLoading = false;
  String? _error;
  
  // CIN Data
  String? _cinNumber;
  Map<String, dynamic>? _frontIdCardData;
  Map<String, dynamic>? _backIdCardData;
  bool _frontInfoConfirmed = false;
  bool _backInfoConfirmed = false;
  bool _finalIdVerificationConfirmed = false;
  bool _cinVerified = false;
  bool _existingCinFromProfile = false;
  
  // Phone verification
  String? _phoneNumber;
  bool _phoneVerified = false;
  bool _otpSent = false;
  
  // Biometrics
  bool _biometricsEnabled = false;
  bool _biometricsAvailable = false;
  List<BiometricType> _availableBiometrics = [];
  
  // Loading state for initial check
  bool _initialLoading = true;
  Map<String, dynamic>? _lastSubmittedPayload;
  
  final LocalAuthentication _localAuth = LocalAuthentication();
  final ApiService _apiService = ApiService();
  final OcrService _ocrService = OcrService();
  final AuthService _authService = AuthService();
  final OtpService _otpService = OtpService();

  // ── field schema constants ──────────────────────────────────────────────────

  /// Backend/debug keys that are never meaningful to display or submit.
  static const _metaKeys = {
    'missingFields', 'confidenceHints', 'rawText', 'source', 'ocrConfidence',
  };

  /// Canonical field order for the front-side card.
  static const _frontSchema = [
    'identityNumber', 'lastName', 'firstName', 'fullName',
    'dateOfBirth', 'placeOfBirth', 'lineage',
  ];

  /// Canonical field order for the back-side card.
  static const _backSchema = [
    'address',
    'issueDate',
  ];

  // Getters
  OnboardingStep get currentStep => _currentStep;
  bool get isLoading => _isLoading;
  bool get initialLoading => _initialLoading;
  String? get error => _error;
  String? get cinNumber => _cinNumber;
  bool get cinVerified => _cinVerified;
  Map<String, dynamic>? get frontIdCardData => _frontIdCardData;
  Map<String, dynamic>? get backIdCardData => _backIdCardData;

  /// Clean extracted fields restricted to the canonical schema, with no meta/
  /// garbage keys and no empty values. Used when submitting data to the API.
  Map<String, dynamic> get frontExtractedFields =>
      _extractSchemaFields(_frontIdCardData, _frontSchema);
  Map<String, dynamic> get backExtractedFields =>
      _extractSchemaFields(_backIdCardData, _backSchema);

  /// All schema fields, pre-populated with extracted values (empty string if
  /// not yet extracted). Used to drive the editable review cards so the user
  /// always sees every expected field and can fill in what OCR missed.
  Map<String, dynamic> get frontDisplayFields =>
      _buildDisplayFields(_frontIdCardData, _frontSchema);
  Map<String, dynamic> get backDisplayFields =>
      _buildDisplayFields(_backIdCardData, _backSchema);
  bool get hasFrontIdCard => _frontIdCardData != null;
  bool get hasBackIdCard => _backIdCardData != null;

  /// Per-field OCR confidences (0.0–1.0) from the Gemini backend.
  Map<String, double> get frontFieldConfidences =>
      _confidencesFrom(_frontIdCardData);
  Map<String, double> get backFieldConfidences =>
      _confidencesFrom(_backIdCardData);

  /// Fields where model confidence < 0.55 — shown with a warning icon in the
  /// review form so the user knows to double-check before confirming.
  Set<String> get lowConfidenceFrontFields =>
      _lowConfidenceKeys(frontFieldConfidences);
  Set<String> get lowConfidenceBackFields =>
      _lowConfidenceKeys(backFieldConfidences);

  /// True when the backend flagged the front scan as needing manual review.
  bool get frontRequiresManualReview =>
      _frontIdCardData?['requiresManualReview'] == true;
  bool get backRequiresManualReview =>
      _backIdCardData?['requiresManualReview'] == true;
    bool get frontInfoConfirmed => _frontInfoConfirmed;
    bool get backInfoConfirmed => _backInfoConfirmed;
    bool get finalIdVerificationConfirmed => _finalIdVerificationConfirmed;
    bool get canCaptureBackSide => _existingCinFromProfile || _frontInfoConfirmed;
    bool get canReviewCombinedIdData => _existingCinFromProfile ||
      (hasFrontIdCard && hasBackIdCard && _frontInfoConfirmed && _backInfoConfirmed);
  bool get hasCompleteIdCardData =>
      _existingCinFromProfile || (hasFrontIdCard && hasBackIdCard);
  Map<String, dynamic> get extractedIdCardFields => _buildCombinedIdCardFields();
  Map<String, dynamic>? get lastSubmittedPayload => _lastSubmittedPayload;
  String get idCardCaptureSummary {
    if (_existingCinFromProfile && !hasFrontIdCard && !hasBackIdCard) {
      return 'Existing verification';
    }
    final front = hasFrontIdCard ? 'Front' : 'Missing front';
    final back = hasBackIdCard ? 'Back' : 'Missing back';
    return '$front / $back';
  }
  bool get biometricsEnabled => _biometricsEnabled;
  bool get biometricsAvailable => _biometricsAvailable;
  List<BiometricType> get availableBiometrics => _availableBiometrics;
  String? get phoneNumber => _phoneNumber;
  bool get phoneVerified => _phoneVerified;
  bool get otpSent => _otpSent;
  bool get allComplete =>
      _phoneVerified && _cinVerified && (_biometricsEnabled || kIsWeb);

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
      final userId = user.id;

      _phoneNumber = user.phoneNumber;

      // Phone is verified if the backend profile has a non-empty phone number
      // (the OTP verify endpoint already persists this server-side).
      _phoneVerified = user.phoneNumber.isNotEmpty;

      // Pre-fill CIN number from profile if it looks valid, but do NOT mark
      // as verified yet — the verification document is the source of truth.
      if (user.identityNumber.isNotEmpty &&
          user.identityNumber != '00000000' &&
          user.identityNumber.length == 8) {
        _cinNumber = user.identityNumber;
      }

      // Always check the verification document regardless of profile CIN state.
      await _loadVerificationProgress(userId);

      _updateCinVerificationState();
      
      // Biometrics is device-local — keep in SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      _biometricsEnabled = prefs.getBool('biometrics_enabled_$userId') ?? false;
      
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

  /// Save biometrics enabled state locally (scoped by user ID)
  Future<void> _saveBiometricsState(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = await TokenService.getUserId();
    if (userId == null) return;
    await prefs.setBool('biometrics_enabled_$userId', enabled);
  }

  /// Load verification progress from backend so onboarding can resume.
  /// If the document is missing or not started, resets all CIN state so the
  /// user is taken back through the full CIN scan flow.
  Future<void> _loadVerificationProgress(String userId) async {
    try {
      final data = await _apiService.get(
        ApiConstants.verification(userId),
        requiresAuth: true,
      );
      if (data is! Map<String, dynamic>) {
        _resetCinState();
        return;
      }

      final status = data['status']?.toString() ?? 'not_started';

      if (status == 'not_started') {
        _resetCinState();
        return;
      }

      // Restore CIN number from document (overrides profile value if present)
      final cin = data['identityNumber']?.toString();
      if (cin != null && cin.length == 8 && RegExp(r'^\d{8}$').hasMatch(cin)) {
        _cinNumber = cin;
      }

      // Restore front data
      if (data['frontData'] is Map<String, dynamic>) {
        _frontIdCardData = {
          'side': 'front',
          'extractedFields': data['frontData'],
          'rawText': data['frontRawText'],
        };
      }
      _frontInfoConfirmed = data['frontConfirmed'] == true;

      // Restore back data
      if (data['backData'] is Map<String, dynamic>) {
        _backIdCardData = {
          'side': 'back',
          'extractedFields': data['backData'],
          'rawText': data['backRawText'],
        };
      }
      _backInfoConfirmed = data['backConfirmed'] == true;

      _finalIdVerificationConfirmed = data['finalConfirmed'] == true;

      if (data['phoneVerified'] == true) {
        _phoneVerified = true;
      }

      // Only mark as fully verified if the document says so
      if (status == 'verified') {
        _existingCinFromProfile = true;
      }
    } catch (e) {
      // 404 = document was deleted — treat as not started
      _resetCinState();
    }
  }

  void _resetCinState() {
    _existingCinFromProfile = false;
    _frontInfoConfirmed = false;
    _backInfoConfirmed = false;
    _finalIdVerificationConfirmed = false;
    _frontIdCardData = null;
    _backIdCardData = null;
    _cinVerified = false;
  }

  void nextStep() {
    _currentStep = _nextIncompleteStep(_currentStep);
    notifyListeners();
  }

  /// Find the next step that hasn't been completed yet.
  /// If all are done, go to complete.
  OnboardingStep _nextIncompleteStep(OnboardingStep from) {
    final order = [
      OnboardingStep.cinFrontScan,
      OnboardingStep.cinBackScan,
      OnboardingStep.phoneVerification,
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
      case OnboardingStep.cinFrontScan:
        return _existingCinFromProfile || _frontInfoConfirmed;
      case OnboardingStep.cinBackScan:
        return _cinVerified;
      case OnboardingStep.phoneVerification:
        return _phoneVerified;
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
      case OnboardingStep.cinFrontScan:
        _currentStep = OnboardingStep.welcome;
        break;
      case OnboardingStep.cinBackScan:
        _currentStep = OnboardingStep.cinFrontScan;
        break;
      case OnboardingStep.phoneVerification:
        _currentStep = OnboardingStep.cinBackScan;
        break;
      case OnboardingStep.biometrics:
        _currentStep = OnboardingStep.phoneVerification;
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
  Future<void> scanFrontIdCardFromCamera() async {
    await _scanIdCard(side: 'front', fromCamera: true);
  }

  Future<void> scanFrontIdCardFromGallery() async {
    await _scanIdCard(side: 'front', fromCamera: false);
  }

  Future<void> scanBackIdCardFromCamera() async {
    await _scanIdCard(side: 'back', fromCamera: true);
  }

  Future<void> scanBackIdCardFromGallery() async {
    await _scanIdCard(side: 'back', fromCamera: false);
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
    _error = null;
    notifyListeners();
  }

  Future<void> _scanIdCard({
    required String side,
    required bool fromCamera,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final scanData = await _ocrService.scanIdentityCardData(
        side: side,
        fromCamera: fromCamera,
      );

      if (scanData == null) {
        _error = 'Could not read text from image. Please try again.';
      } else if (scanData['error'] != null) {
        _error = scanData['error'].toString();
      } else {
        if (side == 'front') {
          _frontIdCardData = scanData;
          _frontInfoConfirmed = false;
        } else {
          _backIdCardData = scanData;
          _backInfoConfirmed = false;
        }
        _finalIdVerificationConfirmed = false;

        final combinedFields = _buildCombinedIdCardFields();
        final identityNumber = combinedFields['identityNumber']?.toString();
        if (identityNumber != null &&
            identityNumber.length == 8 &&
            RegExp(r'^\d{8}$').hasMatch(identityNumber)) {
          _cinNumber = identityNumber;
        }

        final hasUsableData = combinedFields.isNotEmpty ||
            (scanData['rawText']?.toString().trim().isNotEmpty ?? false);
        if (!hasUsableData) {
          _error = 'Could not detect data from the ID card. Please try again.';
        } else {
          _error = null;
        }
      }

      _updateCinVerificationState();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Error scanning ID card: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  void setCinManually(String cin) {
    if (cin.length == 8 && RegExp(r'^\d{8}$').hasMatch(cin)) {
      _cinNumber = cin;
      _finalIdVerificationConfirmed = false;
      _updateCinVerificationState();
      _error = null;
    } else {
      _error = 'CIN must be exactly 8 digits';
      _finalIdVerificationConfirmed = false;
      _updateCinVerificationState();
    }
    notifyListeners();
  }

  Future<void> confirmFrontIdCardInfo() async {
    if (!hasFrontIdCard) {
      _error = 'Please upload the front side first.';
      notifyListeners();
      return;
    }
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final user = await _authService.getProfile();
      final frontPayload = {
        ...frontExtractedFields,
        if (_cinNumber != null) 'identityNumber': _cinNumber,
      };
      debugPrint('=== FRONT CONFIRM PAYLOAD ===');
      frontPayload.forEach((k, v) => debugPrint('  $k: $v'));
      debugPrint('=============================');
      await _apiService.patch(
        ApiConstants.verificationFrontConfirm(user.id),
        body: frontPayload,
        requiresAuth: true,
      );

      _frontInfoConfirmed = true;
      _finalIdVerificationConfirmed = false;
      _updateCinVerificationState();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to confirm front data: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> confirmBackIdCardInfo() async {
    if (!hasBackIdCard) {
      _error = 'Please upload the back side first.';
      notifyListeners();
      return;
    }
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final user = await _authService.getProfile();
      debugPrint('=== BACK CONFIRM PAYLOAD ===');
      backExtractedFields.forEach((k, v) => debugPrint('  $k: $v'));
      debugPrint('============================');
      await _apiService.patch(
        ApiConstants.verificationBackConfirm(user.id),
        body: backExtractedFields,
        requiresAuth: true,
      );

      _backInfoConfirmed = true;
      _finalIdVerificationConfirmed = false;
      _updateCinVerificationState();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to confirm back data: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> verifyCollectedIdCardInfo() async {
    if (!canReviewCombinedIdData) {
      _error = 'Please confirm the front and back information first.';
      notifyListeners();
      return;
    }

    final hasValidCin = _cinNumber != null &&
        _cinNumber!.length == 8 &&
        RegExp(r'^\d{8}$').hasMatch(_cinNumber!);
    if (!hasValidCin) {
      _error = 'The CIN number is missing or invalid.';
      _finalIdVerificationConfirmed = false;
      _updateCinVerificationState();
      notifyListeners();
      return;
    }

    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final user = await _authService.getProfile();
      await _apiService.patch(
        ApiConstants.verificationFinalize(user.id),
        body: {
          'identityNumber': _cinNumber,
        },
        requiresAuth: true,
      );

      _finalIdVerificationConfirmed = true;
      _updateCinVerificationState();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to finalize verification: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Correct a single extracted field on the front side.
  /// Resets the front-confirmed flag so the user must re-confirm.
  void updateFrontExtractedField(String key, String value) {
    if (_frontIdCardData == null) return;
    final fields = Map<String, dynamic>.from(
      (_frontIdCardData!['extractedFields'] as Map?)?.cast<String, dynamic>() ?? {},
    );
    if (value.trim().isEmpty) {
      fields.remove(key);
    } else {
      fields[key] = value.trim();
    }
    _frontIdCardData = {..._frontIdCardData!, 'extractedFields': fields};
    _frontInfoConfirmed = false;
    _finalIdVerificationConfirmed = false;
    if (key == 'identityNumber') _refreshCombinedCin();
    _updateCinVerificationState();
    notifyListeners();
  }

  /// Correct a single extracted field on the back side.
  void updateBackExtractedField(String key, String value) {
    if (_backIdCardData == null) return;
    final fields = Map<String, dynamic>.from(
      (_backIdCardData!['extractedFields'] as Map?)?.cast<String, dynamic>() ?? {},
    );
    if (value.trim().isEmpty) {
      fields.remove(key);
    } else {
      fields[key] = value.trim();
    }
    _backIdCardData = {..._backIdCardData!, 'extractedFields': fields};
    _backInfoConfirmed = false;
    _finalIdVerificationConfirmed = false;
    _updateCinVerificationState();
    notifyListeners();
  }

  void clearFrontIdCard() {
    _frontIdCardData = null;
    _frontInfoConfirmed = false;
    _finalIdVerificationConfirmed = false;
    _refreshCombinedCin();
    _error = null;
    notifyListeners();
  }

  void clearBackIdCard() {
    _backIdCardData = null;
    _backInfoConfirmed = false;
    _finalIdVerificationConfirmed = false;
    _refreshCombinedCin();
    _error = null;
    notifyListeners();
  }

  void clearCin() {
    _frontIdCardData = null;
    _backIdCardData = null;
    _frontInfoConfirmed = false;
    _backInfoConfirmed = false;
    _finalIdVerificationConfirmed = false;
    _cinNumber = null;
    _existingCinFromProfile = false;
    _cinVerified = false;
    _error = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<Map<String, dynamic>> submitOnboardingData() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final user = await _authService.getProfile();
      final payload = getOnboardingData();

      // Update basic user profile fields (phone, CIN).
      // Verification data is already persisted via the
      // front-confirm / back-confirm / finalize endpoints.
      final requestBody = <String, dynamic>{
        if (_phoneNumber != null && _phoneNumber!.isNotEmpty)
          'phoneNumber': _phoneNumber,
        if (_cinNumber != null && _cinNumber!.isNotEmpty)
          'identitynumber': _cinNumber,
      };

      if (requestBody.isNotEmpty) {
        await _apiService.patch(
          ApiConstants.userProfile(user.id),
          body: requestBody,
          requiresAuth: true,
        );
      }

      _lastSubmittedPayload = payload;
      if (_cinNumber != null && _cinNumber!.isNotEmpty) {
        _existingCinFromProfile = true;
      }
      _updateCinVerificationState();
      _isLoading = false;
      notifyListeners();
      return payload;
    } catch (e) {
      _error = 'Failed to submit onboarding data: $e';
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  void _refreshCombinedCin() {
    final combinedFields = _buildCombinedIdCardFields();
    final identityNumber = combinedFields['identityNumber']?.toString();
    if (!_existingCinFromProfile) {
      _cinNumber = identityNumber;
    }
    _updateCinVerificationState();
  }

  Map<String, dynamic> _buildCombinedIdCardFields() {
    final combined = <String, dynamic>{};

    void mergeSideData(Map<String, dynamic>? sideData) {
      if (sideData == null) return;
      final fields = sideData['extractedFields'];
      if (fields is! Map) return;

      for (final entry in fields.entries) {
        final value = entry.value;
        if (value == null || value.toString().trim().isEmpty) continue;
        combined[entry.key.toString()] = value;
      }
    }

    mergeSideData(_frontIdCardData);
    mergeSideData(_backIdCardData);

    if (_cinNumber != null && _cinNumber!.isNotEmpty) {
      combined['identityNumber'] = _cinNumber;
    }

    return combined;
  }

  /// Like _extractCleanFields but further restricts keys to the given schema.
  /// Prevents extra OCR fields (e.g. barcodeNumber) from reaching the backend.
  Map<String, dynamic> _extractSchemaFields(
    Map<String, dynamic>? sideData,
    List<String> schema,
  ) {
    final clean = _extractCleanFields(sideData);
    return Map.fromEntries(
      clean.entries.where((e) => schema.contains(e.key)),
    );
  }

  /// Clean extracted fields: removes meta/debug keys and empty values only.
  /// Arabic characters are intentionally kept — they are valid CIN data.
  Map<String, dynamic> _extractCleanFields(Map<String, dynamic>? sideData) {
    if (sideData == null) return const {};
    final fields = sideData['extractedFields'];
    if (fields is! Map) return const {};
    return Map.fromEntries(
      fields.entries.where((e) {
        final key = e.key.toString();
        final value = e.value?.toString() ?? '';
        return !_metaKeys.contains(key) && value.trim().isNotEmpty;
      }).map((e) => MapEntry(e.key.toString(), e.value)),
    );
  }

  /// All schema fields in canonical order, pre-populated with clean extracted
  /// values (empty string when not yet extracted). Drives the editable cards.
  Map<String, dynamic> _buildDisplayFields(
    Map<String, dynamic>? sideData,
    List<String> schema,
  ) {
    final result = Map<String, dynamic>.fromEntries(
      schema.map((k) => MapEntry(k, '')),
    );
    if (sideData == null) return result;
    final clean = _extractCleanFields(sideData);
    for (final key in schema) {
      if (clean.containsKey(key)) result[key] = clean[key];
    }
    return result;
  }

  Map<String, double> _confidencesFrom(Map<String, dynamic>? sideData) {
    final raw = sideData?['fieldConfidences'];
    if (raw is! Map) return {};
    return Map.fromEntries(
      raw.entries.map(
        (e) => MapEntry(e.key.toString(), (e.value as num?)?.toDouble() ?? 0.0),
      ),
    );
  }

  Set<String> _lowConfidenceKeys(Map<String, double> confidences) =>
      confidences.entries
          .where((e) => e.value < 0.55)
          .map((e) => e.key)
          .toSet();

  void _updateCinVerificationState() {
    final hasValidCin = _cinNumber != null &&
        _cinNumber!.length == 8 &&
        RegExp(r'^\d{8}$').hasMatch(_cinNumber!);
    _cinVerified = _existingCinFromProfile ||
        (_frontInfoConfirmed &&
            _backInfoConfirmed &&
            _finalIdVerificationConfirmed &&
            hasValidCin);
  }

  // Get all collected data for API submission
  Map<String, dynamic> getOnboardingData() {
    return {
      'phoneNumber': _phoneNumber,
      'phoneVerified': _phoneVerified,
      'cinNumber': _cinNumber,
      'cinVerified': _cinVerified,
      'biometricsEnabled': _biometricsEnabled,
      'idCard': {
        'frontCaptured': hasFrontIdCard,
        'backCaptured': hasBackIdCard,
        'captureSummary': idCardCaptureSummary,
        'verificationReady': hasCompleteIdCardData,
        'identityNumber': _cinNumber,
        'combinedFields': _buildCombinedIdCardFields(),
        'front': _frontIdCardData,
        'back': _backIdCardData,
      },
    };
  }
}
