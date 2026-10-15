import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sabr_electronics/data/datasources/local/database_helper.dart';
import 'package:sabr_electronics/data/repositories/spare_part_repository_impl.dart';
import 'package:sabr_electronics/domain/entities/spare_part_entity.dart';
import 'package:sabr_electronics/domain/enums/app_currency.dart';

void main() {
  late Database db;
  late SparePartRepositoryImpl repository;

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
        },
      ),
    );

    DatabaseHelper.instance.databaseForTesting = db;
    repository = SparePartRepositoryImpl(dbHelper: DatabaseHelper.instance);
  });

  tearDown(() async {
    await db.close();
  });

  group('SparePartRepository Tests', () {
    test('إضافة قطعة غيار واسترجاعها بنجاح مع دعم العملات', () async {
      final now = DateTime.now();
      final part = SparePartEntity(
        name: 'TDA7294 Audio Amplifier IC',
        partCode: 'IC-7294-01',
        category: 'integrated_circuit',
        costPrice: 25.0,
        sellingPrice: 40.0,
        currency: AppCurrency.sar,
        stockQuantity: 10,
        minStockAlert: 3,
        createdAt: now,
        updatedAt: now,
      );

      final id = await repository.insertSparePart(part);
      expect(id, greaterThan(0));

      final fetched = await repository.getSparePartById(id);
      expect(fetched, isNotNull);
      expect(fetched!.name, equals('TDA7294 Audio Amplifier IC'));
      expect(fetched.partCode, equals('IC-7294-01'));
      expect(fetched.currency, equals(AppCurrency.sar));
      expect(fetched.stockQuantity, equals(10));
      expect(fetched.isLowStock, isFalse);
    });

    test('البحث بالاسم والرمز المرجعي مع التصفية بالفئة', () async {
      final now = DateTime.now();
      await repository.insertSparePart(SparePartEntity(
        name: 'IRFP260N Power Mosfet',
        partCode: 'TR-260-01',
        category: 'power_semiconductor',
        costPrice: 1500,
        sellingPrice: 2500,
        currency: AppCurrency.yer,
        stockQuantity: 8,
        minStockAlert: 2,
        createdAt: now,
        updatedAt: now,
      ));

      await repository.insertSparePart(SparePartEntity(
        name: 'شاشة أندرويد 9 بوصة IPS لسيارة كيا',
        partCode: 'SCR-KIA-09',
        category: 'car_screen_lcd',
        costPrice: 50,
        sellingPrice: 85,
        currency: AppCurrency.usd,
        stockQuantity: 2,
        minStockAlert: 2,
        createdAt: now,
        updatedAt: now,
      ));

      // بحث بالرمز
      final byCode = await repository.getSparePartByCode('TR-260-01');
      expect(byCode, isNotNull);
      expect(byCode!.name, contains('IRFP260N'));

      // بحث بنص الاسم
      final searchResults = await repository.searchSpareParts('شاشة');
      expect(searchResults.length, equals(1));
      expect(searchResults.first.currency, equals(AppCurrency.usd));

      // بحث مع فلتر الفئة
      final filteredResults = await repository.searchSpareParts('', category: 'power_semiconductor');
      expect(filteredResults.length, equals(1));
      expect(filteredResults.first.category, equals('power_semiconductor'));
    });

    test('اكتشاف نواقص المخزون والتنبيه الحرج', () async {
      final now = DateTime.now();
      // قطعة رصيدها طبيعي
      await repository.insertSparePart(SparePartEntity(
        name: 'مكثف 470uF 450V إلكتروليتي',
        category: 'capacitors_passives',
        stockQuantity: 15,
        minStockAlert: 5,
        createdAt: now,
        updatedAt: now,
      ));

      // قطعة رصيدها حرج مساوٍ للحد
      await repository.insertSparePart(SparePartEntity(
        name: 'معالج أندرويد شاشات سيارات UIS7862',
        category: 'integrated_circuit',
        stockQuantity: 2,
        minStockAlert: 2,
        createdAt: now,
        updatedAt: now,
      ));

      // قطعة رصيدها منخفض جداً
      await repository.insertSparePart(SparePartEntity(
        name: 'متحكم شحن إنفرتر طاقة شمسية',
        category: 'power_supply_inverter',
        stockQuantity: 1,
        minStockAlert: 4,
        createdAt: now,
        updatedAt: now,
      ));

      final lowStock = await repository.getLowStockParts();
      expect(lowStock.length, equals(2));
      expect(lowStock.any((p) => p.name.contains('UIS7862')), isTrue);
      expect(lowStock.any((p) => p.name.contains('متحكم شحن')), isTrue);
    });

    test('تعديل المخزون السريع (إضافة أو استهلاك) ومنع الرصيد السالب', () async {
      final now = DateTime.now();
      final id = await repository.insertSparePart(SparePartEntity(
        name: 'كابل حساس ECG طبي',
        category: 'medical_components',
        stockQuantity: 5,
        minStockAlert: 2,
        createdAt: now,
        updatedAt: now,
      ));

      // استهلاك قطعتين
      final deductOk = await repository.adjustStock(id, -2);
      expect(deductOk, isTrue);

      var part = await repository.getSparePartById(id);
      expect(part!.stockQuantity, equals(3));

      // إضافة 10 قطع
      final addOk = await repository.adjustStock(id, 10);
      expect(addOk, isTrue);

      part = await repository.getSparePartById(id);
      expect(part!.stockQuantity, equals(13));

      // محاولة استهلاك أكثر من المتوفر (رفض الرصيد السالب)
      final negativeAttempt = await repository.adjustStock(id, -20);
      expect(negativeAttempt, isFalse);

      part = await repository.getSparePartById(id);
      expect(part!.stockQuantity, equals(13)); // بقي كما هو
    });
  });
}
