import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sabr_electronics/data/datasources/local/database_helper.dart';
import 'package:sabr_electronics/data/repositories/customer_repository_impl.dart';
import 'package:sabr_electronics/domain/entities/customer_entity.dart';

void main() {
  late Database db;
  late CustomerRepositoryImpl customerRepo;

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
            CREATE TABLE customers (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL,
              customerType TEXT NOT NULL DEFAULT 'individual',
              phone TEXT NOT NULL,
              alternatePhone TEXT,
              notes TEXT,
              createdAt TEXT NOT NULL,
              updatedAt TEXT NOT NULL
            );
          ''');
          await db.execute('''
            CREATE TABLE devices (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              customerId INTEGER NOT NULL,
              deviceCategory TEXT NOT NULL,
              brand TEXT NOT NULL,
              model TEXT NOT NULL,
              serialNumber TEXT,
              devicePassword TEXT,
              physicalCondition TEXT,
              createdAt TEXT NOT NULL,
              updatedAt TEXT NOT NULL
            );
          ''');
          await db.execute('''
            CREATE TABLE repair_records (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              trackingCode TEXT UNIQUE NOT NULL,
              customerId INTEGER NOT NULL,
              deviceId INTEGER NOT NULL,
              userId INTEGER NOT NULL,
              status TEXT NOT NULL,
              estimatedCost REAL NOT NULL DEFAULT 0.0,
              laborCost REAL NOT NULL DEFAULT 0.0,
              partsCost REAL NOT NULL DEFAULT 0.0,
              discountAmount REAL NOT NULL DEFAULT 0.0,
              totalAmount REAL NOT NULL DEFAULT 0.0,
              paidAmount REAL NOT NULL DEFAULT 0.0,
              initialComplaint TEXT NOT NULL,
              createdAt TEXT NOT NULL,
              updatedAt TEXT NOT NULL
            );
          ''');
        },
      ),
    );

    DatabaseHelper.instance.databaseForTesting = db;
    customerRepo = CustomerRepositoryImpl(dbHelper: DatabaseHelper.instance);
  });

  tearDown(() async {
    await db.close();
  });

  group('CustomerRepository Tests', () {
    test('إضافة عميل واسترجاعه بالمعرف ورقم الهاتف', () async {
      final now = DateTime.now();
      final customer = CustomerEntity(
        name: 'مختار العبسي',
        customerType: 'car_workshop',
        phone: '777333444',
        alternatePhone: '711333444',
        notes: 'عميل ورشة سيارات معتمد',
        createdAt: now,
        updatedAt: now,
      );

      final customerId = await customerRepo.createCustomer(customer);
      expect(customerId, isPositive);

      final fetched = await customerRepo.getCustomerById(customerId);
      expect(fetched, isNotNull);
      expect(fetched!.name, equals('مختار العبسي'));
      expect(fetched.customerType, equals('car_workshop'));
      expect(fetched.phone, equals('777333444'));

      final byPhone = await customerRepo.getCustomerByPhone('711333444');
      expect(byPhone, isNotNull);
      expect(byPhone!.id, equals(customerId));
    });

    test('البحث عن العملاء بالاسم ورقم الهاتف', () async {
      final now = DateTime.now();
      await customerRepo.createCustomer(CustomerEntity(
        name: 'أحمد سعيد مهيوب',
        phone: '771234567',
        createdAt: now,
        updatedAt: now,
      ));
      await customerRepo.createCustomer(CustomerEntity(
        name: 'خالد اليماني',
        phone: '739876543',
        createdAt: now,
        updatedAt: now,
      ));

      final resultsName = await customerRepo.searchCustomers('مهيوب');
      expect(resultsName.length, equals(1));
      expect(resultsName.first.name, contains('مهيوب'));

      final resultsPhone = await customerRepo.searchCustomers('73987');
      expect(resultsPhone.length, equals(1));
      expect(resultsPhone.first.name, equals('خالد اليماني'));
    });

    test('تحديث بيانات العميل وحساب الإحصائيات الفنية والمالية', () async {
      final now = DateTime.now();
      final id = await customerRepo.createCustomer(CustomerEntity(
        name: 'ماجد الشميري',
        phone: '770001122',
        createdAt: now,
        updatedAt: now,
      ));

      // تحديث الاسم
      final updated = await customerRepo.updateCustomer(CustomerEntity(
        id: id,
        name: 'ماجد الشميري - مركز الشفاء الطبي',
        customerType: 'medical_center',
        phone: '770001122',
        createdAt: now,
        updatedAt: DateTime.now(),
      ));
      expect(updated, isTrue);

      final fetched = await customerRepo.getCustomerById(id);
      expect(fetched!.name, equals('ماجد الشميري - مركز الشفاء الطبي'));
      expect(fetched.customerType, equals('medical_center'));

      // إضافة أجهزة وتذاكر صيانة لاختبار getCustomerStats
      await db.insert('devices', {
        'customerId': id,
        'deviceCategory': 'medical',
        'brand': 'Mindray',
        'model': 'Patient Monitor',
        'createdAt': now.toIso8601String(),
        'updatedAt': now.toIso8601String(),
      });
      await db.insert('repair_records', {
        'trackingCode': 'REP-2026-TEST',
        'customerId': id,
        'deviceId': 1,
        'userId': 1,
        'status': 'in_progress',
        'estimatedCost': 50000.0,
        'laborCost': 20000.0,
        'partsCost': 30000.0,
        'discountAmount': 0.0,
        'totalAmount': 50000.0,
        'paidAmount': 20000.0, // متبقي 30,000 دَيْن
        'initialComplaint': 'عطل في وحدة الطاقة',
        'createdAt': now.toIso8601String(),
        'updatedAt': now.toIso8601String(),
      });

      final stats = await customerRepo.getCustomerStats(id);
      expect(stats['deviceCount'], equals(1));
      expect(stats['repairCount'], equals(1));
      expect(stats['debt'], equals(30000.0));
    });
  });
}
