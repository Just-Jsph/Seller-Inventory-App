import '../../core/utils/money.dart';

class SaleModel {
  final int? id;
  final int userId;
  final String invoiceNumber;
  final String? customerName;
  final String? customerPhone;
  final int totalAmountCents;
  final int discountCents;
  final int paidAmountCents;
  final String paymentMethod; // 'CASH', 'E-WALLET', 'CARD', 'DEBT', 'OTHER'
  final String paymentStatus; // 'PAID', 'PARTIAL', 'UNPAID'
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  SaleModel({
    this.id,
    required this.userId,
    required this.invoiceNumber,
    this.customerName,
    this.customerPhone,
    required this.totalAmountCents,
    this.discountCents = 0,
    required this.paidAmountCents,
    this.paymentMethod = 'CASH',
    this.paymentStatus = 'PAID',
    this.notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  double get totalAmount => Money.toDouble(totalAmountCents);
  double get discount => Money.toDouble(discountCents);
  double get paidAmount => Money.toDouble(paidAmountCents);
  double get netAmount => Money.toDouble(totalAmountCents - discountCents);
  String get formattedTotal => Money.format(totalAmountCents);

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'invoice_number': invoiceNumber,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'total_amount_cents': totalAmountCents,
      'discount_cents': discountCents,
      'paid_amount_cents': paidAmountCents,
      'payment_method': paymentMethod,
      'payment_status': paymentStatus,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory SaleModel.fromMap(Map<String, dynamic> map) {
    return SaleModel(
      id: map['id'] as int?,
      userId: map['user_id'] as int,
      invoiceNumber: map['invoice_number'] as String,
      customerName: map['customer_name'] as String?,
      customerPhone: map['customer_phone'] as String?,
      totalAmountCents: map['total_amount_cents'] as int,
      discountCents: (map['discount_cents'] as int?) ?? 0,
      paidAmountCents: map['paid_amount_cents'] as int,
      paymentMethod: (map['payment_method'] as String?) ?? 'CASH',
      paymentStatus: (map['payment_status'] as String?) ?? 'PAID',
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  SaleModel copyWith({
    int? id,
    int? userId,
    String? invoiceNumber,
    String? customerName,
    String? customerPhone,
    int? totalAmountCents,
    int? discountCents,
    int? paidAmountCents,
    String? paymentMethod,
    String? paymentStatus,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SaleModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      totalAmountCents: totalAmountCents ?? this.totalAmountCents,
      discountCents: discountCents ?? this.discountCents,
      paidAmountCents: paidAmountCents ?? this.paidAmountCents,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
