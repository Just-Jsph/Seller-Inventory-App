import '../../core/utils/money.dart';

class InventoryTransactionModel {
  final int? id;
  final int userId;
  final int productId;
  final String transactionType; // 'STOCK_IN', 'STOCK_OUT', 'ADJUSTMENT', 'SALE', 'RETURN', 'DAMAGE'
  final double quantity;
  final int? unitCostCents;
  final String? note;
  final String? referenceId;
  final DateTime createdAt;
  final DateTime updatedAt;

  InventoryTransactionModel({
    this.id,
    required this.userId,
    required this.productId,
    required this.transactionType,
    required this.quantity,
    this.unitCostCents,
    this.note,
    this.referenceId,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  double? get unitCost => unitCostCents != null ? Money.toDouble(unitCostCents!) : null;

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'product_id': productId,
      'transaction_type': transactionType,
      'quantity': quantity,
      'unit_cost_cents': unitCostCents,
      'note': note,
      'reference_id': referenceId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory InventoryTransactionModel.fromMap(Map<String, dynamic> map) {
    return InventoryTransactionModel(
      id: map['id'] as int?,
      userId: map['user_id'] as int,
      productId: map['product_id'] as int,
      transactionType: map['transaction_type'] as String,
      quantity: (map['quantity'] as num).toDouble(),
      unitCostCents: map['unit_cost_cents'] as int?,
      note: map['note'] as String?,
      referenceId: map['reference_id'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  InventoryTransactionModel copyWith({
    int? id,
    int? userId,
    int? productId,
    String? transactionType,
    double? quantity,
    int? unitCostCents,
    String? note,
    String? referenceId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return InventoryTransactionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      productId: productId ?? this.productId,
      transactionType: transactionType ?? this.transactionType,
      quantity: quantity ?? this.quantity,
      unitCostCents: unitCostCents ?? this.unitCostCents,
      note: note ?? this.note,
      referenceId: referenceId ?? this.referenceId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
