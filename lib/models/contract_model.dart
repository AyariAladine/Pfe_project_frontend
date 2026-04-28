/// Contract types supported by the platform
enum ContractType {
  rental,
  sale,
  rentalAnnex;

  String toJson() {
    switch (this) {
      case ContractType.rental:
        return 'rental';
      case ContractType.sale:
        return 'sale';
      case ContractType.rentalAnnex:
        return 'rental_annex';
    }
  }

  static ContractType fromJson(String json) {
    switch (json.toLowerCase().replaceAll('-', '_')) {
      case 'sale':
        return ContractType.sale;
      case 'rental_annex':
        return ContractType.rentalAnnex;
      default:
        return ContractType.rental;
    }
  }
}

/// Contract lifecycle status
enum ContractStatus {
  draft,
  pendingReview,
  pendingSignatures,
  signedByOwner,
  signedByTenant,
  completed,
  cancelled;

  String toJson() {
    switch (this) {
      case ContractStatus.draft:
        return 'draft';
      case ContractStatus.pendingReview:
        return 'pending_review';
      case ContractStatus.pendingSignatures:
        return 'pending_signatures';
      case ContractStatus.signedByOwner:
        return 'signed_by_owner';
      case ContractStatus.signedByTenant:
        return 'signed_by_tenant';
      case ContractStatus.completed:
        return 'completed';
      case ContractStatus.cancelled:
        return 'cancelled';
    }
  }

  static ContractStatus fromJson(String json) {
    switch (json.toLowerCase().replaceAll('-', '_')) {
      case 'pending_review':
        return ContractStatus.pendingReview;
      case 'pending_signatures':
        return ContractStatus.pendingSignatures;
      case 'signed_by_owner':
        return ContractStatus.signedByOwner;
      case 'signed_by_tenant':
        return ContractStatus.signedByTenant;
      case 'completed':
        return ContractStatus.completed;
      case 'cancelled':
        return ContractStatus.cancelled;
      default:
        return ContractStatus.draft;
    }
  }
}

/// A contract created from a template for a specific application
class ContractModel {
  final String id;
  final String applicationId;
  final ContractType type;
  final ContractStatus status;
  final String lawyerId;
  final String ownerId;
  final String tenantId;
  final String propertyId;

  /// The generated contract body text (Arabic legal text)
  final String content;

  /// Filled-in clause values (editable by lawyer)
  final Map<String, String> fields;

  final double dealAmount;
  final DateTime? startDate;
  final DateTime? endDate;

  final String? ownerSignatureUrl;
  final String? tenantSignatureUrl;
  final String? lawyerSignatureUrl;

  final DateTime createdAt;
  final DateTime? updatedAt;

  // Populated relations
  final Map<String, dynamic>? owner;
  final Map<String, dynamic>? tenant;
  final Map<String, dynamic>? lawyer;
  final Map<String, dynamic>? property;

  ContractModel({
    required this.id,
    required this.applicationId,
    required this.type,
    this.status = ContractStatus.draft,
    required this.lawyerId,
    required this.ownerId,
    required this.tenantId,
    required this.propertyId,
    required this.content,
    this.fields = const {},
    required this.dealAmount,
    this.startDate,
    this.endDate,
    this.ownerSignatureUrl,
    this.tenantSignatureUrl,
    this.lawyerSignatureUrl,
    required this.createdAt,
    this.updatedAt,
    this.owner,
    this.tenant,
    this.lawyer,
    this.property,
  });

  factory ContractModel.fromJson(Map<String, dynamic> json) {
    return ContractModel(
      id: json['_id'] as String? ?? json['id'] as String? ?? '',
      applicationId: _extractId(json['applicationId']) ?? '',
      type: ContractType.fromJson(json['type'] as String? ?? 'rental'),
      status:
          ContractStatus.fromJson(json['status'] as String? ?? 'draft'),
      lawyerId: _extractId(json['lawyerId']) ?? '',
      ownerId: _extractId(json['ownerId']) ?? '',
      tenantId: _extractId(json['tenantId']) ?? '',
      propertyId: _extractId(json['propertyId']) ?? '',
      content: json['content'] as String? ?? '',
      fields: json['fields'] is Map
          ? Map<String, String>.from(
              (json['fields'] as Map).map((k, v) => MapEntry(k.toString(), v.toString())))
          : {},
      dealAmount: (json['dealAmount'] as num?)?.toDouble() ?? 0.0,
      startDate: json['startDate'] != null
          ? DateTime.tryParse(json['startDate'] as String)
          : null,
      endDate: json['endDate'] != null
          ? DateTime.tryParse(json['endDate'] as String)
          : null,
      ownerSignatureUrl: json['ownerSignatureUrl'] as String?,
      tenantSignatureUrl: json['tenantSignatureUrl'] as String?,
      lawyerSignatureUrl: json['lawyerSignatureUrl'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String)
          : null,
      owner: _extractPopulated(json, 'ownerId', 'owner'),
      tenant: _extractPopulated(json, 'tenantId', 'tenant'),
      lawyer: _extractPopulated(json, 'lawyerId', 'lawyer'),
      property: _extractPopulated(json, 'propertyId', 'property'),
    );
  }

  Map<String, dynamic> toJson() => {
        'applicationId': applicationId,
        'type': type.toJson(),
        'content': content,
        'fields': fields,
        'dealAmount': dealAmount,
        if (startDate != null) 'startDate': startDate!.toIso8601String(),
        if (endDate != null) 'endDate': endDate!.toIso8601String(),
      };

  // ─── Convenience getters ──────────────────────────────────────

  String get ownerName => _personName(owner);
  String get tenantName => _personName(tenant);
  String get lawyerName => _personName(lawyer);
  String get propertyAddress =>
      property?['Propertyaddresse'] as String? ?? '—';

  bool get isEditable =>
      status == ContractStatus.draft ||
      status == ContractStatus.pendingReview;

  bool get isSigned => status == ContractStatus.completed;

  ContractModel copyWith({
    ContractStatus? status,
    String? content,
    Map<String, String>? fields,
    DateTime? startDate,
    DateTime? endDate,
    String? ownerSignatureUrl,
    String? tenantSignatureUrl,
    String? lawyerSignatureUrl,
  }) {
    return ContractModel(
      id: id,
      applicationId: applicationId,
      type: type,
      status: status ?? this.status,
      lawyerId: lawyerId,
      ownerId: ownerId,
      tenantId: tenantId,
      propertyId: propertyId,
      content: content ?? this.content,
      fields: fields ?? this.fields,
      dealAmount: dealAmount,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      ownerSignatureUrl: ownerSignatureUrl ?? this.ownerSignatureUrl,
      tenantSignatureUrl: tenantSignatureUrl ?? this.tenantSignatureUrl,
      lawyerSignatureUrl: lawyerSignatureUrl ?? this.lawyerSignatureUrl,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      owner: owner,
      tenant: tenant,
      lawyer: lawyer,
      property: property,
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────

  static String? _extractId(dynamic value) {
    if (value == null) return null;
    if (value is String) return value;
    if (value is Map<String, dynamic>) {
      return value['_id'] as String? ?? value['id'] as String?;
    }
    return null;
  }

  static Map<String, dynamic>? _extractPopulated(
      Map<String, dynamic> json, String idKey, String altKey) {
    if (json[idKey] is Map<String, dynamic>) {
      return json[idKey] as Map<String, dynamic>;
    }
    if (json[altKey] is Map<String, dynamic>) {
      return json[altKey] as Map<String, dynamic>;
    }
    return null;
  }

  static String _personName(Map<String, dynamic>? person) {
    if (person == null) return '—';
    return '${person['name'] ?? ''} ${person['lastName'] ?? ''}'.trim();
  }
}
