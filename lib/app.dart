import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/constants/app_strings.dart';
import 'core/theme/app_theme.dart';
import 'presentation/features/dashboard/screens/dashboard_screen.dart';

/// تطبيق صبر إلكترونكس الرئيسي
class SabrElectronicsApp extends ConsumerWidget {
  const SabrElectronicsApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,

      // إعدادات الثيم والوضع الداكن الافتراضي
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,

      // دعم اللغة العربية واتجاه اليمين لليسار RTL بنسبة 100%
      locale: const Locale('ar'),
      supportedLocales: const [
        Locale('ar'),
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
