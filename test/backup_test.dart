import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sabr_electronics/data/services/backup_service.dart';

void main() {
  late Directory tempDir;
  late String testDbPath;
  late BackupService backupService;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('sabr_backup_test_');
    testDbPath = '${tempDir.path}/sabr_test.db';

    // إنشاء قاعدة بيانات حقيقية لاختبار النسخ
    final db = await databaseFactory.openDatabase(
      testDbPath,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, version) async {
          await db.execute('CREATE TABLE settings (key TEXT PRIMARY KEY, value TEXT NOT NULL, updatedAt TEXT);');
          await db.execute('CREATE TABLE audit_logs (id INTEGER PRIMARY KEY AUTOINCREMENT, userId INTEGER, action TEXT, entityName TEXT, entityId TEXT, details TEXT, createdAt TEXT);');
          await db.insert('settings', {'key': 'shop_name', 'value': 'صبر إلكترونكس للتجارب'});
        },
      ),
    );
    await db.close();

    backupService = BackupService();
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('BackupService Tests', () {
    test('التحقق من سلامة ملف قاعدة البيانات عبر verifyBackup', () async {
      // ملف صالح
      final isValid = await backupService.verifyBackup(testDbPath);
      expect(isValid, isTrue);

      // ملف عشوائي غير صالح
      final fakeFilePath = '${tempDir.path}/corrupt.db';
      await File(fakeFilePath).writeAsString('THIS IS NOT A SQLITE DATABASE');
      final isFakeValid = await backupService.verifyBackup(fakeFilePath);
      expect(isFakeValid, isFalse);
    });

    test('فحص BackupFileInfo وحجم الملف وتنسيقه', () {
      final info = BackupFileInfo(
        path: '/test/path/sabr_backup_20261016_120000.db',
        fileName: 'sabr_backup_20261016_120000.db',
        createdAt: DateTime(2026, 10, 16, 12, 0),
        sizeInBytes: 2048 * 1024, // 2 MB
      );

      expect(info.fileName, equals('sabr_backup_20261016_120000.db'));
      expect(info.formattedSize, contains('2.00 م.ب'));
      expect(info.formattedDate, equals('2026-10-16 12:00'));
    });
  });
}
