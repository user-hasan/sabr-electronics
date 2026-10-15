import '../entities/user_entity.dart';
import '../enums/user_role.dart';

abstract class AuthRepository {
  Future<List<UserEntity>> getAllUsers();
  Future<UserEntity?> getUserByUsername(String username);
  Future<UserEntity?> verifyPin(String pin);
  Future<bool> verifyManagerPin(String pin);
  Future<int> createUser(UserEntity user);
  Future<bool> updateUserPin(int userId, String newPin);
  Future<bool> setUserActive(int userId, bool isActive);
  Future<UserEntity?> getCurrentUser();
  Future<void> setCurrentUser(UserEntity user);
  Future<bool> hasPermission(UserRole role, String action);
}
