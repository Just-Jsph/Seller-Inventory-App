import '../../core/utils/money.dart';

class DebtItemModel {
  final int? id;
  final int debtId;
  final int productId;
  final String productName;
  final double quantity;
  final int unitPriceCents;
  final int subtotalCents;
  final DateTime createdAt;
  final DateTime updatedAt;

  DebtItemModel({
    this.id,
    required this.debtId,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPriceCents,
    required this.subtotalCents,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  double get unitPrice => Money.toDouble(unitPriceCents);
  double get subtotal => Money.toDouble(subtotalCents);

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'debt_id': debtId,
      'product_id': productId,
      'product_name': productName,
      'quantity': quantity,
      'unit_price_cents': unitPriceCents,
      'subtotal_cents': subtotalCents,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory DebtItemModel.fromMap(Map<String, dynamic> map) {
    return DebtItemModel(
      id: map['id'] as int?,
      debtId: map['debt_id'] as int,
      productId: map['product_id'] as int,
      productName: map['product_name'] as String,
      quantity: (map['quantity'] as num).toDouble(),
      unitPriceCents: map['unit_price_cents'] as int,
      subtotalCents: map['subtotal_cents'] as int,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  DebtItemModel copyWith({
    int? id,
    int? debtId,
    int? productId,
    String? productName,
    double? quantity,
    int? unitPriceCents,
    int? subtotalCents,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DebtItemModel(
      id: id ?? this.id,
      debtId: debtId ?? this.debtId,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      quantity: quantity ?? this.quantity,
      unitPriceCents: unitPriceCents ?? this.unitPriceCents,
      subtotalCents: subtotalCents ?? this.subtotalCents,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
