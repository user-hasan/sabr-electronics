import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sqflite/sqflite.dart';
import '../../domain/entities/app_settings_entity.dart';
import '../../domain/repositories/settings_repository.dart';
import '../datasources/local/database_helper.dart';

/// تطبيق مستودع الإعدادات المركزي بالاعتماد على SQLite و FlutterSecureStorage
class SettingsRepositoryImpl implements SettingsRepository {
  final DatabaseHelper dbHelper;
  final FlutterSecureStorage secureStorage;

  SettingsRepositoryImpl({
    DatabaseHelper? dbHelper,
    FlutterSecureStorage? secureStorage,
  })  : dbHelper = dbHelper ?? DatabaseHelper.instance,
        secureStorage = secureStorage ?? const FlutterSecureStorage();

  @override
  Future<AppSettingsEntity> getSettings() async {
    final db = await dbHelper.database;
    final rows = await db.query('settings');

    final Map<String, String> map = {};
    for (final row in rows) {
      final key = row['key'] as String?;
      final value = row['value'] as String?;
      if (key != null && value != null) {
        map[key] = value;
      }
    }

    return AppSettingsEntity.fromDbMap(map);
  }

  @override
  Future<bool> updateSetting(String key, String value) async {
    final db = await dbHelper.database;
    final now = DateTime.now().toIso8601String();

    final count = await db.insert(
      'settings',
      {
        'key': key,
        'value': value,
        'updatedAt': now,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    return count > 0;
  }

  @override
  Future<bool> saveSettings(AppSettingsEntity settings) async {
    final db = await dbHelper.database;
    final now = DateTime.now().toIso8601String();
    final map = settings.toDbMap();

    await db.transaction((txn) async {
      for (final entry in map.entries) {
        await txn.insert(
          'settings',
          {
            'key': entry.key,
            'value': entry.value,
            'updatedAt': now,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });

    return true;
  }

  @override
  Future<String?> getSecureKey(String key) async {
    return await secureStorage.read(key: key);
  }

  @override
  Future<void> setSecureKey(String key, String value) async {
    await secureStorage.write(key: key, value: value);
  }
}
