import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sabr_electronics/data/datasources/local/database_helper.dart';
import 'package:sabr_electronics/data/repositories/settings_repository_impl.dart';
import 'package:sabr_electronics/domain/enums/app_currency.dart';
import 'package:sabr_electronics/presentation/providers/settings_provider.dart';

void main() {
  late Database db;
  late SettingsRepositoryImpl repository;

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
            CREATE TABLE settings (
              key TEXT PRIMARY KEY,
              value TEXT NOT NULL,
              updatedAt TEXT NOT NULL
            );
          ''');

          final now = DateTime.now().toIso8601String();
          final batch = db.batch();
          final defaultSettings = {
            'shop_name': 'صبر إلكترونكس',
            'shop_phone': '777000000',
            'shop_address': 'اليمن - المركز الرئيسي',
            'default_currency': 'YER',
            'printer_paper_width': '58mm',
            'default_warranty_days': '30',
            'auto_lock_timeout': '5',
            'require_pin_for_discounts': 'true',
            'theme_mode': 'dark',
          };

          defaultSettings.forEach((key, value) {
            batch.insert('settings', {
              'key': key,
              'value': value,
              'updatedAt': now,
            });
          });

          await batch.commit(noResult: true);
        },
      ),
    );

    DatabaseHelper.instance.databaseForTesting = db;
    repository = SettingsRepositoryImpl(dbHelper: DatabaseHelper.instance);
  });

  tearDown(() async {
    await db.close();
  });

  group('Settings System & Riverpod Tests', () {
    test('قراءة الإعدادات الافتراضية من SQLite بنجاح', () async {
      final settings = await repository.getSettings();
      expect(settings.shopName, equals('صبر إلكترونكس'));
      expect(settings.shopPhone, equals('777000000'));
      expect(settings.defaultCurrency, equals(AppCurrency.yer));
      expect(settings.printerPaperWidth, equals('58mm'));
      expect(settings.defaultWarrantyDays, equals(30));
      expect(settings.themeMode, equals(ThemeMode.dark));
    });

    test('تحديث إعداد منفرد وحفظه في SQLite', () async {
      final updatedOk = await repository.updateSetting('shop_name', 'صبر إلكترونكس - فرع تعز');
      expect(updatedOk, isTrue);

      final settings = await repository.getSettings();
      expect(settings.shopName, equals('صبر إلكترونكس - فرع تعز'));
    });

    test('تحديث وحفظ كائن الإعدادات الشامل بالكامل', () async {
      final current = await repository.getSettings();
      final modified = current.copyWith(
        shopName: 'صبر إلكترونكس المركز الرئيسي',
        shopPhone: '777111222',
        printerPaperWidth: '80mm',
        defaultCurrency: AppCurrency.sar,
        themeMode: ThemeMode.light,
        lowStockThreshold: 5,
      );

      final saved = await repository.saveSettings(modified);
      expect(saved, isTrue);

      final fetched = await repository.getSettings();
      expect(fetched.shopName, equals('صبر إلكترونكس المركز الرئيسي'));
      expect(fetched.shopPhone, equals('777111222'));
      expect(fetched.printerPaperWidth, equals('80mm'));
      expect(fetched.defaultCurrency, equals(AppCurrency.sar));
      expect(fetched.themeMode, equals(ThemeMode.light));
      expect(fetched.lowStockThreshold, equals(5));
    });

    test('تكامل Riverpod: SettingsNotifier واستجابة الحالة الفورية', () async {
      final container = ProviderContainer(
        overrides: [
          settingsRepositoryProvider.overrideWithValue(repository),
        ],
      );

      // انتظار التحميل الأولي
      await container.read(settingsProvider.notifier).loadSettings();
      var state = container.read(settingsProvider);
      expect(state.shopName, equals('صبر إلكترونكس'));

      // تبديل الثيم إلى الفاتح
      await container.read(settingsProvider.notifier).setThemeMode(ThemeMode.light);
      expect(container.read(themeModeProvider), equals(ThemeMode.light));
      expect(container.read(settingsProvider).themeMode, equals(ThemeMode.light));

      // تبديل العملة إلى الدولار
      await container.read(settingsProvider.notifier).setDefaultCurrency(AppCurrency.usd);
      expect(container.read(defaultCurrencyProvider), equals(AppCurrency.usd));
      expect(container.read(settingsProvider).defaultCurrency, equals(AppCurrency.usd));

      // التحقق من استمرار التغيير في قاعدة البيانات
      final inDb = await repository.getSettings();
      expect(inDb.themeMode, equals(ThemeMode.light));
      expect(inDb.defaultCurrency, equals(AppCurrency.usd));

      container.dispose();
    });
  });
}
