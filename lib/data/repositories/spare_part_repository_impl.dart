import '../../domain/entities/spare_part_entity.dart';
import '../../domain/repositories/spare_part_repository.dart';
import '../datasources/local/database_helper.dart';

class SparePartRepositoryImpl implements SparePartRepository {
  final DatabaseHelper dbHelper;

  SparePartRepositoryImpl({DatabaseHelper? dbHelper})
      : dbHelper = dbHelper ?? DatabaseHelper.instance;

  @override
  Future<List<SparePartEntity>> getAllSpareParts() async {
    final db = await dbHelper.database;
    final results = await db.query(
      'spare_parts',
      orderBy: 'name ASC',
    );
    return results.map((m) => SparePartEntity.fromMap(m)).toList();
  }

  @override
  Future<SparePartEntity?> getSparePartById(int id) async {
    final db = await dbHelper.database;
    final results = await db.query(
      'spare_parts',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (results.isEmpty) return null;
    return SparePartEntity.fromMap(results.first);
  }

  @override
  Future<SparePartEntity?> getSparePartByCode(String code) async {
    final db = await dbHelper.database;
    final cleanCode = code.trim();
    final results = await db.query(
      'spare_parts',
      where: 'partCode = ?',
      whereArgs: [cleanCode],
      limit: 1,
    );
    if (results.isEmpty) return null;
    return SparePartEntity.fromMap(results.first);
  }

  @override
  Future<List<SparePartEntity>> searchSpareParts(String query, {String? category}) async {
    final db = await dbHelper.database;
    final cleanQuery = '%${query.trim()}%';
    String whereClause;
    List<dynamic> whereArgs;

    if (category != null && category.isNotEmpty && category != 'all') {
      whereClause = '(name LIKE ? OR partCode LIKE ?) AND category = ?';
      whereArgs = [cleanQuery, cleanQuery, category];
    } else {
      whereClause = 'name LIKE ? OR partCode LIKE ?';
      whereArgs = [cleanQuery, cleanQuery];
    }

    final results = await db.query(
      'spare_parts',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'name ASC',
    );
    return results.map((m) => SparePartEntity.fromMap(m)).toList();
  }

  @override
  Future<List<SparePartEntity>> getLowStockParts() async {
    final db = await dbHelper.database;
    final results = await db.rawQuery(
      'SELECT * FROM spare_parts WHERE stockQuantity <= minStockAlert ORDER BY stockQuantity ASC',
    );
    return results.map((m) => SparePartEntity.fromMap(m)).toList();
  }

  @override
  Future<int> insertSparePart(SparePartEntity part) async {
    final db = await dbHelper.database;
    return await db.insert('spare_parts', part.toMap());
  }

  @override
  Future<int> updateSparePart(SparePartEntity part) async {
    if (part.id == null) return 0;
    final db = await dbHelper.database;
    return await db.update(
      'spare_parts',
      part.toMap(),
      where: 'id = ?',
      whereArgs: [part.id],
    );
  }

  @override
  Future<int> deleteSparePart(int id) async {
    final db = await dbHelper.database;
    return await db.delete('spare_parts', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<bool> adjustStock(int id, int quantityDelta) async {
    final db = await dbHelper.database;
    return await db.transaction((txn) async {
      final res = await txn.query(
        'spare_parts',
        columns: ['stockQuantity'],
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      if (res.isEmpty) return false;

      final currentStock = res.first['stockQuantity'] as int;
      final newStock = currentStock + quantityDelta;
      if (newStock < 0) return false; // منع الرصيد السالب

      final now = DateTime.now().toIso8601String();
      final updatedRows = await txn.update(
        'spare_parts',
        {
          'stockQuantity': newStock,
          'updatedAt': now,
        },
        where: 'id = ?',
        whereArgs: [id],
      );

      return updatedRows > 0;
    });
  }
}
