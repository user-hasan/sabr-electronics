import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sabr_electronics/data/datasources/local/database_helper.dart';
import 'package:sabr_electronics/data/repositories/repair_repository_impl.dart';
import 'package:sabr_electronics/data/repositories/spare_part_repository_impl.dart';
import 'package:sabr_electronics/domain/entities/payment_entity.dart';
import 'package:sabr_electronics/domain/entities/repair_item_entity.dart';
import 'package:sabr_electronics/domain/entities/repair_record_entity.dart';
import 'package:sabr_electronics/domain/entities/spare_part_entity.dart';
import 'package:sabr_electronics/domain/enums/app_currency.dart';
import 'package:sabr_electronics/domain/enums/payment_method.dart';
import 'package:sabr_electronics/domain/enums/repair_status.dart';

void main() {
  late Database db;
  late RepairRepositoryImpl repairRepo;
  late SparePartRepositoryImpl spareRepo;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    db = await databaseFactory.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 1,
        onConfigure: (db) async {
          await db.execute('PRAGMA foreign_keys = ON;');
        },
        onCreate: (db, version) async {
          final batch = db.batch();
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

          await batch.commit();
        },
      ),
    );

    DatabaseHelper.instance.databaseForTesting = db;
    repairRepo = RepairRepositoryImpl(dbHelper: DatabaseHelper.instance);
    spareRepo = SparePartRepositoryImpl(dbHelper: DatabaseHelper.instance);
  });

  tearDown(() async {
    await db.close();
  });

  group('RepairRepository & Financial Engine Tests', () {
    test('دورة الصيانة الكاملة: إضافة قطع، أجور، حساب الإجمالي وخصم المخزون', () async {
      final now = DateTime.now();

      // 1. إنشاء عميل وجهاز
      final custId = await db.insert('customers', {
        'name': 'المهندس فاروق محمد',
        'customerType': 'individual',
        'phone': '777123456',
        'createdAt': now.toIso8601String(),
        'updatedAt': now.toIso8601String(),
      });

      final devId = await db.insert('devices', {
        'customerId': custId,
        'category': 'car_screens',
        'deviceType': 'شاشة سيارة',
        'brand': 'TS10 Android',
        'model': '9 Inch IPS',
        'createdAt': now.toIso8601String(),
        'updatedAt': now.toIso8601String(),
      });

      // 2. إدخال قطعة غيار في المخزن
      final partId = await spareRepo.insertSparePart(SparePartEntity(
        name: 'معالج شاشة UIS7862',
        partCode: 'CPU-7862',
        category: 'integrated_circuit',
        costPrice: 40,
        sellingPrice: 70,
        currency: AppCurrency.usd,
        stockQuantity: 5,
        minStockAlert: 1,
        createdAt: now,
        updatedAt: now,
      ));

      // 3. إنشاء تذكرة صيانة
      final record = RepairRecordEntity(
        recordNumber: 'REC-2026-0001',
        customerId: custId,
        deviceId: devId,
        receivedAt: now,
        status: RepairStatus.received,
        problemDescription: 'الشاشة متوقفة على الشعار ولا تستجيب للمس',
        currency: AppCurrency.usd,
        estimatedCost: 100,
        paidAmount: 20, // عربون مقدم
        createdAt: now,
        updatedAt: now,
      );
      final repairId = await db.insert('repair_records', record.toMap());

      // 4. إضافة قطعة غيار للتذكرة -> التأكد من خصم المخزون وإعادة حساب التكلفة
      await repairRepo.addRepairItem(RepairItemEntity(
        repairRecordId: repairId,
        itemType: 'spare_part',
        sparePartId: partId,
        description: 'معالج شاشة UIS7862',
        unitCost: 40,
        unitPrice: 70,
        quantity: 1,
        totalPrice: 70,
        createdAt: now,
      ));

      // التحقق من خصم رصيد المخزن من 5 إلى 4
      final updatedPart = await spareRepo.getSparePartById(partId);
      expect(updatedPart!.stockQuantity, equals(4));

      // 5. إضافة أجور يد
      await repairRepo.addRepairItem(RepairItemEntity(
        repairRecordId: repairId,
        itemType: 'labor',
        description: 'إعادة شبلنة ولحام المعالج بالهوت إير',
        unitPrice: 30,
        quantity: 1,
        totalPrice: 30,
        createdAt: now,
      ));

      // 6. التحقق من الحساب المالي الإجمالي:
      // partsCost: 70, laborCost: 30, totalAmount: 100, paidAmount: 20, remainingAmount: 80
      final repAfterItems = await repairRepo.getRepairById(repairId);
      expect(repAfterItems!.partsCost, equals(70.0));
      expect(repAfterItems.laborCost, equals(30.0));
      expect(repAfterItems.totalAmount, equals(100.0));
      expect(repAfterItems.remainingAmount, equals(80.0));

      // 7. تسجيل دفعة مالية بالمتبقي 80
      final payId = await repairRepo.recordPayment(PaymentEntity(
        receiptNumber: 'PAY-2026-0001',
        repairRecordId: repairId,
        customerId: custId,
        amount: 80,
        currency: AppCurrency.usd,
        paymentMethod: PaymentMethod.cash,
        receivedByUserId: 1,
        paidAt: now,
      ));
      expect(payId, greaterThan(0));

      final repAfterPayment = await repairRepo.getRepairById(repairId);
      expect(repAfterPayment!.paidAmount, equals(80.0));
      expect(repAfterPayment.remainingAmount, equals(20.0));

      // 8. تحديث الحالة إلى جاهز للتسليم ثم تم التسليم
      final readyOk = await repairRepo.updateRepairStatus(repairId, RepairStatus.ready);
      expect(readyOk, isTrue);

      final deliverOk = await repairRepo.updateRepairStatus(repairId, RepairStatus.delivered);
      expect(deliverOk, isTrue);

      final repFinal = await repairRepo.getRepairById(repairId);
      expect(repFinal!.status, equals(RepairStatus.delivered));
      expect(repFinal.deliveredAt, isNotNull);

      // 9. إنشاء رسالة واتساب جاهزة
      final msg = repairRepo.generateWhatsAppMessage(
        record: repFinal,
        customerName: 'المهندس فاروق محمد',
        deviceName: 'TS10 Android 9 Inch',
      );
      expect(msg, contains('REC-2026-0001'));
      expect(msg, contains('تم تسليم جهازكم'));
      expect(msg, contains('الضمان'));
    });
  });
}
