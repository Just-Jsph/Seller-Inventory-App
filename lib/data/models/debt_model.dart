import '../../core/utils/money.dart';

class DebtModel {
  final int? id;
  final int userId;
  final String customerName;
  final String? customerPhone;
  final int totalAmountCents;
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
  double get remainingAmount => Money.toDouble(totalAmountCents - paidAmountCents);
  int get remainingAmountCents => totalAmountCents - paidAmountCents;
  String get formattedRemaining => Money.format(remainingAmountCents);

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'total_amount_cents': totalAmountCents,
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
      paidAmountCents: paidAmountCents ?? this.paidAmountCents,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
