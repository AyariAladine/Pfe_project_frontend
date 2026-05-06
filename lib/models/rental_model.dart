class PaymentRecord {
  final DateTime paidAt;
  final double amount;

  PaymentRecord({required this.paidAt, required this.amount});

  factory PaymentRecord.fromJson(Map<String, dynamic> json) {
    return PaymentRecord(
      paidAt: DateTime.tryParse(json['paidAt'] as String? ?? '') ?? DateTime.now(),
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class RentalModel {
  final String id;
  final String contractId;
  final String propertyId;
  final String ownerId;
  final String tenantId;
  final double monthlyAmount;
  final DateTime startDate;
  final DateTime nextDueDate;
  final String status; // 'active' | 'terminated'
  final List<PaymentRecord> paymentHistory;
  final String propertyAddress;
  final String ownerName;
  final String tenantName;
  final DateTime createdAt;

  RentalModel({
    required this.id,
    required this.contractId,
    required this.propertyId,
    required this.ownerId,
    required this.tenantId,
    required this.monthlyAmount,
    required this.startDate,
    required this.nextDueDate,
    required this.status,
    required this.paymentHistory,
    required this.propertyAddress,
    required this.ownerName,
    required this.tenantName,
    required this.createdAt,
  });

  factory RentalModel.fromJson(Map<String, dynamic> json) {
    return RentalModel(
      id: json['_id'] as String? ?? json['id'] as String? ?? '',
      contractId: _extractId(json['contractId']) ?? '',
      propertyId: _extractId(json['propertyId']) ?? '',
      ownerId: _extractId(json['ownerId']) ?? '',
      tenantId: _extractId(json['tenantId']) ?? '',
      monthlyAmount: (json['monthlyAmount'] as num?)?.toDouble() ?? 0.0,
      startDate: DateTime.tryParse(json['startDate'] as String? ?? '') ?? DateTime.now(),
      nextDueDate: DateTime.tryParse(json['nextDueDate'] as String? ?? '') ?? DateTime.now(),
      status: json['status'] as String? ?? 'active',
      paymentHistory: (json['paymentHistory'] as List<dynamic>?)
              ?.map((e) => PaymentRecord.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      propertyAddress: json['propertyAddress'] as String? ?? '',
      ownerName: json['ownerName'] as String? ?? '',
      tenantName: json['tenantName'] as String? ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
    );
  }

  int get daysUntilDue {
    final now = DateTime.now();
    return nextDueDate.difference(DateTime(now.year, now.month, now.day)).inDays;
  }

  bool get isOverdue => daysUntilDue < 0;
  bool get isDueSoon => !isOverdue && daysUntilDue <= 3;

  static String? _extractId(dynamic value) {
    if (value == null) return null;
    if (value is String) return value;
    if (value is Map<String, dynamic>) {
      return value['_id'] as String? ?? value['id'] as String?;
    }
    return null;
  }
}
