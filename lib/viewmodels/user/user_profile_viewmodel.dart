import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../services/api_service.dart';
import '../../services/user_service.dart';

/// ViewModel for the regular user profile editing screen
class UserProfileViewModel extends ChangeNotifier {
  final UserService _userService = UserService();

  UserModel? _user;
  final bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;
  String? _successMessage;

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

  /// Mark that something changed (called from UI when text fields change)
  void markChanged() {
    if (!_hasChanges) {
      _hasChanges = true;
      notifyListeners();
    }
  }

  /// Load user data from the auth viewmodel's cached user
  void loadFromUser(UserModel user) {
    _user = user;
    nameController.text = user.name;
    lastNameController.text = user.lastName;
    emailController.text = user.email;
    phoneController.text = user.phoneNumber;
    identityNumberController.text = user.identityNumber;
    _hasChanges = false;
    _errorMessage = null;
    _successMessage = null;
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
    notifyListeners();
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
