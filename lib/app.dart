import 'package:device_preview/device_preview.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/constants/app_strings.dart';
import 'core/theme/app_theme.dart';
import 'presentation/features/dashboard/screens/dashboard_screen.dart';

import 'presentation/providers/settings_provider.dart';

/// تطبيق صبر إلكترونكس الرئيسي
class SabrElectronicsApp extends ConsumerWidget {
  const SabrElectronicsApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentThemeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,

      // ربط محاكي الهيكل DevicePreview
      locale: DevicePreview.locale(context) ?? const Locale('ar'),
      builder: DevicePreview.appBuilder,

      // إعدادات الثيم المرتبطة بالإعدادات التفاعلية
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: currentThemeMode,

      // دعم اللغة العربية واتجاه اليمين لليسار RTL بنسبة 100%
      supportedLocales: const [
        Locale('ar'),
        Locale('en'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      // الشاشة الرئيسية المبدئية
      home: const DashboardScreen(),
    );
  }
}
