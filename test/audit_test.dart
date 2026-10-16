import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sabr_electronics/data/datasources/local/database_helper.dart';
import 'package:sabr_electronics/data/repositories/audit_repository_impl.dart';

void main() {
  late Database db;
  late AuditRepositoryImpl auditRepo;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    db = await databaseFactory.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE audit_logs (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              userId INTEGER,
              action TEXT NOT NULL,
              entityName TEXT NOT NULL,
              entityId TEXT NOT NULL,
              details TEXT,
              createdAt TEXT NOT NULL
            );
          ''');
        },
      ),
    );

    DatabaseHelper.instance.databaseForTesting = db;
    auditRepo = AuditRepositoryImpl(dbHelper: DatabaseHelper.instance);
  });

  tearDown(() async {
    await db.close();
  });

  group('AuditRepository Tests', () {
    test('تسجيل عملية في سجل الرقابة واسترجاعها', () async {
      await auditRepo.logAction(
        userId: 1,
        action: 'repair_status_update',
        entityName: 'repair_record',
        entityId: '101',
        details: 'تم تغيير الحالة من قيد الفحص إلى مكتمل وجاهز للتسليم',
      );

      final logs = await auditRepo.getAuditLogs(limit: 10);
      expect(logs.length, equals(1));
      expect(logs.first['action'], equals('repair_status_update'));
      expect(logs.first['entityName'], equals('repair_record'));
      expect(logs.first['entityId'], equals('101'));
      expect(logs.first['details'], contains('جاهز للتسليم'));
    });

    test('ترتيب السجلات الرقابية تنازلياً من الأحدث إلى الأقدم', () async {
      await auditRepo.logAction(action: 'first_action', entityName: 'e1', entityId: '1');
      await auditRepo.logAction(action: 'second_action', entityName: 'e2', entityId: '2');
      await auditRepo.logAction(action: 'third_action', entityName: 'e3', entityId: '3');

      final logs = await auditRepo.getAuditLogs();
      expect(logs.length, equals(3));
      expect(logs[0]['action'], equals('third_action'));
      expect(logs[1]['action'], equals('second_action'));
      expect(logs[2]['action'], equals('first_action'));
    });
  });
}
