import '../entities/app_settings_entity.dart';

/// مخطط عمليات مستودع إعدادات النظام
abstract class SettingsRepository {
  /// جلب كافة الإعدادات الحالية من قاعدة البيانات مع دمج القيم الافتراضية
  Future<AppSettingsEntity> getSettings();

  /// تحديث إعداد منفرد بمفتاحه وقيمته
  Future<bool> updateSetting(String key, String value);

  /// حفظ وتحديث كائن الإعدادات بالكامل
  Future<bool> saveSettings(AppSettingsEntity settings);

  /// جلب مفتاح سري مشفر من الـ Secure Storage (مثل Gemini API Key)
  Future<String?> getSecureKey(String key);

  /// حفظ مفتاح سري مشفر في الـ Secure Storage
  Future<void> setSecureKey(String key, String value);
}
