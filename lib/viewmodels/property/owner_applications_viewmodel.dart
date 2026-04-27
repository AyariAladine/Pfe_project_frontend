import 'package:flutter/foundation.dart';
import '../../models/application_model.dart';
import '../../services/application_service.dart';
import '../../services/api_service.dart';

/// ViewModel for property owners to manage incoming applications
class OwnerApplicationsViewModel extends ChangeNotifier {
  final ApplicationService _service = ApplicationService();

  // ─── Incoming list state ───────────────────────────────────────
  List<ApplicationModel> _incoming = [];
  bool _isLoading = false;
  String? _error;

  List<ApplicationModel> get incoming => _incoming;
  bool get isLoading => _isLoading;
  String? get error => _error;

  int get pendingCount =>
      _incoming.where((a) => a.status == ApplicationStatus.pending).length;

  // ─── Selected application detail state ─────────────────────────
  ApplicationModel? _selectedApp;
  List<ApplicationMessage> _messages = [];
  bool _isLoadingDetail = false;
  bool _isUpdatingStatus = false;
  bool _isSendingMessage = false;
  String? _actionMessage;

  ApplicationModel? get selectedApp => _selectedApp;
  List<ApplicationMessage> get messages => _messages;
  bool get isLoadingDetail => _isLoadingDetail;
  bool get isUpdatingStatus => _isUpdatingStatus;
  bool get isSendingMessage => _isSendingMessage;
  String? get actionMessage => _actionMessage;

  // ─── Load incoming applications ────────────────────────────────

  Future<void> loadIncoming() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _incoming = await _service.getIncomingApplications();
    } on ApiException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ─── Select & load detail ──────────────────────────────────────

  Future<void> selectApplication(String applicationId) async {
    _isLoadingDetail = true;
    _actionMessage = null;
    _messages = [];
    notifyListeners();

    try {
      _selectedApp = await _service.getApplicationById(applicationId);
      _messages = await _service.getMessages(applicationId);
    } on ApiException catch (e) {
      _actionMessage = e.message;
    } catch (e) {
      _actionMessage = e.toString();
    } finally {
      _isLoadingDetail = false;
      notifyListeners();
    }
  }

  void clearSelection() {
    _selectedApp = null;
    _messages = [];
    _actionMessage = null;
    notifyListeners();
  }

  // ─── Owner status actions ──────────────────────────────────────

  Future<bool> updateStatus({
    required ApplicationStatus newStatus,
    String? note,
    String? rejectionReason,
    String? visitDate,
  }) async {
    if (_selectedApp == null) return false;
    _isUpdatingStatus = true;
    _actionMessage = null;
    notifyListeners();

    try {
      final updated = await _service.updateApplicationStatus(
        applicationId: _selectedApp!.id,
        newStatus: newStatus,
        note: note,
        rejectionReason: rejectionReason,
        visitDate: visitDate,
      );
      _selectedApp = updated;

      // Update the item in the incoming list too
      final idx = _incoming.indexWhere((a) => a.id == updated.id);
      if (idx != -1) _incoming[idx] = updated;

      _actionMessage = 'STATUS_UPDATED';
      return true;
    } on ApiException catch (e) {
      _actionMessage = e.message;
      return false;
    } catch (e) {
      _actionMessage = e.toString();
      return false;
    } finally {
      _isUpdatingStatus = false;
      notifyListeners();
    }
  }

  /// Shortcut: mark as Under Review
  Future<bool> markUnderReview({String? note}) =>
      updateStatus(newStatus: ApplicationStatus.underReview, note: note);

  /// Shortcut: schedule a visit
  Future<bool> scheduleVisit({required String visitDate, String? note}) =>
      updateStatus(
        newStatus: ApplicationStatus.visitScheduled,
        visitDate: visitDate,
        note: note,
      );

  /// Shortcut: pre-approve
  Future<bool> preApprove({String? note}) =>
      updateStatus(newStatus: ApplicationStatus.preApproved, note: note);

  /// Shortcut: accept (ready for negotiation)
  Future<bool> accept({String? note}) =>
      updateStatus(newStatus: ApplicationStatus.accepted, note: note);

  /// Shortcut: reject
  Future<bool> reject({required String reason}) =>
      updateStatus(
        newStatus: ApplicationStatus.rejected,
        rejectionReason: reason,
      );

  // ─── Negotiation / Contract flow ───────────────────────────────

  /// Set the deal amount and move to negotiation status
  Future<bool> setDealAmount(double amount) async {
    if (_selectedApp == null) return false;
    _isUpdatingStatus = true;
    _actionMessage = null;
    notifyListeners();

    try {
      final updated = await _service.setDealAmount(
        applicationId: _selectedApp!.id,
        amount: amount,
      );
      _selectedApp = updated;
      final idx = _incoming.indexWhere((a) => a.id == updated.id);
      if (idx != -1) _incoming[idx] = updated;
      _actionMessage = 'STATUS_UPDATED';
      return true;
    } on ApiException catch (e) {
      _actionMessage = e.message;
      return false;
    } catch (e) {
      _actionMessage = e.toString();
      return false;
    } finally {
      _isUpdatingStatus = false;
      notifyListeners();
    }
  }

  /// Assign a lawyer and move to contract_drafting status
  Future<bool> assignLawyer(String lawyerId) async {
    if (_selectedApp == null) return false;
    _isUpdatingStatus = true;
    _actionMessage = null;
    notifyListeners();

    try {
      final updated = await _service.assignLawyer(
        applicationId: _selectedApp!.id,
        lawyerId: lawyerId,
      );
      _selectedApp = updated;
      final idx = _incoming.indexWhere((a) => a.id == updated.id);
      if (idx != -1) _incoming[idx] = updated;
      _actionMessage = 'STATUS_UPDATED';
      return true;
    } on ApiException catch (e) {
      _actionMessage = e.message;
      return false;
    } catch (e) {
      _actionMessage = e.toString();
      return false;
    } finally {
      _isUpdatingStatus = false;
      notifyListeners();
    }
  }

  // ─── Messaging ─────────────────────────────────────────────────

  Future<bool> sendMessage(String content) async {
    if (_selectedApp == null || content.trim().isEmpty) return false;
    _isSendingMessage = true;
    notifyListeners();

    try {
      final msg = await _service.sendMessage(
        applicationId: _selectedApp!.id,
        content: content.trim(),
      );
      _messages.add(msg);
      return true;
    } on ApiException catch (e) {
      _actionMessage = e.message;
      return false;
    } catch (e) {
      _actionMessage = e.toString();
      return false;
    } finally {
      _isSendingMessage = false;
      notifyListeners();
    }
  }

  /// Refresh messages only
  Future<void> refreshMessages() async {
    if (_selectedApp == null) return;
    try {
      _messages = await _service.getMessages(_selectedApp!.id);
      notifyListeners();
    } catch (_) {}
  }

  void clearActionMessage() {
    _actionMessage = null;
    notifyListeners();
  }
}
