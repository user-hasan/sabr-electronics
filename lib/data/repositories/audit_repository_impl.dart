import '../../domain/repositories/audit_repository.dart';
import '../datasources/local/database_helper.dart';

class AuditRepositoryImpl implements AuditRepository {
  final DatabaseHelper dbHelper;

  AuditRepositoryImpl({DatabaseHelper? dbHelper})
      : dbHelper = dbHelper ?? DatabaseHelper.instance;

  @override
  Future<void> logAction({
    int? userId,
    required String action,
    required String entityName,
    required String entityId,
    String? details,
  }) async {
    final db = await dbHelper.database;
    await db.insert('audit_logs', {
      'userId': userId,
      'action': action,
      'entityName': entityName,
      'entityId': entityId,
      'details': details,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  @override
  Future<List<Map<String, dynamic>>> getAuditLogs({int limit = 100, int offset = 0}) async {
    final db = await dbHelper.database;
    return await db.query(
      'audit_logs',
      orderBy: 'id DESC',
      limit: limit,
      offset: offset,
    );
  }
}
