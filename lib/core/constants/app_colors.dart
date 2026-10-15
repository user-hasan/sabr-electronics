import 'package:flutter/material.dart';

/// الألوان المعيارية لتطبيق صبر إلكترونكس وفق وثيقة الهوية البصرية 14_ASSETS_AND_BRANDING.md
class AppColors {
  AppColors._();

  // الهوية الأساسية
  static const Color primary = Color(0xFF00E5FF);       // Cyan ساطع للـ Highlights والإجراءات الأساسية
  static const Color primaryDark = Color(0xFF06B6D4);   // Cyan متوسط
  static const Color accent = Color(0xFFF59E0B);        // Amber للعتاد والتنبيهات والمبالغ
  static const Color accentDark = Color(0xFFD97706);

  // الوضع الداكن (Dark Mode - الافتراضي للورش)
  static const Color bgDark = Color(0xFF0F172A);        // Dark Slate خلفية الشاشة
  static const Color surfaceDark = Color(0xFF1E293B);   // خلفية البطاقات والحقول
  static const Color surfaceDarkElevated = Color(0xFF243247);
  static const Color borderDark = Color(0xFF334155);    // حدود البطاقات والفواصل
  static const Color textPrimaryDark = Color(0xFFF8FAFC);
  static const Color textSecondaryDark = Color(0xFF94A3B8);

  // الوضع الفاتح (Light Mode)
  static const Color bgLight = Color(0xFFF8FAFC);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceLightElevated = Color(0xFFF1F5F9);
  static const Color borderLight = Color(0xFFE2E8F0);
  static const Color textPrimaryLight = Color(0xFF0F172A);
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

  // ألوان المعاملات المالية
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);
}
