import 'package:flutter/material.dart';

/// الألوان المعيارية لتطبيق صبر إلكترونكس وفق وثيقة الهوية البصرية 14_ASSETS_AND_BRANDING.md
class AppColors {
  AppColors._();

  // الهوية الأساسية (Modern Adaptive Cyan & Royal Indigo)
  static const Color primary = Color(0xFF38BDF8);       // Sky/Cyan ساطع وعصري للإجراءات الأساسية
  static const Color primaryDark = Color(0xFF2563EB);   // Royal Blue للوضع الفاتح
  static const Color secondary = Color(0xFF22D3EE);     // Cyan ثانوي متألق
  static const Color accent = Color(0xFFA78BFA);        // Lavender/Violet للمسات الثانوية الراقية
  static const Color accentDark = Color(0xFF7C3AED);

  // الوضع الداكن المطور (Midnight Indigo - راقي ومريح تحت إضاءة الورش)
  static const Color bgDark = Color(0xFF080F1F);        // Midnight Indigo داكن وعميق
  static const Color surfaceDark = Color(0xFF111C32);   // كحلي نيلي أنيق للبطاقات
  static const Color surfaceDarkElevated = Color(0xFF1A2744); // أسطح عائمة أعلى تبايناً
  static const Color surfaceGlassDark = Color(0xB8111C32); // شفافية ناعمة خفيفة
  static const Color borderDark = Color(0x2E94A3B8);    // حدود ناعمة متناسقة
  static const Color textPrimaryDark = Color(0xFFF8FAFC);
  static const Color textSecondaryDark = Color(0xFF94A3B8);
  static const Color textMutedDark = Color(0xFF64748B);

  // الوضع الفاتح المطور (Pearl Light - لؤلؤي ناصع وأنيق)
  static const Color bgLight = Color(0xFFEEF3FA);       // خلفية لؤلؤية هادئة
  static const Color surfaceLight = Color(0xFFFFFFFF);  // أسطح بيضاء نقية
  static const Color surfaceLightElevated = Color(0xFFF8FAFC);
  static const Color surfaceGlassLight = Color(0xCCFFFFFF);
  static const Color borderLight = Color(0xD0E2E8F0);
  static const Color textPrimaryLight = Color(0xFF172033);
  static const Color textSecondaryLight = Color(0xFF64748B);

  // ألوان الحالات الهندسية لدورة الصيانة
  static const Color statusReceived = Color(0xFF3B82F6);    // تم الاستلام (أزرق)
  static const Color statusInspection = Color(0xFF8B5CF6);  // قيد الفحص (بنفسجي)
  static const Color statusWaiting = Color(0xFFF59E0B);     // بانتظار الموافقة/قطع الغيار (برتقالي)
  static const Color statusInProgress = Color(0xFF06B6D4);  // قيد الإصلاح (سماوي)
  static const Color statusWaitingParts = Color(0xFFEC4899);// بانتظار قطع (وردي)
  static const Color statusReady = Color(0xFF10B981);       // جاهز للتسليم (أخضر زاهي)
  static const Color statusDone = Color(0xFF059669);        // تم التسليم والقبض (أخضر داكن)
  static const Color statusCancelled = Color(0xFFEF4444);   // ملغي أو تعذر الإصلاح (أحمر)
  static const Color statusPending = Color(0xFFF59E0B);     // معلق أو بانتظار إجراء (برتقالي)

  // ألوان المعاملات المالية
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);
}
