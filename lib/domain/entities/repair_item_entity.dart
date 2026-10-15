class RepairItemEntity {
  final int? id;
  final int repairRecordId;
  final String itemType; // 'spare_part' or 'labor'
  final int? sparePartId;
  final String description;
  final double unitCost;
  final double unitPrice;
  final int quantity;
  final double totalPrice;
  final DateTime createdAt;

  const RepairItemEntity({
    this.id,
    required this.repairRecordId,
    required this.itemType,
    this.sparePartId,
    required this.description,
    this.unitCost = 0.0,
    required this.unitPrice,
    this.quantity = 1,
    required this.totalPrice,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'repairRecordId': repairRecordId,
      'itemType': itemType,
      if (sparePartId != null) 'sparePartId': sparePartId,
      'description': description,
      'unitCost': unitCost,
      'unitPrice': unitPrice,
      'quantity': quantity,
      'totalPrice': totalPrice,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory RepairItemEntity.fromMap(Map<String, dynamic> map) {
    return RepairItemEntity(
      id: map['id'] as int?,
      repairRecordId: map['repairRecordId'] as int,
      itemType: map['itemType'] as String,
      sparePartId: map['sparePartId'] as int?,
      description: map['description'] as String,
      unitCost: (map['unitCost'] as num).toDouble(),
      unitPrice: (map['unitPrice'] as num).toDouble(),
      quantity: (map['quantity'] as int?) ?? 1,
      totalPrice: (map['totalPrice'] as num).toDouble(),
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }
}
