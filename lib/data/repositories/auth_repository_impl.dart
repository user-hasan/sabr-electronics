import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/enums/user_role.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/local/database_helper.dart';

class AuthRepositoryImpl implements AuthRepository {
  final DatabaseHelper dbHelper;
  final FlutterSecureStorage secureStorage;

  static const String _currentUserKey = 'current_user_id';
  static const String _managerPinKey = 'manager_secure_pin';

  UserEntity? _cachedCurrentUser;

  AuthRepositoryImpl({
    DatabaseHelper? dbHelper,
    FlutterSecureStorage? secureStorage,
  })  : dbHelper = dbHelper ?? DatabaseHelper.instance,
        secureStorage = secureStorage ?? const FlutterSecureStorage();

  @override
  Future<List<UserEntity>> getAllUsers() async {
    final db = await dbHelper.database;
    final results = await db.query('users', orderBy: 'id ASC');
    return results.map((m) => UserEntity.fromMap(m)).toList();
  }

  @override
  Future<UserEntity?> getUserByUsername(String username) async {
    final db = await dbHelper.database;
    final results = await db.query(
      'users',
      where: 'username = ?',
      whereArgs: [username],
      limit: 1,
    );
    if (results.isEmpty) return null;
    return UserEntity.fromMap(results.first);
  }

  @override
  Future<UserEntity?> verifyPin(String pin) async {
    final db = await dbHelper.database;
    final results = await db.query(
      'users',
      where: 'pinCode = ? AND isActive = 1',
      whereArgs: [pin],
      limit: 1,
    );
    if (results.isEmpty) return null;
    final user = UserEntity.fromMap(results.first);
    await setCurrentUser(user);
    return user;
  }

  @override
  Future<bool> verifyManagerPin(String pin) async {
    // التحقق من PIN المدير المحفوظ مشفراً، أو مستخدم صاحب رتبة owner
    final storedPin = await secureStorage.read(key: _managerPinKey);
    if (storedPin != null && storedPin == pin) {
      return true;
    }

    final db = await dbHelper.database;
    final results = await db.query(
      'users',
      where: 'pinCode = ? AND role = ? AND isActive = 1',
      whereArgs: [pin, UserRole.owner.code],
      limit: 1,
    );
    return results.isNotEmpty;
  }

  @override
  Future<int> createUser(UserEntity user) async {
    final db = await dbHelper.database;
    return await db.insert('users', user.toMap());
  }

  @override
  Future<bool> updateUserPin(int userId, String newPin) async {
    final db = await dbHelper.database;
    final rows = await db.update(
      'users',
      {'pinCode': newPin},
      where: 'id = ?',
      whereArgs: [userId],
    );
    return rows > 0;
  }

  @override
  Future<bool> setUserActive(int userId, bool isActive) async {
    final db = await dbHelper.database;
    final rows = await db.update(
      'users',
      {'isActive': isActive ? 1 : 0},
      where: 'id = ?',
      whereArgs: [userId],
    );
    return rows > 0;
  }

  @override
  Future<UserEntity?> getCurrentUser() async {
    if (_cachedCurrentUser != null) return _cachedCurrentUser;

    final userIdStr = await secureStorage.read(key: _currentUserKey);
    if (userIdStr == null) {
      // إرجاع المدير الافتراضي إن وُجد
      final users = await getAllUsers();
      if (users.isNotEmpty) {
        _cachedCurrentUser = users.first;
        return _cachedCurrentUser;
      }
      return null;
    }

    final userId = int.tryParse(userIdStr);
    if (userId == null) return null;

    final db = await dbHelper.database;
    final results = await db.query('users', where: 'id = ?', whereArgs: [userId], limit: 1);
    if (results.isEmpty) return null;

    _cachedCurrentUser = UserEntity.fromMap(results.first);
    return _cachedCurrentUser;
  }

  @override
  Future<void> setCurrentUser(UserEntity user) async {
    _cachedCurrentUser = user;
    if (user.id != null) {
      await secureStorage.write(key: _currentUserKey, value: user.id.toString());
    }
  }

  @override
  Future<bool> hasPermission(UserRole role, String action) async {
    // تطبيق مصفوفة الصلاحيات من 06_SECURITY.md
    switch (action) {
      case 'intake_device':
      case 'update_diagnostic':
      case 'add_spare_parts':
        return true; // متاح للكل
      case 'receive_payment':
        return role == UserRole.owner || role == UserRole.reception;
      case 'apply_discount':
      case 'delete_record':
      case 'view_reports':
      case 'restore_backup':
        return role == UserRole.owner;
      default:
        return false;
    }
  }
}
