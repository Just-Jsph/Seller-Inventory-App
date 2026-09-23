import '../../core/utils/money.dart';

class ExpenseModel {
  final int? id;
  final int userId;
  final int? categoryId;
  final String title;
  final int amountCents;
  final DateTime expenseDate;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  ExpenseModel({
    this.id,
    required this.userId,
    this.categoryId,
    required this.title,
    required this.amountCents,
    DateTime? expenseDate,
    this.notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : expenseDate = expenseDate ?? DateTime.now(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  double get amount => Money.toDouble(amountCents);
  String get formattedAmount => Money.format(amountCents);

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'category_id': categoryId,
      'title': title,
      'amount_cents': amountCents,
      'expense_date': expenseDate.toIso8601String(),
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory ExpenseModel.fromMap(Map<String, dynamic> map) {
    return ExpenseModel(
      id: map['id'] as int?,
      userId: map['user_id'] as int,
      categoryId: map['category_id'] as int?,
      title: map['title'] as String,
      amountCents: map['amount_cents'] as int,
      expenseDate: DateTime.parse(map['expense_date'] as String),
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  ExpenseModel copyWith({
    int? id,
    int? userId,
    int? categoryId,
    String? title,
    int? amountCents,
    DateTime? expenseDate,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ExpenseModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      categoryId: categoryId ?? this.categoryId,
      title: title ?? this.title,
      amountCents: amountCents ?? this.amountCents,
      expenseDate: expenseDate ?? this.expenseDate,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
