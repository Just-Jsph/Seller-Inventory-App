import '../../core/utils/money.dart';

class DebtModel {
  final int? id;
  final int userId;
  final String customerName;
  final String? customerPhone;
  // Interest configuration
  final String interestType; // 'PERCENTAGE' or 'FIXED'
  final double interestValue; // percentage if type is PERCENTAGE
  final int? interestFixedCents; // fixed amount in cents if type is FIXED
  final String interestPeriod; // 'DAILY','WEEKLY','MONTHLY'
  final int paidAmountCents;
  final DateTime? dueDate;
  final String status; // 'UNPAID', 'PARTIAL', 'PAID'
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  DebtModel({
    this.id,
    required this.userId,
    required this.customerName,
    this.customerPhone,
    required this.totalAmountCents,
    // Interest defaults: no interest
    this.interestType = 'PERCENTAGE',
    this.interestValue = 0.0,
    this.interestFixedCents = null,
    this.interestPeriod = 'MONTHLY',
    this.paidAmountCents = 0,
    this.dueDate,
    this.status = 'UNPAID',
    this.notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  double get totalAmount => Money.toDouble(totalAmountCents);
  double get paidAmount => Money.toDouble(paidAmountCents);
  // Interest calculation based on configuration
  int get interestCents {
    if (interestType == 'PERCENTAGE') {
      return ((totalAmountCents * interestValue) / 100).round();
    } else if (interestType == 'FIXED') {
      return interestFixedCents ?? 0;
    }
    return 0;
  }

  int get totalDueCents => totalAmountCents + interestCents;
  double get totalDue => Money.toDouble(totalDueCents);

  int get remainingAmountCents => totalDueCents - paidAmountCents;
  double get remainingAmount => Money.toDouble(remainingAmountCents);

  String get formattedInterest => Money.format(interestCents);
  String get formattedTotalDue => Money.format(totalDueCents);
  String get formattedRemaining => Money.format(remainingAmountCents);

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'total_amount_cents': totalAmountCents,
      'interest_type': interestType,
      'interest_value': interestValue,
      'interest_fixed_cents': interestFixedCents,
      'interest_period': interestPeriod,
      'paid_amount_cents': paidAmountCents,
      'due_date': dueDate?.toIso8601String(),
      'status': status,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory DebtModel.fromMap(Map<String, dynamic> map) {
    return DebtModel(
      id: map['id'] as int?,
      userId: map['user_id'] as int,
      customerName: map['customer_name'] as String,
      customerPhone: map['customer_phone'] as String?,
      totalAmountCents: map['total_amount_cents'] as int,
      interestType: map['interest_type'] as String? ?? 'PERCENTAGE',
      interestValue: (map['interest_value'] as num?)?.toDouble() ?? 0.0,
      interestFixedCents: map['interest_fixed_cents'] as int?,
      interestPeriod: map['interest_period'] as String? ?? 'MONTHLY',
      paidAmountCents: (map['paid_amount_cents'] as int?) ?? 0,
      dueDate: map['due_date'] != null ? DateTime.parse(map['due_date'] as String) : null,
      status: (map['status'] as String?) ?? 'UNPAID',
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  DebtModel copyWith({
    int? id,
    int? userId,
    String? customerName,
    String? customerPhone,
    int? totalAmountCents,
        double? interestRatePercent,
    int? paidAmountCents,
    DateTime? dueDate,
    String? status,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DebtModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      totalAmountCents: totalAmountCents ?? this.totalAmountCents,
      interestType: interestType ?? this.interestType,
      interestValue: interestValue ?? this.interestValue,
      interestFixedCents: interestFixedCents ?? this.interestFixedCents,
      interestPeriod: interestPeriod ?? this.interestPeriod,
      paidAmountCents: paidAmountCents ?? this.paidAmountCents,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
