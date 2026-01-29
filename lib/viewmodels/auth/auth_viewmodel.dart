import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';

enum AuthState {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error,
}

class AuthViewModel extends ChangeNotifier {
  final AuthService _authService = AuthService();

  AuthState _state = AuthState.initial;
  String? _errorMessage;
  UserRole? _selectedUserRole;
  UserModel? _currentUser;

  AuthState get state => _state;
  String? get errorMessage => _errorMessage;
  UserRole? get selectedUserRole => _selectedUserRole;
  UserModel? get currentUser => _currentUser;
  bool get isLoading => _state == AuthState.loading;
  bool get isAuthenticated => _state == AuthState.authenticated;

  void setUserRole(UserRole role) {
    _selectedUserRole = role;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Initialize auth state on app start
  Future<void> initializeAuth() async {
    try {
      _state = AuthState.loading;
      notifyListeners();
      
      await _authService.initializeAuth();
      
      if (_authService.currentUser != null) {
        _currentUser = _authService.currentUser;
        _state = AuthState.authenticated;
      } else {
        _state = AuthState.unauthenticated;
      }
      notifyListeners();
    } catch (e) {
      _state = AuthState.unauthenticated;
      notifyListeners();
    }
  }

  // Sign In with Email & Password
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    try {
      _state = AuthState.loading;
      _errorMessage = null;
      notifyListeners();

      final authResponse = await _authService.signIn(
        email: email,
        password: password,
      );

      _currentUser = authResponse.user;
      _state = AuthState.authenticated;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _state = AuthState.error;
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _state = AuthState.error;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Sign Up with all required fields
  Future<bool> signUp({
    required String name,
    required String lastName,
    required String email,
    required String password,
    required String phoneNumber,
  }) async {
    try {
      if (_selectedUserRole == null) {
        _errorMessage = 'ACCOUNT_TYPE_REQUIRED';
        notifyListeners();
        return false;
      }

      _state = AuthState.loading;
      _errorMessage = null;
      notifyListeners();

      await _authService.signUp(
        name: name,
        lastName: lastName,
        email: email,
        password: password,
        role: _selectedUserRole!,
        phoneNumber: phoneNumber,
      );

      // After signup, automatically login
      final authResponse = await _authService.signIn(
        email: email,
        password: password,
      );

      _currentUser = authResponse.user;
      _state = AuthState.authenticated;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _state = AuthState.error;
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _state = AuthState.error;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Send Password Reset Email
  Future<bool> forgotPassword(String email) async {
    try {
      _state = AuthState.loading;
      _errorMessage = null;
      notifyListeners();

      await _authService.forgotPassword(email);

      _state = AuthState.initial;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _state = AuthState.error;
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _state = AuthState.error;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Reset password with code
  Future<bool> resetPassword({
    required String code,
    required String newPassword,
  }) async {
    try {
      _state = AuthState.loading;
      _errorMessage = null;
      notifyListeners();

      await _authService.resetPassword(
        code: code,
        newPassword: newPassword,
      );

      _state = AuthState.initial;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _state = AuthState.error;
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _state = AuthState.error;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Sign Out
  Future<void> signOut() async {
    try {
      await _authService.signOut();
      _state = AuthState.unauthenticated;
      _selectedUserRole = null;
      _currentUser = null;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _authService.dispose();
    super.dispose();
  }
}
