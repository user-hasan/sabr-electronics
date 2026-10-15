import '../enums/device_category.dart';

class DeviceEntity {
  final int? id;
  final int customerId;
  final DeviceCategory category;
  final String deviceType;
  final String brand;
  final String model;
  final String? serialNumber;
  final String? carVehicleInfo;
  final String? medicalFacility;
  final String? operatingVoltage;
  final String? receivedAccessories;
  final String? physicalCondition;
  final DateTime createdAt;
  final DateTime updatedAt;

  const DeviceEntity({
    this.id,
    required this.customerId,
    required this.category,
    required this.deviceType,
    required this.brand,
    required this.model,
    this.serialNumber,
    this.carVehicleInfo,
    this.medicalFacility,
    this.operatingVoltage,
    this.receivedAccessories,
    this.physicalCondition,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'customerId': customerId,
      'category': category.code,
      'deviceType': deviceType,
      'brand': brand,
      'model': model,
      'serialNumber': serialNumber,
      'carVehicleInfo': carVehicleInfo,
      'medicalFacility': medicalFacility,
      'operatingVoltage': operatingVoltage,
      'receivedAccessories': receivedAccessories,
      'physicalCondition': physicalCondition,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory DeviceEntity.fromMap(Map<String, dynamic> map) {
    return DeviceEntity(
      id: map['id'] as int?,
      customerId: map['customerId'] as int,
      category: DeviceCategory.fromCode(map['category'] as String),
      deviceType: map['deviceType'] as String,
      brand: map['brand'] as String,
      model: map['model'] as String,
      serialNumber: map['serialNumber'] as String?,
      carVehicleInfo: map['carVehicleInfo'] as String?,
      medicalFacility: map['medicalFacility'] as String?,
      operatingVoltage: map['operatingVoltage'] as String?,
      receivedAccessories: map['receivedAccessories'] as String?,
      physicalCondition: map['physicalCondition'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }
}
