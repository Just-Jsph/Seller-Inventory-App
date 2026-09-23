import '../../core/utils/money.dart';

class SaleItemModel {
  final int? id;
  final int saleId;
  final int productId;
  final String productName;
  final double quantity;
  final int unitPriceCents;
  final int subtotalCents;
  final int costCents;
  final DateTime createdAt;
  final DateTime updatedAt;

  SaleItemModel({
    this.id,
    required this.saleId,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPriceCents,
    required this.subtotalCents,
    this.costCents = 0,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  double get unitPrice => Money.toDouble(unitPriceCents);
  double get subtotal => Money.toDouble(subtotalCents);
  double get cost => Money.toDouble(costCents);
  double get profit => Money.toDouble(subtotalCents - (costCents * quantity).round());

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'sale_id': saleId,
      'product_id': productId,
      'product_name': productName,
      'quantity': quantity,
      'unit_price_cents': unitPriceCents,
      'subtotal_cents': subtotalCents,
      'cost_cents': costCents,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory SaleItemModel.fromMap(Map<String, dynamic> map) {
    return SaleItemModel(
      id: map['id'] as int?,
      saleId: map['sale_id'] as int,
      productId: map['product_id'] as int,
      productName: map['product_name'] as String,
      quantity: (map['quantity'] as num).toDouble(),
      unitPriceCents: map['unit_price_cents'] as int,
      subtotalCents: map['subtotal_cents'] as int,
      costCents: (map['cost_cents'] as int?) ?? 0,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  SaleItemModel copyWith({
    int? id,
    int? saleId,
    int? productId,
    String? productName,
    double? quantity,
    int? unitPriceCents,
    int? subtotalCents,
    int? costCents,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SaleItemModel(
      id: id ?? this.id,
      saleId: saleId ?? this.saleId,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      quantity: quantity ?? this.quantity,
      unitPriceCents: unitPriceCents ?? this.unitPriceCents,
      subtotalCents: subtotalCents ?? this.subtotalCents,
      costCents: costCents ?? this.costCents,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
