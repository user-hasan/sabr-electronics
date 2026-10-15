import '../enums/app_currency.dart';

class SparePartEntity {
  final int? id;
  final String name;
  final String? partCode;
  final String category;
  final double costPrice;
  final double sellingPrice;
  final AppCurrency currency;
  final int stockQuantity;
  final int minStockAlert;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SparePartEntity({
    this.id,
    required this.name,
    this.partCode,
    required this.category,
    this.costPrice = 0.0,
    this.sellingPrice = 0.0,
    this.currency = AppCurrency.yer,
    this.stockQuantity = 0,
    this.minStockAlert = 2,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isLowStock => stockQuantity <= minStockAlert;

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'partCode': partCode,
      'category': category,
      'costPrice': costPrice,
      'sellingPrice': sellingPrice,
      'currency': currency.code,
      'stockQuantity': stockQuantity,
      'minStockAlert': minStockAlert,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory SparePartEntity.fromMap(Map<String, dynamic> map) {
    return SparePartEntity(
      id: map['id'] as int?,
      name: map['name'] as String,
      partCode: map['partCode'] as String?,
      category: map['category'] as String,
      costPrice: (map['costPrice'] as num).toDouble(),
      sellingPrice: (map['sellingPrice'] as num).toDouble(),
      currency: AppCurrency.fromCode((map['currency'] as String?) ?? 'YER'),
      stockQuantity: map['stockQuantity'] as int,
      minStockAlert: map['minStockAlert'] as int,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }
}
