import 'package:flutter/foundation.dart';

import '../../models/application_model.dart';
import '../../models/contract_model.dart';
import '../../core/constants/contract_templates.dart';
import '../../services/contract_service.dart';

/// ViewModel for contract listing, generation, editing, and signing.
class ContractViewModel extends ChangeNotifier {
  final ContractService _service = ContractService();

  List<ContractModel> _contracts = [];
  ContractModel? _selected;
  bool _isLoading = false;
  String? _error;

  // Generated template text (before saving to backend)
  String _generatedContent = '';
  Map<String, String> _editableFields = {};

  // ─── Getters ──────────────────────────────────────────────────

  List<ContractModel> get contracts => _contracts;
  ContractModel? get selected => _selected;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get generatedContent => _generatedContent;
  Map<String, String> get editableFields => _editableFields;

  // ─── Load contracts ───────────────────────────────────────────

  /// Load contracts for regular users (owner / tenant)
  Future<void> loadMyContracts() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _contracts = await _service.getMyContracts();
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  /// Load contracts assigned to the current lawyer
  Future<void> loadLawyerContracts() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _contracts = await _service.getLawyerContracts();
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  /// Load a single contract by ID
  Future<void> loadContract(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _selected = await _service.getContractById(id);
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  /// Load the contract for a specific application
  Future<void> loadContractByApplication(String applicationId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _selected = await _service.getContractByApplication(applicationId);
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  // ─── Template generation (local) ─────────────────────────────

  /// Generate a contract from a template, filling in application data.
  /// Call this when the lawyer opens the contract drafting screen.
  void generateFromTemplate({
    required ContractType type,
    required ApplicationModel application,
    Map<String, String>? overrides,
  }) {
    _editableFields = {
      ...ContractTemplates.getDefaultFields(type),
      if (overrides != null) ...overrides,
    };

    _generatedContent = _service.generateFromTemplate(
      type: type,
      application: application,
      extraFields: _editableFields,
    );

    notifyListeners();
  }

  /// Update a single editable field and regenerate the preview
  void updateField(String key, String value, {
    required ContractType type,
    required ApplicationModel application,
  }) {
    _editableFields[key] = value;
    _generatedContent = _service.generateFromTemplate(
      type: type,
      application: application,
      extraFields: _editableFields,
    );
    notifyListeners();
  }

  /// Directly edit the generated content (free-form)
  void setContent(String content) {
    _generatedContent = content;
    notifyListeners();
  }

  // ─── Contract CRUD ────────────────────────────────────────────

  /// Save the generated contract to the backend (creates a new one)
  Future<bool> createContract({
    required String applicationId,
    required ContractType type,
    required double dealAmount,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _selected = await _service.createContract(
        applicationId: applicationId,
        type: type,
        content: _generatedContent,
        fields: _editableFields,
        dealAmount: dealAmount,
        startDate: startDate,
        endDate: endDate,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Update an existing contract's content
  Future<bool> updateContract({
    required String id,
    String? content,
    Map<String, String>? fields,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _selected = await _service.updateContract(
        id: id,
        content: content,
        fields: fields,
        startDate: startDate,
        endDate: endDate,
      );
      // Sync in list
      final idx = _contracts.indexWhere((c) => c.id == id);
      if (idx != -1) _contracts[idx] = _selected!;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Send the contract for signatures
  Future<bool> sendForSignatures(String id) async {
    return _updateStatus(id, ContractStatus.pendingSignatures);
  }

  /// Sign the contract (current user)
  Future<bool> signContract(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _selected = await _service.signContract(id);
      final idx = _contracts.indexWhere((c) => c.id == id);
      if (idx != -1) _contracts[idx] = _selected!;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> _updateStatus(String id, ContractStatus status) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _selected = await _service.updateStatus(id: id, status: status);
      final idx = _contracts.indexWhere((c) => c.id == id);
      if (idx != -1) _contracts[idx] = _selected!;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void clearSelection() {
    _selected = null;
    _generatedContent = '';
    _editableFields = {};
    notifyListeners();
  }
}
