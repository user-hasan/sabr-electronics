import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../datasources/local/database_helper.dart';
import '../../domain/repositories/audit_repository.dart';
import '../repositories/audit_repository_impl.dart';

/// كائن معلومات ملف النسخة الاحتياطية
class BackupFileInfo {
  final String path;
  final String fileName;
  final DateTime createdAt;
  final int sizeInBytes;

  const BackupFileInfo({
    required this.path,
    required this.fileName,
    required this.createdAt,
    required this.sizeInBytes,
  });

  String get formattedSize {
    if (sizeInBytes < 1024) return '$sizeInBytes بايت';
    if (sizeInBytes < 1024 * 1024) return '${(sizeInBytes / 1024).toStringAsFixed(1)} ك.ب';
    return '${(sizeInBytes / (1024 * 1024)).toStringAsFixed(2)} م.ب';
  }

  String get formattedDate {
    return DateFormat('yyyy-MM-dd HH:mm').format(createdAt);
  }
}

/// خدمة النسخ الاحتياطي والاستعادة الذاتية مع ضمانات التحقق والتراجع الآمن
class BackupService {
  final DatabaseHelper dbHelper;
  final AuditRepository auditRepo;

  BackupService({
    DatabaseHelper? dbHelper,
    AuditRepository? auditRepo,
  })  : dbHelper = dbHelper ?? DatabaseHelper.instance,
        auditRepo = auditRepo ?? AuditRepositoryImpl();

  /// المجلد الافتراضي لتخزين النسخ الاحتياطية المحلية
  Future<Directory> getBackupsDirectory() async {
    Directory baseDir;
    try {
      baseDir = await getApplicationDocumentsDirectory();
    } catch (_) {
      baseDir = await getApplicationSupportDirectory();
    }
    final backupDir = Directory(p.join(baseDir.path, 'sabr_backups'));
    if (!await backupDir.exists()) {
      await backupDir.create(recursive: true);
    }
    return backupDir;
  }

  /// إنشاء نسخة احتياطية محلية متزامنة
  Future<BackupFileInfo> createBackup({int? activeUserId}) async {
    // 1. مزامنة سجلات WAL لضمان اكتمال البيانات في الملف الأساسي
    await dbHelper.checkpoint();

    final dbPath = await dbHelper.getDbPath();
    final originalFile = File(dbPath);
    if (!await originalFile.exists()) {
      throw Exception('ملف قاعدة البيانات غير موجود في المسار: $dbPath');
    }

    final backupDir = await getBackupsDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final backupFileName = 'sabr_backup_$timestamp.db';
    final backupFilePath = p.join(backupDir.path, backupFileName);

    final backupFile = await originalFile.copy(backupFilePath);
    final stat = await backupFile.stat();

    // توثيق العملية في سجل الرقابة
    await auditRepo.logAction(
      userId: activeUserId,
      action: 'backup_create',
      entityName: 'database',
      entityId: backupFileName,
      details: 'تم إنشاء نسخة احتياطية بحجم: ${(stat.size / 1024).toStringAsFixed(1)} KB',
    );

    return BackupFileInfo(
      path: backupFilePath,
      fileName: backupFileName,
      createdAt: stat.modified,
      sizeInBytes: stat.size,
    );
  }

  /// استعراض قائمة النسخ الاحتياطية المتوفرة مرتبة من الأحدث إلى الأقدم
  Future<List<BackupFileInfo>> listBackups() async {
    final backupDir = await getBackupsDirectory();
    final entities = backupDir.listSync();
    final List<BackupFileInfo> backups = [];

    for (final entity in entities) {
      if (entity is File && entity.path.endsWith('.db')) {
        final stat = entity.statSync();
        backups.add(BackupFileInfo(
          path: entity.path,
          fileName: p.basename(entity.path),
          createdAt: stat.modified,
          sizeInBytes: stat.size,
        ));
      }
    }

    backups.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return backups;
  }

  /// التحقق من صحة ملف النسخة الاحتياطية وهيكلها
  Future<bool> verifyBackup(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) return false;

    // فحص ترويسة SQLite (أول 16 بايت يجب أن تبدأ بـ "SQLite format 3\000")
    try {
      final bytes = await file.openRead(0, 16).first;
      if (bytes.length < 16) return false;
      final header = String.fromCharCodes(bytes.sublist(0, 15));
      if (header != 'SQLite format 3') return false;
    } catch (_) {
      return false;
    }

    // فحص فتح قاعدة البيانات والتحقق من الجداول الأساسية
    Database? testDb;
    try {
      testDb = await databaseFactory.openDatabase(
        filePath,
        options: OpenDatabaseOptions(readOnly: true),
      );

      final tables = await testDb.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name IN ('settings', 'repairs', 'customers', 'repair_records');",
      );

      return tables.isNotEmpty;
    } catch (_) {
      return false;
    } finally {
      await testDb?.close();
    }
  }

  /// استعادة نسخة احتياطية بأمان مع آلية Rollback تلقائية عند الفشل
  Future<bool> restoreBackup(String backupFilePath, {int? activeUserId}) async {
    final isValid = await verifyBackup(backupFilePath);
    if (!isValid) {
      throw Exception('ملف النسخة الاحتياطية غير صالح أو تالف.');
    }

    final dbPath = await dbHelper.getDbPath();
    final currentDbFile = File(dbPath);
    final rollbackPath = '$dbPath.rollback';
    final rollbackFile = File(rollbackPath);

    // 1. إغلاق قاعدة البيانات الحالية
    await dbHelper.close();

    // 2. أخذ نسخة تراجع مؤقتة
    if (await currentDbFile.exists()) {
      if (await rollbackFile.exists()) {
        await rollbackFile.delete();
      }
      await currentDbFile.copy(rollbackPath);
    }

    try {
      // 3. استبدال الملف بقاعدة النسخة الاحتياطية
      final backupFile = File(backupFilePath);
      await backupFile.copy(dbPath);

      // 4. فتح قاعدة البيانات المستعادة وفحص سلامتها
      final restoredDb = await dbHelper.database;
      final checkResult = await restoredDb.rawQuery('PRAGMA quick_check;');
      final firstCheck = checkResult.isNotEmpty ? checkResult.first.values.first : null;
      if (firstCheck != 'ok') {
        throw Exception('فشل فحص سلامة قاعدة البيانات بعد الاستعادة: $firstCheck');
      }

      // إزالة نسخة التراجع المؤقتة بعد النجاح
      if (await rollbackFile.exists()) {
        await rollbackFile.delete();
      }

      // توثيق في سجل الرقابة
      await auditRepo.logAction(
        userId: activeUserId,
        action: 'backup_restore',
        entityName: 'database',
        entityId: p.basename(backupFilePath),
        details: 'تم استعادة قاعدة البيانات بنجاح من النسخة: ${p.basename(backupFilePath)}',
      );

      return true;
    } catch (e) {
      // فشل: التراجع إلى النسخة الأصلية
      await dbHelper.close();
      if (await rollbackFile.exists()) {
        await rollbackFile.copy(dbPath);
        await rollbackFile.delete();
      }
      // إعادة فتح قاعدة البيانات
      await dbHelper.database;
      rethrow;
    }
  }

  /// حذف ملف نسخة احتياطية
  Future<bool> deleteBackup(String filePath, {int? activeUserId}) async {
    final file = File(filePath);
    if (await file.exists()) {
      await file.delete();
      await auditRepo.logAction(
        userId: activeUserId,
        action: 'backup_delete',
        entityName: 'database',
        entityId: p.basename(filePath),
        details: 'تم حذف ملف النسخة الاحتياطية',
      );
      return true;
    }
    return false;
  }
}
