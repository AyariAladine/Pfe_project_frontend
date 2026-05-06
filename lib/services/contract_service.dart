import 'package:flutter/foundation.dart';
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
      // Owner identity (from CIN verification)
      ContractTemplates.ownerFullName: _personName(ownerMap),
      ContractTemplates.ownerIdNumber:
          ownerMap?['identitynumber'] as String? ?? '............',
      ContractTemplates.ownerBirthDate:
          ownerMap?['dateOfBirth'] as String? ?? '............',
      ContractTemplates.ownerBirthPlace:
          ownerMap?['placeOfBirth'] as String? ?? '............',
      ContractTemplates.ownerIdIssueDate:
          ownerMap?['issueDate'] as String? ?? '............',
      ContractTemplates.ownerAddress:
          ownerMap?['address'] as String? ?? '............',

      // Tenant identity (from CIN verification)
      ContractTemplates.tenantFullName: _personName(applicantMap),
      ContractTemplates.tenantIdNumber:
          applicantMap?['identitynumber'] as String? ?? '............',
      ContractTemplates.tenantBirthDate:
          applicantMap?['dateOfBirth'] as String? ?? '............',
      ContractTemplates.tenantBirthPlace:
          applicantMap?['placeOfBirth'] as String? ?? '............',
      ContractTemplates.tenantIdIssueDate:
          applicantMap?['issueDate'] as String? ?? '............',
      ContractTemplates.tenantAddress:
          applicantMap?['address'] as String? ?? '............',

      // Property
      ContractTemplates.propertyAddress: application.propertyAddress,

      // Financial
      ContractTemplates.dealAmount:
          (application.dealAmount ?? 0).toStringAsFixed(2),
      ContractTemplates.dealAmountWords:
          _amountToArabicWords(application.dealAmount ?? 0),
      ContractTemplates.depositAmount:
          extraFields['depositAmount'] ?? '............',
      ContractTemplates.syndicAmount:
          extraFields['syndicAmount'] ?? '............',
      ContractTemplates.annualIncreaseRate:
          extraFields['annualIncreaseRate'] ?? '5',
      ContractTemplates.paymentDay:
          extraFields['paymentDay'] ?? 'الخامس',

      // Dates / duration
      ContractTemplates.contractDate: _formatDate(now),
      ContractTemplates.startDate:
          extraFields['startDate'] ?? _formatDate(now),
      ContractTemplates.endDate:
          extraFields['endDate'] ?? '............',
      ContractTemplates.contractDuration:
          extraFields['contractDuration'] ?? '12',

      // Legal
      ContractTemplates.lawyerFullName:
          application.assignedLawyerName ?? '............',
      ContractTemplates.jurisdictionCourt:
          extraFields['jurisdictionCourt'] ?? 'محكمة تونس 1',

      // Annex-specific
      ContractTemplates.originalContractDate:
          extraFields['originalContractDate'] ?? '............',
      ContractTemplates.registrationDate:
          extraFields['registrationDate'] ?? '............',
      ContractTemplates.taxOfficeName:
          extraFields['taxOfficeName'] ?? '............',
      ContractTemplates.receiptNumber:
          extraFields['receiptNumber'] ?? '............',
      ContractTemplates.registrationNumber:
          extraFields['registrationNumber'] ?? '............',
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
    } catch (e) {
      debugPrint('[ContractService] getContractByApplication($applicationId): $e');
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

  // ─── Arabic amount words ──────────────────────────────────────

  String _amountToArabicWords(double amount) {
    if (amount <= 0) return 'صفر دينار';
    final int whole = amount.truncate();
    final int millimes = ((amount - whole) * 1000).round();
    final parts = <String>[];
    if (whole > 0) {
      parts.add('${_intToArabic(whole)} ${_dinarForm(whole)}');
    }
    if (millimes > 0) {
      parts.add('${_intToArabic(millimes)} ${_millimForm(millimes)}');
    }
    return parts.join(' و');
  }

  String _dinarForm(int n) {
    if (n == 1) return 'دينار';
    if (n == 2) return 'ديناران';
    if (n >= 3 && n <= 10) return 'دنانير';
    if (n >= 11 && n <= 99) return 'دينارًا';
    return 'دينار';
  }

  String _millimForm(int n) {
    if (n == 1) return 'مليم';
    if (n == 2) return 'مليمان';
    if (n >= 3 && n <= 10) return 'ملاليم';
    return 'مليمًا';
  }

  static const _ones = [
    '', 'واحد', 'اثنان', 'ثلاثة', 'أربعة', 'خمسة', 'ستة', 'سبعة', 'ثمانية', 'تسعة',
    'عشرة', 'أحد عشر', 'اثنا عشر', 'ثلاثة عشر', 'أربعة عشر', 'خمسة عشر',
    'ستة عشر', 'سبعة عشر', 'ثمانية عشر', 'تسعة عشر',
  ];

  static const _tens = [
    '', '', 'عشرون', 'ثلاثون', 'أربعون', 'خمسون', 'ستون', 'سبعون', 'ثمانون', 'تسعون',
  ];

  static const _hundreds = [
    '', 'مئة', 'مئتان', 'ثلاثمئة', 'أربعمئة', 'خمسمئة',
    'ستمئة', 'سبعمئة', 'ثمانمئة', 'تسعمئة',
  ];

  String _intToArabic(int n) {
    if (n == 0) return 'صفر';
    if (n < 20) return _ones[n];
    if (n < 100) {
      final unit = n % 10;
      return unit == 0 ? _tens[n ~/ 10] : '${_ones[unit]} و${_tens[n ~/ 10]}';
    }
    if (n < 1000) {
      final rem = n % 100;
      return rem == 0
          ? _hundreds[n ~/ 100]
          : '${_hundreds[n ~/ 100]} و${_intToArabic(rem)}';
    }
    if (n < 1_000_000) {
      final th = n ~/ 1000;
      final rem = n % 1000;
      final thStr = th == 1
          ? 'ألف'
          : th == 2
              ? 'ألفان'
              : th <= 10
                  ? '${_intToArabic(th)} آلاف'
                  : '${_intToArabic(th)} ألف';
      return rem == 0 ? thStr : '$thStr و${_intToArabic(rem)}';
    }
    final mil = n ~/ 1_000_000;
    final rem = n % 1_000_000;
    final milStr = mil == 1
        ? 'مليون'
        : mil == 2
            ? 'مليونان'
            : mil <= 10
                ? '${_intToArabic(mil)} ملايين'
                : '${_intToArabic(mil)} مليون';
    return rem == 0 ? milStr : '$milStr و${_intToArabic(rem)}';
  }
}
