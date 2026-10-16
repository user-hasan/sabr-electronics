import 'package:flutter/material.dart';
import '../enums/app_currency.dart';

/// كيان إعدادات نظام صبر إلكترونكس المتكامل
class AppSettingsEntity {
  // 1. بيانات المحل والترويسة
  final String shopName;
  final String shopPhone;
  final String shopAddress;
  final String receiptTerms;
  final bool printLogoOnReceipt;
  final int defaultWarrantyDays;

  // 2. العتاد والطباعة الحرارية
  final String printerConnectionType; // bluetooth, usb, network
  final String? printerDeviceAddress;
  final String printerPaperWidth; // 58mm, 80mm
  final bool autoPrintIntakeReceipt;
  final bool autoPrintStickyTag;

  // 3. المالية والعملات
  final AppCurrency defaultCurrency;
  final int lowStockThreshold;
  final bool requirePinForDiscounts;

  // 4. الأمان والقفل
  final int autoLockTimeout; // بالدقائق (0 يعني معطل)

  // 5. المظهر والعرض
  final ThemeMode themeMode;
  final double textScale;

  // 6. الوسائط والذكاء الاصطناعي
  final bool enableCloudOcr;
  final double ocrConfidenceThreshold;
  final String imageCompressionQuality; // high, medium

  const AppSettingsEntity({
    this.shopName = 'صبر إلكترونكس',
    this.shopPhone = '777000000',
    this.shopAddress = 'اليمن - المركز الرئيسي',
    this.receiptTerms = '• الجهاز يسلم بموجب هذا السند الأصلي فقط.\n• المركز غير مسؤول عن الأجهزة المتروكة لأكثر من 30 يوماً من إشعار الجاهزية.',
    this.printLogoOnReceipt = true,
    this.defaultWarrantyDays = 30,
    this.printerConnectionType = 'bluetooth',
    this.printerDeviceAddress,
    this.printerPaperWidth = '58mm',
    this.autoPrintIntakeReceipt = true,
    this.autoPrintStickyTag = true,
    this.defaultCurrency = AppCurrency.yer,
    this.lowStockThreshold = 2,
    this.requirePinForDiscounts = true,
    this.autoLockTimeout = 5,
    this.themeMode = ThemeMode.dark,
    this.textScale = 1.0,
    this.enableCloudOcr = false,
    this.ocrConfidenceThreshold = 0.80,
    this.imageCompressionQuality = 'high',
  });

  /// تحويل كائن الإعدادات إلى خريطة مفتاح-قيمة (String Key-Value) للحفظ في SQLite
  Map<String, String> toDbMap() {
    return {
      'shop_name': shopName,
      'shop_phone': shopPhone,
      'shop_address': shopAddress,
      'receipt_terms': receiptTerms,
      'print_logo_on_receipt': printLogoOnReceipt.toString(),
      'default_warranty_days': defaultWarrantyDays.toString(),
      'printer_connection_type': printerConnectionType,
      'printer_device_address': ?printerDeviceAddress,
      'printer_paper_width': printerPaperWidth,
      'auto_print_intake_receipt': autoPrintIntakeReceipt.toString(),
      'auto_print_sticky_tag': autoPrintStickyTag.toString(),
      'default_currency': defaultCurrency.code,
      'low_stock_threshold': lowStockThreshold.toString(),
      'require_pin_for_discounts': requirePinForDiscounts.toString(),
      'auto_lock_timeout': autoLockTimeout.toString(),
      'theme_mode': _themeModeToString(themeMode),
      'text_scale': textScale.toString(),
      'enable_cloud_ocr': enableCloudOcr.toString(),
      'ocr_confidence_threshold': ocrConfidenceThreshold.toString(),
      'image_compression_quality': imageCompressionQuality,
    };
  }

  /// إنشاء الكائن من خريطة مسترجعة من SQLite
  factory AppSettingsEntity.fromDbMap(Map<String, String> map) {
    return AppSettingsEntity(
      shopName: map['shop_name'] ?? 'صبر إلكترونكس',
      shopPhone: map['shop_phone'] ?? '777000000',
      shopAddress: map['shop_address'] ?? 'اليمن - المركز الرئيسي',
      receiptTerms: map['receipt_terms'] ??
          '• الجهاز يسلم بموجب هذا السند الأصلي فقط.\n• المركز غير مسؤول عن الأجهزة المتروكة لأكثر من 30 يوماً من إشعار الجاهزية.',
      printLogoOnReceipt: map['print_logo_on_receipt'] != 'false',
      defaultWarrantyDays: int.tryParse(map['default_warranty_days'] ?? '30') ?? 30,
      printerConnectionType: map['printer_connection_type'] ?? 'bluetooth',
      printerDeviceAddress: map['printer_device_address'],
      printerPaperWidth: map['printer_paper_width'] ?? '58mm',
      autoPrintIntakeReceipt: map['auto_print_intake_receipt'] != 'false',
      autoPrintStickyTag: map['auto_print_sticky_tag'] != 'false',
      defaultCurrency: AppCurrency.fromCode(map['default_currency'] ?? 'YER'),
      lowStockThreshold: int.tryParse(map['low_stock_threshold'] ?? '2') ?? 2,
      requirePinForDiscounts: map['require_pin_for_discounts'] != 'false',
      autoLockTimeout: int.tryParse(map['auto_lock_timeout'] ?? '5') ?? 5,
      themeMode: _stringToThemeMode(map['theme_mode']),
      textScale: double.tryParse(map['text_scale'] ?? '1.0') ?? 1.0,
      enableCloudOcr: map['enable_cloud_ocr'] == 'true',
      ocrConfidenceThreshold: double.tryParse(map['ocr_confidence_threshold'] ?? '0.80') ?? 0.80,
      imageCompressionQuality: map['image_compression_quality'] ?? 'high',
    );
  }

  AppSettingsEntity copyWith({
    String? shopName,
    String? shopPhone,
    String? shopAddress,
    String? receiptTerms,
    bool? printLogoOnReceipt,
    int? defaultWarrantyDays,
    String? printerConnectionType,
    String? printerDeviceAddress,
    String? printerPaperWidth,
    bool? autoPrintIntakeReceipt,
    bool? autoPrintStickyTag,
    AppCurrency? defaultCurrency,
    int? lowStockThreshold,
    bool? requirePinForDiscounts,
    int? autoLockTimeout,
    ThemeMode? themeMode,
    double? textScale,
    bool? enableCloudOcr,
    double? ocrConfidenceThreshold,
    String? imageCompressionQuality,
  }) {
    return AppSettingsEntity(
      shopName: shopName ?? this.shopName,
      shopPhone: shopPhone ?? this.shopPhone,
      shopAddress: shopAddress ?? this.shopAddress,
      receiptTerms: receiptTerms ?? this.receiptTerms,
      printLogoOnReceipt: printLogoOnReceipt ?? this.printLogoOnReceipt,
      defaultWarrantyDays: defaultWarrantyDays ?? this.defaultWarrantyDays,
      printerConnectionType: printerConnectionType ?? this.printerConnectionType,
      printerDeviceAddress: printerDeviceAddress ?? this.printerDeviceAddress,
      printerPaperWidth: printerPaperWidth ?? this.printerPaperWidth,
      autoPrintIntakeReceipt: autoPrintIntakeReceipt ?? this.autoPrintIntakeReceipt,
      autoPrintStickyTag: autoPrintStickyTag ?? this.autoPrintStickyTag,
      defaultCurrency: defaultCurrency ?? this.defaultCurrency,
      lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
      requirePinForDiscounts: requirePinForDiscounts ?? this.requirePinForDiscounts,
      autoLockTimeout: autoLockTimeout ?? this.autoLockTimeout,
      themeMode: themeMode ?? this.themeMode,
      textScale: textScale ?? this.textScale,
      enableCloudOcr: enableCloudOcr ?? this.enableCloudOcr,
      ocrConfidenceThreshold: ocrConfidenceThreshold ?? this.ocrConfidenceThreshold,
      imageCompressionQuality: imageCompressionQuality ?? this.imageCompressionQuality,
    );
  }

  static String _themeModeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }

  static ThemeMode _stringToThemeMode(String? str) {
    switch (str) {
      case 'light':
        return ThemeMode.light;
      case 'system':
        return ThemeMode.system;
      case 'dark':
      default:
        return ThemeMode.dark;
    }
  }
}
