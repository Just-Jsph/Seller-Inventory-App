import '../../core/utils/money.dart';

class ProductModel {
  final int? id;
  final int userId;
  final int? categoryId;
  final String name;
  final String? sku;
  final String? barcode;
  final int buyPriceCents; // Stored in cents (e.g. 1050 = $10.50)
  final int sellPriceCents; // Stored in cents (e.g. 1500 = $15.00)
  final double stockQuantity;
  final double minStockAlert;
  final String unit; // 'pcs', 'kg', 'box', 'liter', etc.
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  ProductModel({
    this.id,
    required this.userId,
    this.categoryId,
    required this.name,
    this.sku,
    this.barcode,
    required this.buyPriceCents,
    required this.sellPriceCents,
    this.stockQuantity = 0.0,
    this.minStockAlert = 5.0,
    this.unit = 'pcs',
    this.isActive = true,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  // Helper getters for dollar/decimal amounts
  double get buyPrice => Money.toDouble(buyPriceCents);
  double get sellPrice => Money.toDouble(sellPriceCents);
  String get formattedBuyPrice => Money.format(buyPriceCents);
  String get formattedSellPrice => Money.format(sellPriceCents);

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'category_id': categoryId,
      'name': name,
      'sku': sku,
      'barcode': barcode,
      'buy_price_cents': buyPriceCents,
      'sell_price_cents': sellPriceCents,
      'stock_quantity': stockQuantity,
      'min_stock_alert': minStockAlert,
      'unit': unit,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory ProductModel.fromMap(Map<String, dynamic> map) {
    return ProductModel(
      id: map['id'] as int?,
      userId: map['user_id'] as int,
      categoryId: map['category_id'] as int?,
      name: map['name'] as String,
      sku: map['sku'] as String?,
      barcode: map['barcode'] as String?,
      buyPriceCents: map['buy_price_cents'] as int,
      sellPriceCents: map['sell_price_cents'] as int,
      stockQuantity: (map['stock_quantity'] as num).toDouble(),
      minStockAlert: (map['min_stock_alert'] as num).toDouble(),
      unit: (map['unit'] as String?) ?? 'pcs',
      isActive: (map['is_active'] as int) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  ProductModel copyWith({
    int? id,
    int? userId,
    int? categoryId,
    String? name,
    String? sku,
    String? barcode,
    int? buyPriceCents,
    int? sellPriceCents,
    double? stockQuantity,
    double? minStockAlert,
    String? unit,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProductModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      categoryId: categoryId ?? this.categoryId,
      name: name ?? this.name,
      sku: sku ?? this.sku,
      barcode: barcode ?? this.barcode,
      buyPriceCents: buyPriceCents ?? this.buyPriceCents,
      sellPriceCents: sellPriceCents ?? this.sellPriceCents,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      minStockAlert: minStockAlert ?? this.minStockAlert,
      unit: unit ?? this.unit,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
