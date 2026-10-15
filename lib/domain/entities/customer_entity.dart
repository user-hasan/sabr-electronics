class CustomerEntity {
  final int? id;
  final String name;
  final String customerType; // individual, car_workshop, medical_center
  final String phone;
  final String? alternatePhone;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CustomerEntity({
    this.id,
    required this.name,
    this.customerType = 'individual',
    required this.phone,
    this.alternatePhone,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'customerType': customerType,
      'phone': phone,
      'alternatePhone': alternatePhone,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory CustomerEntity.fromMap(Map<String, dynamic> map) {
    return CustomerEntity(
      id: map['id'] as int?,
      name: map['name'] as String,
      customerType: (map['customerType'] as String?) ?? 'individual',
      phone: map['phone'] as String,
      alternatePhone: map['alternatePhone'] as String?,
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }
}
