import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sabr_electronics/domain/entities/customer_entity.dart';
import 'package:sabr_electronics/domain/entities/device_entity.dart';
import 'package:sabr_electronics/domain/entities/spare_part_entity.dart';
import 'package:sabr_electronics/domain/entities/repair_record_entity.dart';
import 'package:sabr_electronics/domain/enums/app_currency.dart';
import 'package:sabr_electronics/domain/enums/device_category.dart';
import 'package:sabr_electronics/domain/enums/repair_status.dart';
import 'package:sabr_electronics/data/datasources/local/database_helper.dart';

void main() {
  late Database db;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    // إنشاء قاعدة بيانات في الذاكرة للاختبارات الصارمة
    db = await databaseFactory.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 1,
        onConfigure: (db) async {
          await db.execute('PRAGMA foreign_keys = ON;');
        },
        onCreate: (db, version) async {
          final batch = db.batch();

          // الجداول الـ 11
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
              FOREIGN KEY (deviceId) REFERENCES devices (id) ON DELETE RESTRICT
            );
          ''');

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
              FOREIGN KEY (customerId) REFERENCES customers (id) ON DELETE RESTRICT
            );
          ''');

          await batch.commit(noResult: true);
        },
      ),
    );
  });

  tearDown(() async {
    await db.close();
  });

  test('Customer insertion and retrieval', () async {
    final now = DateTime.now();
    final customer = CustomerEntity(
      name: 'د. عادل النجار',
      phone: '777112233',
      customerType: 'medical_center',
      createdAt: now,
      updatedAt: now,
    );

    final id = await db.insert('customers', customer.toMap());
    expect(id, isPositive);

    final result = await db.query('customers', where: 'id = ?', whereArgs: [id]);
    expect(result.length, 1);
    final fetched = CustomerEntity.fromMap(result.first);
    expect(fetched.name, 'د. عادل النجار');
    expect(fetched.phone, '777112233');
    expect(fetched.customerType, 'medical_center');
  });

  test('Foreign key constraint restricts inserting device without customer', () async {
    final now = DateTime.now();
    final orphanDevice = DeviceEntity(
      customerId: 9999, // غير موجود
      category: DeviceCategory.medical,
      deviceType: 'جهاز مراقبة مرضى Patient Monitor',
      brand: 'Mindray',
      model: 'uMEC10',
      createdAt: now,
      updatedAt: now,
    );

    expect(
      () async => await db.insert('devices', orphanDevice.toMap()),
      throwsA(isA<DatabaseException>()),
    );
  });

  test('Multi-currency spare parts persistence (YER, SAR, USD)', () async {
    final now = DateTime.now();
    final partSAR = SparePartEntity(
      name: 'شاشة لمس سيارة 9 إنش IPS',
      category: 'car_screen_lcd',
      costPrice: 120.0,
      sellingPrice: 180.0,
      currency: AppCurrency.sar,
      stockQuantity: 5,
      createdAt: now,
      updatedAt: now,
    );

    final id = await db.insert('spare_parts', partSAR.toMap());
    final result = await db.query('spare_parts', where: 'id = ?', whereArgs: [id]);
    final fetched = SparePartEntity.fromMap(result.first);

    expect(fetched.currency, AppCurrency.sar);
    expect(fetched.costPrice, 120.0);
    expect(fetched.sellingPrice, 180.0);
  });

  test('Transactional repair calculation (Labor + Parts - Discount = Total)', () async {
    final now = DateTime.now();

    // 1. إضافة عميل
    final custId = await db.insert('customers', {
      'name': 'مركز الشفاء الطبي',
      'phone': '770123456',
      'createdAt': now.toIso8601String(),
      'updatedAt': now.toIso8601String(),
    });

    // 2. إضافة جهاز طبي
    final devId = await db.insert('devices', {
      'customerId': custId,
      'category': DeviceCategory.medical.code,
      'deviceType': 'جهاز تخطيط قلب ECG',
      'brand': 'GE Healthcare',
      'model': 'MAC 2000',
      'createdAt': now.toIso8601String(),
      'updatedAt': now.toIso8601String(),
    });

    // 3. حسابات الصيانة
    const double laborCost = 5000.0;
    const double partsCost = 15000.0;
    const double discount = 1000.0;
    const double total = (laborCost + partsCost) - discount; // 19000.0
    const double advancePaid = 10000.0;
    const double remaining = total - advancePaid; // 9000.0

    final record = RepairRecordEntity(
      recordNumber: 'REC-2026-0001',
      customerId: custId,
      deviceId: devId,
      receivedAt: now,
      status: RepairStatus.inProgress,
      problemDescription: 'عطل في بوردة معالجة الإشارة وقاطع باور',
      currency: AppCurrency.yer,
      laborCost: laborCost,
      partsCost: partsCost,
      discountAmount: discount,
      totalAmount: total,
      paidAmount: advancePaid,
      remainingAmount: remaining,
      createdAt: now,
      updatedAt: now,
    );

    final recId = await db.insert('repair_records', record.toMap());
    final res = await db.query('repair_records', where: 'id = ?', whereArgs: [recId]);
    final fetched = RepairRecordEntity.fromMap(res.first);

    expect(fetched.totalAmount, 19000.0);
    expect(fetched.remainingAmount, 9000.0);
    expect(fetched.currency, AppCurrency.yer);
  });

  test('Verify DatabaseHelper dbVersion is upgraded to 2', () async {
    expect(DatabaseHelper.dbVersion, equals(2));
  });
}
