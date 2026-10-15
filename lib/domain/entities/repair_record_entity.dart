import '../enums/app_currency.dart';
import '../enums/repair_status.dart';

class RepairRecordEntity {
  final int? id;
  final String recordNumber;
  final int customerId;
  final int deviceId;
  final int? technicianId;
  final DateTime receivedAt;
  final DateTime? expectedDeliveryAt;
  final DateTime? deliveredAt;
  final RepairStatus status;
  final String problemDescription;
  final String? diagnosticNotes;
  final AppCurrency currency;
  final double estimatedCost;
  final double laborCost;
  final double partsCost;
  final double totalAmount;
  final double discountAmount;
  final double paidAmount;
  final double remainingAmount;
  final int warrantyDays;
  final DateTime createdAt;
  final DateTime updatedAt;

  const RepairRecordEntity({
    this.id,
    required this.recordNumber,
    required this.customerId,
    required this.deviceId,
    this.technicianId,
    required this.receivedAt,
    this.expectedDeliveryAt,
    this.deliveredAt,
    this.status = RepairStatus.received,
    required this.problemDescription,
    this.diagnosticNotes,
    this.currency = AppCurrency.yer,
    this.estimatedCost = 0.0,
    this.laborCost = 0.0,
    this.partsCost = 0.0,
    this.totalAmount = 0.0,
    this.discountAmount = 0.0,
    this.paidAmount = 0.0,
    this.remainingAmount = 0.0,
    this.warrantyDays = 30,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'recordNumber': recordNumber,
      'customerId': customerId,
      'deviceId': deviceId,
      'technicianId': technicianId,
      'receivedAt': receivedAt.toIso8601String(),
      'expectedDeliveryAt': expectedDeliveryAt?.toIso8601String(),
      'deliveredAt': deliveredAt?.toIso8601String(),
      'status': status.code,
      'problemDescription': problemDescription,
      'diagnosticNotes': diagnosticNotes,
      'currency': currency.code,
      'estimatedCost': estimatedCost,
      'laborCost': laborCost,
      'partsCost': partsCost,
      'totalAmount': totalAmount,
      'discountAmount': discountAmount,
      'paidAmount': paidAmount,
      'remainingAmount': remainingAmount,
      'warrantyDays': warrantyDays,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory RepairRecordEntity.fromMap(Map<String, dynamic> map) {
    return RepairRecordEntity(
      id: map['id'] as int?,
      recordNumber: map['recordNumber'] as String,
      customerId: map['customerId'] as int,
      deviceId: map['deviceId'] as int,
      technicianId: map['technicianId'] as int?,
      receivedAt: DateTime.parse(map['receivedAt'] as String),
      expectedDeliveryAt: map['expectedDeliveryAt'] != null
          ? DateTime.parse(map['expectedDeliveryAt'] as String)
          : null,
      deliveredAt: map['deliveredAt'] != null
          ? DateTime.parse(map['deliveredAt'] as String)
          : null,
      status: RepairStatus.fromCode(map['status'] as String),
      problemDescription: map['problemDescription'] as String,
      diagnosticNotes: map['diagnosticNotes'] as String?,
      currency: AppCurrency.fromCode((map['currency'] as String?) ?? 'YER'),
      estimatedCost: (map['estimatedCost'] as num).toDouble(),
      laborCost: (map['laborCost'] as num).toDouble(),
      partsCost: (map['partsCost'] as num).toDouble(),
      totalAmount: (map['totalAmount'] as num).toDouble(),
      discountAmount: (map['discountAmount'] as num).toDouble(),
      paidAmount: (map['paidAmount'] as num).toDouble(),
      remainingAmount: (map['remainingAmount'] as num).toDouble(),
      warrantyDays: (map['warrantyDays'] as int?) ?? 30,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }
}
