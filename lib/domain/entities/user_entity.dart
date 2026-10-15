import '../enums/user_role.dart';

class UserEntity {
  final int? id;
  final String username;
  final String displayName;
  final String pinCode;
  final UserRole role;
  final bool isActive;
  final DateTime createdAt;

  const UserEntity({
    this.id,
    required this.username,
    required this.displayName,
    required this.pinCode,
    required this.role,
    this.isActive = true,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'username': username,
      'displayName': displayName,
      'pinCode': pinCode,
      'role': role.code,
      'isActive': isActive ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory UserEntity.fromMap(Map<String, dynamic> map) {
    return UserEntity(
      id: map['id'] as int?,
      username: map['username'] as String,
      displayName: map['displayName'] as String,
      pinCode: map['pinCode'] as String,
      role: UserRole.fromCode(map['role'] as String),
      isActive: (map['isActive'] as int) == 1,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }
}
