import '../../domain/entities/device_entity.dart';
import '../../domain/enums/device_category.dart';
import '../../domain/repositories/device_repository.dart';
import '../datasources/local/database_helper.dart';

class DeviceRepositoryImpl implements DeviceRepository {
  final DatabaseHelper dbHelper;

  DeviceRepositoryImpl({DatabaseHelper? dbHelper})
      : dbHelper = dbHelper ?? DatabaseHelper.instance;

  @override
  Future<List<DeviceEntity>> getDevicesByCustomerId(int customerId) async {
    final db = await dbHelper.database;
    final results = await db.query(
      'devices',
      where: 'customerId = ?',
      whereArgs: [customerId],
      orderBy: 'id DESC',
    );
    return results.map((m) => DeviceEntity.fromMap(m)).toList();
  }

  @override
  Future<DeviceEntity?> getDeviceById(int id) async {
    final db = await dbHelper.database;
    final results = await db.query(
      'devices',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (results.isEmpty) return null;
    return DeviceEntity.fromMap(results.first);
  }

  @override
  Future<List<DeviceEntity>> getDevicesByCategory(DeviceCategory category) async {
    final db = await dbHelper.database;
    final results = await db.query(
      'devices',
      where: 'category = ?',
      whereArgs: [category.code],
      orderBy: 'id DESC',
    );
    return results.map((m) => DeviceEntity.fromMap(m)).toList();
  }

  @override
  Future<List<DeviceEntity>> searchDevices(String query) async {
    final db = await dbHelper.database;
    final cleanQuery = '%${query.trim()}%';
    final results = await db.query(
      'devices',
      where: 'brand LIKE ? OR model LIKE ? OR serialNumber LIKE ? OR deviceType LIKE ? OR carVehicleInfo LIKE ? OR medicalFacility LIKE ?',
      whereArgs: [cleanQuery, cleanQuery, cleanQuery, cleanQuery, cleanQuery, cleanQuery],
      limit: 25,
    );
    return results.map((m) => DeviceEntity.fromMap(m)).toList();
  }

  @override
  Future<int> createDevice(DeviceEntity device) async {
    final db = await dbHelper.database;
    return await db.insert('devices', device.toMap());
  }

  @override
  Future<bool> updateDevice(DeviceEntity device) async {
    if (device.id == null) return false;
    final db = await dbHelper.database;
    final rows = await db.update(
      'devices',
      device.toMap(),
      where: 'id = ?',
      whereArgs: [device.id],
    );
    return rows > 0;
  }

  @override
  Future<bool> deleteDevice(int id) async {
    final db = await dbHelper.database;
    final rows = await db.delete('devices', where: 'id = ?', whereArgs: [id]);
    return rows > 0;
  }

  @override
  Future<int> getDeviceCount() async {
    final db = await dbHelper.database;
    final res = await db.rawQuery('SELECT COUNT(*) as count FROM devices');
    return (res.first['count'] as int?) ?? 0;
  }
}
