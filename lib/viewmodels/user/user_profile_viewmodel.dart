import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../services/face_recognition_service.dart';
import '../../services/signature_service.dart';
import '../../services/user_service.dart';

/// ViewModel for the regular user profile editing screen
class UserProfileViewModel extends ChangeNotifier {
  final UserService _userService = UserService();
  final FaceRecognitionService _faceService = FaceRecognitionService();
  final SignatureService _signatureService = SignatureService();

  UserModel? _user;
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

  // Tracking changes
  bool _hasChanges = false;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
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

  /// Load user data from the auth viewmodel's cached user
  void loadFromUser(UserModel user) {
    _isLoading = true;
    notifyListeners();

    _user = user;
    _faceRegistered = user.faceRegistered;
    _signatureUrl = user.signatureUrl;
    nameController.text = user.name;
    lastNameController.text = user.lastName;
    emailController.text = user.email;
    phoneController.text = user.phoneNumber;
    identityNumberController.text = user.identityNumber;
    _hasChanges = false;
    _errorMessage = null;
    _successMessage = null;

    _isLoading = false;
    notifyListeners();
  }

  /// Save all profile changes
  Future<bool> saveProfile() async {
    if (_user == null) return false;

    _isSaving = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      _user = await _userService.updateUserProfile(
        _user!.id,
        name: nameController.text.trim(),
        lastName: lastNameController.text.trim(),
        email: emailController.text.trim(),
        phoneNumber: phoneController.text.trim(),
        identitynumber: identityNumberController.text.trim(),
      );

      // Re-sync controllers with server response
      nameController.text = _user!.name;
      lastNameController.text = _user!.lastName;
      emailController.text = _user!.email;
      phoneController.text = _user!.phoneNumber;
      identityNumberController.text = _user!.identityNumber;

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
    notifyListeners();
  }

  // ─── Face Recognition ──────────────────────────────────────────────

  /// Register the user's face from a camera image
  Future<void> registerFace(Uint8List imageBytes) async {
    if (_user == null) return;
    _isFaceProcessing = true;
    _faceMessage = null;
    notifyListeners();

    final result = await _faceService.registerFace(
      userEmail: _user!.email,
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

  /// Verify the user's face
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

  /// Verify face before allowing deletion
  /// Remove the user's registered face after password verification
  Future<void> removeFace(String password) async {
    if (_user == null) return;
    _isFaceProcessing = true;
    _faceMessage = null;
    notifyListeners();

    try {
      // Verify password via login endpoint
      final authService = AuthService();
      await authService.signIn(email: _user!.email, password: password);
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

    // Password verified — proceed with deletion
    final result = await _faceService.deleteFace(userEmail: _user!.email);

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

  /// Save a new signature
  Future<void> saveSignature(Uint8List pngBytes) async {
    if (_user == null) return;
    _isSignatureProcessing = true;
    _signatureMessage = null;
    notifyListeners();

    try {
      final url = await _signatureService.uploadSignature(
        userId: _user!.id,
        signatureBytes: pngBytes,
        isLawyer: false,
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

  /// Delete saved signature
  Future<void> deleteSignature() async {
    if (_user == null) return;
    _isSignatureProcessing = true;
    _signatureMessage = null;
    notifyListeners();

    try {
      await _signatureService.deleteSignature(
        userId: _user!.id,
        isLawyer: false,
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
