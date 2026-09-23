import '../../core/utils/money.dart';

class DebtPaymentModel {
  final int? id;
  final int debtId;
  final int userId;
  final int amountCents;
  final String paymentMethod;
  final DateTime paymentDate;
  final String? note;
  final DateTime createdAt;
  final DateTime updatedAt;

  DebtPaymentModel({
    this.id,
    required this.debtId,
    required this.userId,
    required this.amountCents,
    this.paymentMethod = 'CASH',
    DateTime? paymentDate,
    this.note,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : paymentDate = paymentDate ?? DateTime.now(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  double get amount => Money.toDouble(amountCents);
  String get formattedAmount => Money.format(amountCents);

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'debt_id': debtId,
      'user_id': userId,
      'amount_cents': amountCents,
      'payment_method': paymentMethod,
      'payment_date': paymentDate.toIso8601String(),
      'note': note,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory DebtPaymentModel.fromMap(Map<String, dynamic> map) {
    return DebtPaymentModel(
      id: map['id'] as int?,
      debtId: map['debt_id'] as int,
      userId: map['user_id'] as int,
      amountCents: map['amount_cents'] as int,
      paymentMethod: (map['payment_method'] as String?) ?? 'CASH',
      paymentDate: DateTime.parse(map['payment_date'] as String),
      note: map['note'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  DebtPaymentModel copyWith({
    int? id,
    int? debtId,
    int? userId,
    int? amountCents,
    String? paymentMethod,
    DateTime? paymentDate,
    String? note,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DebtPaymentModel(
      id: id ?? this.id,
      debtId: debtId ?? this.debtId,
      userId: userId ?? this.userId,
      amountCents: amountCents ?? this.amountCents,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentDate: paymentDate ?? this.paymentDate,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
