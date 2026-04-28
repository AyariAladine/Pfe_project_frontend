import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/user_model.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../services/face_recognition_service.dart';
import '../../services/signature_service.dart';
import '../../services/lawyer_service.dart';

/// ViewModel for the lawyer profile editing screen
class LawyerProfileViewModel extends ChangeNotifier {
  final LawyerService _lawyerService = LawyerService();
  final ImagePicker _imagePicker = ImagePicker();
  final FaceRecognitionService _faceService = FaceRecognitionService();
  final SignatureService _signatureService = SignatureService();

  UserModel? _lawyer;
  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;
  String? _successMessage;

  // Face recognition state
  bool _faceRegistered = false;
  bool _isFaceProcessing = false;
  String? _faceMessage;
  double? _faceConfidence;

  // Signature state
  String? _signatureUrl;
  bool _isSignatureProcessing = false;
  String? _signatureMessage;

  // Text editing controllers for editable fields
  final TextEditingController nameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController identityNumberController =
      TextEditingController();

  // Selected files (not yet uploaded)
  Uint8List? _pictureBytes;
  String? _pictureFileName;

  // Verification
  bool _isVerifying = false;
  bool? _isVerified;          // null = not checked yet
  String? _verifiedName;      // name returned by scraper on match

  // Location
  double? _latitude;
  double? _longitude;

  // Tracking changes
  bool _hasChanges = false;

  UserModel? get lawyer => _lawyer;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;

  Uint8List? get pictureBytes => _pictureBytes;
  String? get pictureFileName => _pictureFileName;

  bool get isVerifying => _isVerifying;
  bool? get isVerified => _isVerified;
  String? get verifiedName => _verifiedName;

  double? get latitude => _latitude;
  double? get longitude => _longitude;
  bool get hasLocation => _latitude != null && _longitude != null;
  bool get hasChanges => _hasChanges;

  // Face recognition getters
  bool get faceRegistered => _faceRegistered;
  bool get isFaceProcessing => _isFaceProcessing;
  String? get faceMessage => _faceMessage;
  double? get faceConfidence => _faceConfidence;

  // Signature getters
  String? get signatureUrl => _signatureUrl;
  bool get hasSignature => _signatureUrl != null && _signatureUrl!.isNotEmpty;
  bool get isSignatureProcessing => _isSignatureProcessing;
  String? get signatureMessage => _signatureMessage;

  /// Mark that something changed (called from UI when text fields change)
  void markChanged() {
    if (!_hasChanges) {
      _hasChanges = true;
      notifyListeners();
    }
  }

  /// Load the lawyer's current profile data
  Future<void> loadProfile(String lawyerId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _lawyer = await _lawyerService.getLawyerById(lawyerId);
      _latitude = _lawyer?.latitude;
      _longitude = _lawyer?.longitude;
      _isVerified = _lawyer?.isVerified;
      _faceRegistered = _lawyer?.faceRegistered ?? false;
      _signatureUrl = _lawyer?.signatureUrl;

      // Populate text controllers
      nameController.text = _lawyer?.name ?? '';
      lastNameController.text = _lawyer?.lastName ?? '';
      emailController.text = _lawyer?.email ?? '';
      phoneController.text = _lawyer?.phoneNumber ?? '';
      identityNumberController.text = _lawyer?.identityNumber ?? '';

      _hasChanges = false;
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'UNEXPECTED_ERROR';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Pick a profile picture from gallery
  Future<void> pickPicture() async {
    try {
      final picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      if (picked != null) {
        _pictureBytes = await picked.readAsBytes();
        _pictureFileName = picked.name;
        _hasChanges = true;
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Failed to pick image';
      notifyListeners();
    }
  }

  /// Take a profile picture with camera
  Future<void> takePicture() async {
    try {
      final picked = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      if (picked != null) {
        _pictureBytes = await picked.readAsBytes();
        _pictureFileName = picked.name;
        _hasChanges = true;
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Failed to take photo';
      notifyListeners();
    }
  }

  /// Verify lawyer name against the Tunisian Bar Association database
  Future<void> verifyLawyer() async {
    if (_lawyer == null) return;

    final fullName = '${_lawyer!.name} ${_lawyer!.lastName}'.trim();
    final cin = _lawyer!.identityNumber;
    final phone = _lawyer!.phoneNumber;
    if (fullName.isEmpty || cin.isEmpty || phone.isEmpty) return;

    _isVerifying = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _lawyerService.verifyLawyer(
        fullName: fullName,
        cin: cin,
        phone: phone,
      );
      _isVerified = result['verified'] == true;
      _verifiedName = result['lawyer']?['nom_complet'] as String?;

      // Persist verification status to backend
      if (_isVerified != null) {
        _lawyer = await _lawyerService.setVerified(_lawyer!.id, _isVerified!);
      }
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _isVerified = null;
    } catch (e) {
      _errorMessage = 'VERIFICATION_FAILED';
      _isVerified = null;
    } finally {
      _isVerifying = false;
      notifyListeners();
    }
  }

  /// Set location from map picker
  void setLocation(double lat, double lng) {
    _latitude = lat;
    _longitude = lng;
    _hasChanges = true;
    notifyListeners();
  }

  /// Clear location
  void clearLocation() {
    _latitude = null;
    _longitude = null;
    _hasChanges = true;
    notifyListeners();
  }

  /// Save all profile changes
  Future<bool> saveProfile() async {
    if (_lawyer == null) return false;

    _isSaving = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      _lawyer = await _lawyerService.updateLawyerProfile(
        _lawyer!.id,
        pictureBytes: _pictureBytes,
        pictureFileName: _pictureFileName,
        name: nameController.text.trim(),
        lastName: lastNameController.text.trim(),
        email: emailController.text.trim(),
        phoneNumber: phoneController.text.trim(),
        identitynumber: identityNumberController.text.trim(),
        latitude: _latitude,
        longitude: _longitude,
      );

      // Clear pending file selections after successful save
      _pictureBytes = null;
      _pictureFileName = null;
      _latitude = _lawyer?.latitude;
      _longitude = _lawyer?.longitude;
      _hasChanges = false;
      _successMessage = 'PROFILE_UPDATED';

      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'UNEXPECTED_ERROR';
      notifyListeners();
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    _faceMessage = null;
    _faceConfidence = null;
    _signatureMessage = null;
    notifyListeners();
  }

  // ─── Face Recognition ──────────────────────────────────────────────

  Future<void> registerFace(Uint8List imageBytes) async {
    if (_lawyer == null) return;
    _isFaceProcessing = true;
    _faceMessage = null;
    notifyListeners();

    final result = await _faceService.registerFace(
      userEmail: _lawyer!.email,
      imageBytes: imageBytes,
    );

    _isFaceProcessing = false;
    if (result.success) {
      _faceRegistered = true;
      _faceMessage = 'FACE_REGISTERED';
    } else {
      _faceMessage = result.message;
    }
    notifyListeners();
  }

  Future<void> verifyFace(Uint8List imageBytes) async {
    _isFaceProcessing = true;
    _faceMessage = null;
    _faceConfidence = null;
    notifyListeners();

    final result = await _faceService.recognizeFace(imageBytes: imageBytes);

    _isFaceProcessing = false;
    if (result.success && result.userId != null) {
      _faceConfidence = result.confidence;
      if (result.confidence != null && result.confidence! < 0.60) {
        _faceMessage = 'FACE_LOW_CONFIDENCE';
      } else {
        _faceMessage = 'FACE_VERIFIED';
      }
    } else {
      _faceMessage = 'FACE_NOT_RECOGNIZED';
    }
    notifyListeners();
  }

  Future<void> removeFace(String password) async {
    if (_lawyer == null) return;
    _isFaceProcessing = true;
    _faceMessage = null;
    notifyListeners();

    try {
      final authService = AuthService();
      try {
        await authService.signIn(email: _lawyer!.email, password: password);
      } finally {
        authService.dispose();
      }
    } on ApiException {
      _isFaceProcessing = false;
      _faceMessage = 'FACE_DELETE_WRONG_PASSWORD';
      notifyListeners();
      return;
    } catch (_) {
      _isFaceProcessing = false;
      _faceMessage = 'FACE_DELETE_WRONG_PASSWORD';
      notifyListeners();
      return;
    }

    final result = await _faceService.deleteFace(userEmail: _lawyer!.email);

    _isFaceProcessing = false;
    if (result.success) {
      _faceRegistered = false;
      _faceMessage = 'FACE_REMOVED';
      _faceConfidence = null;
    } else {
      _faceMessage = result.message;
    }
    notifyListeners();
  }

  // ─── Electronic Signature ───────────────────────────────────────────

  Future<void> saveSignature(Uint8List pngBytes) async {
    if (_lawyer == null) return;
    _isSignatureProcessing = true;
    _signatureMessage = null;
    notifyListeners();

    try {
      final url = await _signatureService.uploadSignature(
        userId: _lawyer!.id,
        signatureBytes: pngBytes,
        isLawyer: true,
      );
      _signatureUrl = url;
      _signatureMessage = 'SIGNATURE_SAVED';
    } on ApiException catch (e) {
      _signatureMessage = e.message;
    } catch (e) {
      _signatureMessage = e.toString();
    } finally {
      _isSignatureProcessing = false;
      notifyListeners();
    }
  }

  Future<void> deleteSignature() async {
    if (_lawyer == null) return;
    _isSignatureProcessing = true;
    _signatureMessage = null;
    notifyListeners();

    try {
      await _signatureService.deleteSignature(
        userId: _lawyer!.id,
        isLawyer: true,
      );
      _signatureUrl = null;
      _signatureMessage = 'SIGNATURE_DELETED';
    } on ApiException catch (e) {
      _signatureMessage = e.message;
    } catch (e) {
      _signatureMessage = e.toString();
    } finally {
      _isSignatureProcessing = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    identityNumberController.dispose();
    super.dispose();
  }
}
