import 'package:flutter/foundation.dart';
import '../../models/application_model.dart';
import '../../services/application_service.dart';
import '../../services/api_service.dart';

/// ViewModel for managing the user's property applications
class ApplicationViewModel extends ChangeNotifier {
  final ApplicationService _service = ApplicationService();

  List<ApplicationModel> _applications = [];
  bool _isLoading = false;
  String? _error;

  // For the property detail "Apply" flow
  bool _isApplying = false;
  String? _applyMessage;
  ApplicationModel? _existingApplication; // current user's app for viewed property

  List<ApplicationModel> get applications => _applications;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isApplying => _isApplying;
  String? get applyMessage => _applyMessage;
  ApplicationModel? get existingApplication => _existingApplication;

  bool get hasApplied =>
      _existingApplication != null &&
      _existingApplication!.status != ApplicationStatus.cancelled;

  /// Load all applications for the current user
  Future<void> loadMyApplications() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _applications = await _service.getMyApplications();
    } on ApiException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Check if user already applied for a specific property
  Future<void> checkExistingApplication(String propertyId) async {
    _existingApplication = null;
    _applyMessage = null;
    notifyListeners();

    try {
      _existingApplication =
          await _service.getMyApplicationForProperty(propertyId);
    } catch (_) {
      // Not critical — just means we couldn't check
    }
    notifyListeners();
  }

  /// Apply for a property
  Future<bool> applyForProperty({
    required String propertyId,
    required ApplicationType type,
    String? message,
  }) async {
    _isApplying = true;
    _applyMessage = null;
    notifyListeners();

    try {
      final app = await _service.applyForProperty(
        propertyId: propertyId,
        type: type,
        message: message,
      );
      _existingApplication = app;
      _applyMessage = 'APPLICATION_SUBMITTED';
      // Also prepend to local list
      _applications.insert(0, app);
      return true;
    } on ApiException catch (e) {
      _applyMessage = e.message;
      return false;
    } catch (e) {
      _applyMessage = e.toString();
      return false;
    } finally {
      _isApplying = false;
      notifyListeners();
    }
  }

  /// Cancel an existing application
  Future<bool> cancelApplication(String applicationId) async {
    _isApplying = true;
    _applyMessage = null;
    notifyListeners();

    try {
      await _service.cancelApplication(applicationId);
      // Update local state
      final idx = _applications.indexWhere((a) => a.id == applicationId);
      if (idx != -1) {
        _applications[idx] = ApplicationModel(
          id: _applications[idx].id,
          propertyId: _applications[idx].propertyId,
          applicantId: _applications[idx].applicantId,
          type: _applications[idx].type,
          status: ApplicationStatus.cancelled,
          message: _applications[idx].message,
          createdAt: _applications[idx].createdAt,
          updatedAt: DateTime.now(),
          property: _applications[idx].property,
          applicant: _applications[idx].applicant,
        );
      }
      if (_existingApplication?.id == applicationId) {
        _existingApplication = null;
      }
      _applyMessage = 'APPLICATION_CANCELLED';
      return true;
    } on ApiException catch (e) {
      _applyMessage = e.message;
      return false;
    } catch (e) {
      _applyMessage = e.toString();
      return false;
    } finally {
      _isApplying = false;
      notifyListeners();
    }
  }

  void clearApplyMessage() {
    _applyMessage = null;
    notifyListeners();
  }
}
