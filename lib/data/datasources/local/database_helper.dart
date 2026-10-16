import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// المساعد المركزي لقاعدة بيانات SQLite المحلية - مصدر الحقيقة الوحيد
class DatabaseHelper {
  static const String dbName = 'sabr_electronics.db';
  static const int dbVersion = 2;

  DatabaseHelper._internal();
  static final DatabaseHelper instance = DatabaseHelper._internal();

  Database? _database;

  @visibleForTesting
  set databaseForTesting(Database? db) => _database = db;

  Future<Database> get database async {
    if (_database != null && _database!.isOpen) {
      return _database!;
    }
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    // تهيئة FFI لبيئات سطح المكتب والاختبارات إذا لزم الأمر
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final String dbPath = await getDbPath();

    return await openDatabase(
      dbPath,
      version: dbVersion,
      onConfigure: (db) async {
        // تفعيل قيود المفاتيح الأجنبية بشكل صارم
        await db.execute('PRAGMA foreign_keys = ON;');
      },
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<String> getDbPath() async {
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux)) {
      final appSupportDir = await getApplicationSupportDirectory();
      return p.join(appSupportDir.path, dbName);
    }
    final String documentsDirectory = await getDatabasesPath();
    return p.join(documentsDirectory, dbName);
  }

  Future<void> _onCreate(Database db, int version) async {
    final batch = db.batch();

    // 1. جدول المستخدمين والصلاحيات
    batch.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT UNIQUE NOT NULL,
        displayName TEXT NOT NULL,
        pinCode TEXT NOT NULL,
        role TEXT NOT NULL,
        isActive INTEGER NOT NULL DEFAULT 1,
        createdAt TEXT NOT NULL
      );
    ''');

    // 2. جدول العملاء
    batch.execute('''
      CREATE TABLE customers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        customerType TEXT NOT NULL DEFAULT 'individual',
        phone TEXT NOT NULL UNIQUE,
        alternatePhone TEXT,
        notes TEXT,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL
      );
    ''');

    // 3. جدول الأجهزة الهندسية
    batch.execute('''
      CREATE TABLE devices (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        customerId INTEGER NOT NULL,
        category TEXT NOT NULL,
        deviceType TEXT NOT NULL,
        brand TEXT NOT NULL,
        model TEXT NOT NULL,
        serialNumber TEXT,
        carVehicleInfo TEXT,
        medicalFacility TEXT,
        operatingVoltage TEXT,
        receivedAccessories TEXT,
        physicalCondition TEXT,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        FOREIGN KEY (customerId) REFERENCES customers (id) ON DELETE RESTRICT
      );
    ''');

    // 4. جدول صور وتوثيق الأجهزة
    batch.execute('''
      CREATE TABLE device_images (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        deviceId INTEGER NOT NULL,
        repairRecordId INTEGER,
        imageType TEXT NOT NULL,
        originalPath TEXT NOT NULL,
        thumbnailPath TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        FOREIGN KEY (deviceId) REFERENCES devices (id) ON DELETE CASCADE
      );
    ''');

    // 5. مستودع القطع والمكونات الإلكترونية
    batch.execute('''
      CREATE TABLE spare_parts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        partCode TEXT UNIQUE,
        category TEXT NOT NULL,
        costPrice REAL NOT NULL DEFAULT 0.0,
        sellingPrice REAL NOT NULL DEFAULT 0.0,
        currency TEXT NOT NULL DEFAULT 'YER',
        stockQuantity INTEGER NOT NULL DEFAULT 0,
        minStockAlert INTEGER NOT NULL DEFAULT 2,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL
      );
    ''');

    // 6. تذاكر وعمليات الصيانة
    batch.execute('''
      CREATE TABLE repair_records (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        recordNumber TEXT UNIQUE NOT NULL,
        customerId INTEGER NOT NULL,
        deviceId INTEGER NOT NULL,
        technicianId INTEGER,
        receivedAt TEXT NOT NULL,
        expectedDeliveryAt TEXT,
        deliveredAt TEXT,
        status TEXT NOT NULL,
        problemDescription TEXT NOT NULL,
        diagnosticNotes TEXT,
        currency TEXT NOT NULL DEFAULT 'YER',
        estimatedCost REAL NOT NULL DEFAULT 0.0,
        laborCost REAL NOT NULL DEFAULT 0.0,
        partsCost REAL NOT NULL DEFAULT 0.0,
        totalAmount REAL NOT NULL DEFAULT 0.0,
        discountAmount REAL NOT NULL DEFAULT 0.0,
        paidAmount REAL NOT NULL DEFAULT 0.0,
        remainingAmount REAL NOT NULL DEFAULT 0.0,
        warrantyDays INTEGER NOT NULL DEFAULT 30,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        FOREIGN KEY (customerId) REFERENCES customers (id) ON DELETE RESTRICT,
        FOREIGN KEY (deviceId) REFERENCES devices (id) ON DELETE RESTRICT,
        FOREIGN KEY (technicianId) REFERENCES users (id) ON DELETE SET NULL
      );
    ''');

    // 7. بنود الصيانة والمكونات المستهلكة
    batch.execute('''
      CREATE TABLE repair_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        repairRecordId INTEGER NOT NULL,
        itemType TEXT NOT NULL,
        sparePartId INTEGER,
        description TEXT NOT NULL,
        unitCost REAL NOT NULL DEFAULT 0.0,
        unitPrice REAL NOT NULL DEFAULT 0.0,
        quantity INTEGER NOT NULL DEFAULT 1,
        totalPrice REAL NOT NULL DEFAULT 0.0,
        createdAt TEXT NOT NULL,
        FOREIGN KEY (repairRecordId) REFERENCES repair_records (id) ON DELETE CASCADE,
        FOREIGN KEY (sparePartId) REFERENCES spare_parts (id) ON DELETE SET NULL
      );
    ''');

    // 8. سندات القبض والدفعات المالية
    batch.execute('''
      CREATE TABLE payments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        receiptNumber TEXT UNIQUE NOT NULL,
        repairRecordId INTEGER NOT NULL,
        customerId INTEGER NOT NULL,
        amount REAL NOT NULL,
        currency TEXT NOT NULL DEFAULT 'YER',
        paymentMethod TEXT NOT NULL,
        receivedByUserId INTEGER NOT NULL,
        paidAt TEXT NOT NULL,
        notes TEXT,
        FOREIGN KEY (repairRecordId) REFERENCES repair_records (id) ON DELETE RESTRICT,
        FOREIGN KEY (customerId) REFERENCES customers (id) ON DELETE RESTRICT,
        FOREIGN KEY (receivedByUserId) REFERENCES users (id) ON DELETE RESTRICT
      );
    ''');

    // 9. سجل تتبع الحالات التاريخي
    batch.execute('''
      CREATE TABLE repair_status_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        repairRecordId INTEGER NOT NULL,
        changedByUserId INTEGER,
        oldStatus TEXT NOT NULL,
        newStatus TEXT NOT NULL,
        note TEXT,
        changedAt TEXT NOT NULL,
        FOREIGN KEY (repairRecordId) REFERENCES repair_records (id) ON DELETE CASCADE,
        FOREIGN KEY (changedByUserId) REFERENCES users (id) ON DELETE SET NULL
      );
    ''');

    // 10. سجل الرقابة والتدقيق (غير قابل للحذف)
    batch.execute('''
      CREATE TABLE audit_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId INTEGER,
        action TEXT NOT NULL,
        entityName TEXT NOT NULL,
        entityId TEXT NOT NULL,
        details TEXT,
        createdAt TEXT NOT NULL,
        FOREIGN KEY (userId) REFERENCES users (id) ON DELETE SET NULL
      );
    ''');

    // 11. إعدادات النظام العامة
    batch.execute('''
      CREATE TABLE settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL,
        updatedAt TEXT NOT NULL
      );
    ''');

    // بذر البيانات الأولية (Default Admin User & Default Settings)
    final now = DateTime.now().toIso8601String();

    // مستخدم افتراضي: مدير المحل (PIN: 1234)
    batch.insert('users', {
      'username': 'admin',
      'displayName': 'المدير العام',
      'pinCode': '1234',
      'role': 'owner',
      'isActive': 1,
      'createdAt': now,
    });

    // الإعدادات الافتراضية
    final defaultSettings = {
      'shop_name': 'صبر إلكترونكس',
      'shop_phone': '777000000',
      'shop_address': 'اليمن - المركز الرئيسي',
      'default_currency': 'YER',
      'printer_paper_width': '58mm',
      'default_warranty_days': '30',
      'auto_lock_timeout': '5',
      'require_pin_for_discounts': 'true',
    };

    defaultSettings.forEach((key, value) {
      batch.insert('settings', {
        'key': key,
        'value': value,
        'updatedAt': now,
      });
    });

    // إنشاء الفهارس لتحسين سرعة الاستعلامات والبحث
    _createIndexes(batch);

    await batch.commit(noResult: true);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // الترقية المتسلسلة بدون حذف الجداول (Zero Data Loss)
    if (oldVersion < 2) {
      final batch = db.batch();
      _createIndexes(batch);
      await batch.commit(noResult: true);
    }
  }

  static void _createIndexes(Batch batch) {
    batch.execute('CREATE INDEX IF NOT EXISTS idx_repair_records_customer ON repair_records (customerId);');
    batch.execute('CREATE INDEX IF NOT EXISTS idx_repair_records_device ON repair_records (deviceId);');
    batch.execute('CREATE INDEX IF NOT EXISTS idx_repair_records_status ON repair_records (status);');
    batch.execute('CREATE INDEX IF NOT EXISTS idx_devices_customer ON devices (customerId);');
    batch.execute('CREATE INDEX IF NOT EXISTS idx_device_images_device ON device_images (deviceId);');
    batch.execute('CREATE INDEX IF NOT EXISTS idx_repair_items_record ON repair_items (repairRecordId);');
    batch.execute('CREATE INDEX IF NOT EXISTS idx_payments_record ON payments (repairRecordId);');
    batch.execute('CREATE INDEX IF NOT EXISTS idx_payments_customer ON payments (customerId);');
    batch.execute('CREATE INDEX IF NOT EXISTS idx_spare_parts_code ON spare_parts (partCode);');
    batch.execute('CREATE INDEX IF NOT EXISTS idx_spare_parts_category ON spare_parts (category);');
    batch.execute('CREATE INDEX IF NOT EXISTS idx_audit_logs_user ON audit_logs (userId);');
    batch.execute('CREATE INDEX IF NOT EXISTS idx_audit_logs_created ON audit_logs (createdAt);');
  }

  /// تنفيذ نقطة تفتيش للكتابة المسبقة لضمان مزامنة التغييرات من ملف WAL إلى ملف DB الرئيسي قبل النسخ الاحتياطي
  Future<void> checkpoint() async {
    final db = await database;
    try {
      await db.execute('PRAGMA wal_checkpoint(FULL);');
    } catch (_) {
      // قد لا يكون وضع WAL مفعلاً في بعض البيئات أو قواعد بيانات الذاكرة، يتم التجاهل بأمان
    }
  }

  Future<void> close() async {
    final db = _database;
    if (db != null && db.isOpen) {
      await db.close();
      _database = null;
    }
  }
}
