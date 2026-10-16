import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/settings_repository_impl.dart';
import '../../domain/entities/app_settings_entity.dart';
import '../../domain/enums/app_currency.dart';
import '../../domain/repositories/settings_repository.dart';

/// مزود مستودع الإعدادات
final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepositoryImpl();
});

/// مزود حالة الإعدادات التفاعلي لكامل أرجاء التطبيق
final settingsProvider = StateNotifierProvider<SettingsNotifier, AppSettingsEntity>((ref) {
  final repo = ref.watch(settingsRepositoryProvider);
  return SettingsNotifier(repo);
});

/// موجه الثيم النشط المشتق من الإعدادات
final themeModeProvider = Provider<ThemeMode>((ref) {
  return ref.watch(settingsProvider).themeMode;
});

/// موجه العملة الافتراضية النشطة
final defaultCurrencyProvider = Provider<AppCurrency>((ref) {
  return ref.watch(settingsProvider).defaultCurrency;
});

class SettingsNotifier extends StateNotifier<AppSettingsEntity> {
  final SettingsRepository _repository;

  SettingsNotifier(this._repository) : super(const AppSettingsEntity()) {
    loadSettings();
  }

  /// تحميل الإعدادات من قاعدة بيانات SQLite
  Future<void> loadSettings() async {
    try {
      final loaded = await _repository.getSettings();
      state = loaded;
    } catch (_) {
      // الحفاظ على الحالة الافتراضية عند أي خطأ
    }
  }

  /// تحديث وحفظ الإعدادات كاملة
  Future<bool> saveSettings(AppSettingsEntity newSettings) async {
    state = newSettings;
    return await _repository.saveSettings(newSettings);
  }

  /// تبديل مظهر التطبيق (Dark / Light / System) فوراُ
  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    final modeStr = mode == ThemeMode.light
        ? 'light'
        : mode == ThemeMode.system
            ? 'system'
            : 'dark';
    await _repository.updateSetting('theme_mode', modeStr);
  }

  /// تبديل العملة الافتراضية
  Future<void> setDefaultCurrency(AppCurrency currency) async {
    state = state.copyWith(defaultCurrency: currency);
    await _repository.updateSetting('default_currency', currency.code);
  }

  /// تبديل مقاس ورق الطابعة (58mm / 80mm)
  Future<void> setPrinterPaperWidth(String width) async {
    state = state.copyWith(printerPaperWidth: width);
    await _repository.updateSetting('printer_paper_width', width);
  }

  /// تبديل التكبير/التصغير للخطوط
  Future<void> setTextScale(double scale) async {
    state = state.copyWith(textScale: scale);
    await _repository.updateSetting('text_scale', scale.toString());
  }

  /// حفظ مفتاح Gemini API بأمان
  Future<void> setGeminiApiKey(String apiKey) async {
    await _repository.setSecureKey('gemini_api_key', apiKey.trim());
  }

  /// قراءة مفتاح Gemini API المشفر
  Future<String?> getGeminiApiKey() async {
    return await _repository.getSecureKey('gemini_api_key');
  }
}
