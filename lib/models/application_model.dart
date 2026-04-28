/// Application status lifecycle:
/// pending → under_review → visit_scheduled → pre_approved → accepted
///   → negotiation → awaiting_lawyer → contract_drafting → (contract)
///                        ↘ rejected
///         ↘ cancelled (by applicant)
enum ApplicationStatus {
  pending,
  underReview,
  visitScheduled,
  preApproved,
  accepted,
  negotiation,
  awaitingLawyer,
  contractDrafting,
  rejected,
  cancelled;

  String toJson() {
    switch (this) {
      case ApplicationStatus.underReview:
        return 'under_review';
      case ApplicationStatus.visitScheduled:
        return 'visit_scheduled';
      case ApplicationStatus.preApproved:
        return 'pre_approved';
      case ApplicationStatus.awaitingLawyer:
        return 'awaiting_lawyer';
      case ApplicationStatus.contractDrafting:
        return 'contract_drafting';
      default:
        return name;
    }
  }

  static ApplicationStatus fromJson(String json) {
    final normalized = json.toLowerCase().replaceAll('-', '_');
    switch (normalized) {
      case 'under_review':
        return ApplicationStatus.underReview;
      case 'visit_scheduled':
        return ApplicationStatus.visitScheduled;
      case 'pre_approved':
        return ApplicationStatus.preApproved;
      case 'awaiting_lawyer':
        return ApplicationStatus.awaitingLawyer;
      case 'contract_drafting':
        return ApplicationStatus.contractDrafting;
      default:
        return ApplicationStatus.values.firstWhere(
          (e) => e.name.toLowerCase() == normalized,
          orElse: () => ApplicationStatus.pending,
        );
    }
  }

  /// Whether the owner can still take action on this application
  bool get isActive =>
      this == pending ||
      this == underReview ||
      this == visitScheduled ||
      this == preApproved ||
      this == accepted ||
      this == negotiation ||
      this == awaitingLawyer;
}

/// Application type — rent or buy
enum ApplicationType {
  rent,
  buy;

  String toJson() => name;

  static ApplicationType fromJson(String json) {
    return ApplicationType.values.firstWhere(
      (e) => e.name.toLowerCase() == json.toLowerCase(),
      orElse: () => ApplicationType.rent,
    );
  }
}

/// A single message in the application conversation
class ApplicationMessage {
  final String id;
  final String applicationId;
  final String senderId;
  final String senderName;
  final String content;
  final DateTime createdAt;
  final bool isRead;

  ApplicationMessage({
    required this.id,
    required this.applicationId,
    required this.senderId,
    required this.senderName,
    required this.content,
    required this.createdAt,
    this.isRead = false,
  });

  factory ApplicationMessage.fromJson(Map<String, dynamic> json) {
    final sender = json['sender'];
    String senderName = '';
    String senderId = '';

    if (sender is Map<String, dynamic>) {
      senderId = sender['_id'] as String? ?? sender['id'] as String? ?? '';
      senderName =
          '${sender['name'] ?? ''} ${sender['lastName'] ?? ''}'.trim();
    } else if (sender is String) {
      senderId = sender;
    }

    return ApplicationMessage(
      id: json['_id'] as String? ?? json['id'] as String? ?? '',
      applicationId: json['applicationId'] as String? ?? '',
      senderId: json['senderId'] as String? ?? senderId,
      senderName: json['senderName'] as String? ?? senderName,
      content: json['content'] as String? ?? json['message'] as String? ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      isRead: json['isRead'] as bool? ?? false,
    );
  }
}

/// A status change entry in the application history
class ApplicationStatusEntry {
  final ApplicationStatus fromStatus;
  final ApplicationStatus toStatus;
  final String? changedBy;
  final String? note;
  final DateTime createdAt;

  ApplicationStatusEntry({
    required this.fromStatus,
    required this.toStatus,
    this.changedBy,
    this.note,
    required this.createdAt,
  });

  factory ApplicationStatusEntry.fromJson(Map<String, dynamic> json) {
    return ApplicationStatusEntry(
      fromStatus:
          ApplicationStatus.fromJson(json['fromStatus'] as String? ?? 'pending'),
      toStatus:
          ApplicationStatus.fromJson(json['toStatus'] as String? ?? 'pending'),
      changedBy: json['changedBy'] as String?,
      note: json['note'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }
}

/// A user's application (postulation) for a property
class ApplicationModel {
  final String id;
  final String propertyId;
  final String applicantId;
  final ApplicationType type;
  final ApplicationStatus status;
  final String? message;
  final String? ownerNotes;
  final String? rejectionReason;
  final DateTime? visitDate;
  final DateTime createdAt;
  final DateTime? updatedAt;

  // Negotiation / contract fields
  final double? dealAmount;
  final String? assignedLawyerId;
  final Map<String, dynamic>? assignedLawyer;

  // Populated relations (may come from backend joins)
  final Map<String, dynamic>? property;
  final Map<String, dynamic>? applicant;

  // Status history and messages (loaded on detail)
  final List<ApplicationStatusEntry> statusHistory;
  final int unreadMessages;

  ApplicationModel({
    required this.id,
    required this.propertyId,
    required this.applicantId,
    required this.type,
    this.status = ApplicationStatus.pending,
    this.message,
    this.ownerNotes,
    this.rejectionReason,
    this.visitDate,
    required this.createdAt,
    this.updatedAt,
    this.dealAmount,
    this.assignedLawyerId,
    this.assignedLawyer,
    this.property,
    this.applicant,
    this.statusHistory = const [],
    this.unreadMessages = 0,
  });

  factory ApplicationModel.fromJson(Map<String, dynamic> json) {
    List<ApplicationStatusEntry> history = [];
    if (json['statusHistory'] is List) {
      history = (json['statusHistory'] as List)
          .map((e) =>
              ApplicationStatusEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    return ApplicationModel(
      id: json['_id'] as String? ?? json['id'] as String? ?? '',
      propertyId:
          _extractId(json['propertyId']) ?? _extractId(json['property']) ?? '',
      applicantId:
          _extractId(json['applicantId']) ?? _extractId(json['applicant']) ?? '',
      type: ApplicationType.fromJson(json['type'] as String? ?? 'rent'),
      status:
          ApplicationStatus.fromJson(json['status'] as String? ?? 'pending'),
      message: json['message'] as String?,
      ownerNotes: json['ownerNotes'] as String?,
      rejectionReason: json['rejectionReason'] as String?,
      visitDate: json['visitDate'] != null
          ? DateTime.parse(json['visitDate'] as String)
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      dealAmount: (json['dealAmount'] as num?)?.toDouble(),
      assignedLawyerId: _extractId(json['assignedLawyerId']) ?? _extractId(json['assignedLawyer']),
      assignedLawyer: json['assignedLawyerId'] is Map<String, dynamic>
          ? json['assignedLawyerId'] as Map<String, dynamic>
          : json['assignedLawyer'] is Map<String, dynamic>
              ? json['assignedLawyer'] as Map<String, dynamic>
              : null,
      property: json['propertyId'] is Map<String, dynamic>
          ? json['propertyId'] as Map<String, dynamic>
          : json['property'] is Map<String, dynamic>
              ? json['property'] as Map<String, dynamic>
              : null,
      applicant: json['applicantId'] is Map<String, dynamic>
          ? json['applicantId'] as Map<String, dynamic>
          : json['applicant'] is Map<String, dynamic>
              ? json['applicant'] as Map<String, dynamic>
              : null,
      statusHistory: history,
      unreadMessages: json['unreadMessages'] as int? ?? 0,
    );
  }

  /// Extract an ID from either a plain string or a populated object
  static String? _extractId(dynamic value) {
    if (value == null) return null;
    if (value is String) return value;
    if (value is Map<String, dynamic>) {
      return value['_id'] as String? ?? value['id'] as String?;
    }
    return null;
  }

  Map<String, dynamic> toJson() => {
        'propertyId': propertyId,
        'type': type.toJson(),
        if (message != null && message!.isNotEmpty) 'message': message,
      };

  // ─── Convenience getters for populated property data ───────────

  String get propertyAddress =>
      property?['Propertyaddresse'] as String? ?? '—';

  String? get propertyFirstImage {
    final images = property?['propertyImages'];
    if (images is List && images.isNotEmpty) return images.first as String?;
    return null;
  }

  String get ownerName {
    final owner = property?['owner'];
    if (owner is Map<String, dynamic>) {
      return '${owner['name'] ?? ''} ${owner['lastName'] ?? ''}'.trim();
    }
    return '—';
  }

  // ─── Convenience getters for populated applicant data ──────────

  String get applicantName {
    if (applicant == null) return '—';
    return '${applicant!['name'] ?? ''} ${applicant!['lastName'] ?? ''}'.trim();
  }

  String? get applicantEmail => applicant?['email'] as String?;

  String? get applicantPhone {
    final phone = applicant?['phoneNumber'] as String?;
    return (phone != null && phone != '00000000') ? phone : null;
  }

  bool get applicantFaceRegistered =>
      applicant?['faceRegistered'] as bool? ?? false;

  bool get applicantHasSignature =>
      applicant?['signatureUrl'] != null &&
      (applicant!['signatureUrl'] as String).isNotEmpty;

  bool get applicantIsVerified =>
      applicant?['isVerified'] as bool? ?? false;

  String? get applicantProfileImage =>
      applicant?['profileImageUrl'] as String?;

  // ─── Convenience getters for assigned lawyer ───────────────────

  String? get assignedLawyerName {
    if (assignedLawyer == null) return null;
    final name = '${assignedLawyer!['name'] ?? ''} ${assignedLawyer!['lastName'] ?? ''}'.trim();
    return name.isEmpty ? null : name;
  }

  /// Create a copy with updated fields
  ApplicationModel copyWith({
    ApplicationStatus? status,
    String? ownerNotes,
    String? rejectionReason,
    DateTime? visitDate,
    int? unreadMessages,
    double? dealAmount,
    String? assignedLawyerId,
    Map<String, dynamic>? assignedLawyer,
  }) {
    return ApplicationModel(
      id: id,
      propertyId: propertyId,
      applicantId: applicantId,
      type: type,
      status: status ?? this.status,
      message: message,
      ownerNotes: ownerNotes ?? this.ownerNotes,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      visitDate: visitDate ?? this.visitDate,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      dealAmount: dealAmount ?? this.dealAmount,
      assignedLawyerId: assignedLawyerId ?? this.assignedLawyerId,
      assignedLawyer: assignedLawyer ?? this.assignedLawyer,
      property: property,
      applicant: applicant,
      statusHistory: statusHistory,
      unreadMessages: unreadMessages ?? this.unreadMessages,
    );
  }
}
