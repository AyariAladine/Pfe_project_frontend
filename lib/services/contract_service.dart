import '../core/constants/api_constants.dart';
import '../core/constants/contract_templates.dart';
import '../models/application_model.dart';
import '../models/contract_model.dart';
import 'api_service.dart';

/// Service for contract CRUD and template generation.
class ContractService {
  final ApiService _api = ApiService();

  // ─── Template generation (local, no API call) ─────────────────

  /// Generate contract body text from a template + application data.
  /// Returns the filled-in Arabic legal text ready for lawyer review.
  String generateFromTemplate({
    required ContractType type,
    required ApplicationModel application,
    required Map<String, String> extraFields,
  }) {
    final template = ContractTemplates.getTemplate(type);
    final now = DateTime.now();

    final ownerMap = application.property?['owner'] as Map<String, dynamic>?;
    final applicantMap = application.applicant;

    final values = <String, String>{
      ContractTemplates.ownerFullName: _personName(ownerMap),
      ContractTemplates.ownerIdNumber:
          ownerMap?['identitynumber'] as String? ?? '............',
      ContractTemplates.ownerAddress:
          application.propertyAddress,
      ContractTemplates.tenantFullName: _personName(applicantMap),
      ContractTemplates.tenantIdNumber:
          applicantMap?['identitynumber'] as String? ?? '............',
      ContractTemplates.tenantAddress:
          applicantMap?['address'] as String? ?? '............',
      ContractTemplates.propertyAddress: application.propertyAddress,
      ContractTemplates.dealAmount:
          (application.dealAmount ?? 0).toStringAsFixed(2),
      ContractTemplates.dealAmountWords: '............',
      ContractTemplates.contractDate: _formatDate(now),
      ContractTemplates.startDate:
          extraFields['startDate'] ?? _formatDate(now),
      ContractTemplates.endDate:
          extraFields['endDate'] ?? '............',
      ContractTemplates.lawyerFullName:
          application.assignedLawyerName ?? '............',
      ContractTemplates.depositAmount:
          extraFields['depositAmount'] ?? '............',
      ContractTemplates.paymentDay:
          extraFields['paymentDay'] ?? '1',
      ContractTemplates.contractDuration:
          extraFields['contractDuration'] ?? '12',
    };

    return ContractTemplates.fillTemplate(template: template, values: values);
  }

  // ─── API calls ────────────────────────────────────────────────

  /// Create a new contract (sent by lawyer after reviewing template)
  Future<ContractModel> createContract({
    required String applicationId,
    required ContractType type,
    required String content,
    required Map<String, String> fields,
    required double dealAmount,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final body = {
      'applicationId': applicationId,
      'type': type.toJson(),
      'content': content,
      'fields': fields,
      'dealAmount': dealAmount,
      if (startDate != null) 'startDate': startDate.toIso8601String(),
      if (endDate != null) 'endDate': endDate.toIso8601String(),
    };

    final response = await _api.post(
      ApiConstants.contracts,
      body: body,
      requiresAuth: true,
    );

    return ContractModel.fromJson(response);
  }

  /// Get all contracts for the current user (owner or tenant)
  Future<List<ContractModel>> getMyContracts() async {
    final response = await _api.get(
      ApiConstants.myContracts,
      requiresAuth: true,
    );
    if (response is List) {
      return response
          .map((j) => ContractModel.fromJson(j as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  /// Get all contracts assigned to the current lawyer
  Future<List<ContractModel>> getLawyerContracts() async {
    final response = await _api.get(
      ApiConstants.lawyerContracts,
      requiresAuth: true,
    );
    if (response is List) {
      return response
          .map((j) => ContractModel.fromJson(j as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  /// Get a single contract by ID (with populated relations)
  Future<ContractModel> getContractById(String id) async {
    final response = await _api.get(
      ApiConstants.contractById(id),
      requiresAuth: true,
    );
    return ContractModel.fromJson(response as Map<String, dynamic>);
  }

  /// Get contract for a specific application
  Future<ContractModel?> getContractByApplication(
      String applicationId) async {
    try {
      final response = await _api.get(
        ApiConstants.contractByApplication(applicationId),
        requiresAuth: true,
      );
      return ContractModel.fromJson(response as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  /// Update the contract content (lawyer editing)
  Future<ContractModel> updateContract({
    required String id,
    String? content,
    Map<String, String>? fields,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final body = <String, dynamic>{
      if (content != null) 'content': content,
      if (fields != null) 'fields': fields,
      if (startDate != null) 'startDate': startDate.toIso8601String(),
      if (endDate != null) 'endDate': endDate.toIso8601String(),
    };

    final response = await _api.patch(
      ApiConstants.contractById(id),
      body: body,
      requiresAuth: true,
    );

    return ContractModel.fromJson(response);
  }

  /// Update contract status (e.g. send for signatures)
  Future<ContractModel> updateStatus({
    required String id,
    required ContractStatus status,
  }) async {
    final response = await _api.patch(
      ApiConstants.contractUpdateStatus(id),
      body: {'status': status.toJson()},
      requiresAuth: true,
    );

    return ContractModel.fromJson(response);
  }

  /// Sign the contract (adds the current user's signature)
  Future<ContractModel> signContract(String id) async {
    final response = await _api.post(
      ApiConstants.contractSign(id),
      body: {},
      requiresAuth: true,
    );

    return ContractModel.fromJson(response);
  }

  // ─── Helpers ──────────────────────────────────────────────────

  String _personName(Map<String, dynamic>? person) {
    if (person == null) return '............';
    final name =
        '${person['name'] ?? ''} ${person['lastName'] ?? ''}'.trim();
    return name.isEmpty ? '............' : name;
  }

  String _formatDate(DateTime d) =>
      '${d.year}/${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}';
}
