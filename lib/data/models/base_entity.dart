/// Data models for sales, inventory, products, and customers will reside here.
class BaseEntity {
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;

  const BaseEntity({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
  });
}
