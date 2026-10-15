import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // تشغيل التطبيق محاطاً بـ ProviderScope لإدارة الحالة عبر Riverpod
  runApp(
    const ProviderScope(
      child: SabrElectronicsApp(),
    ),
  );
}
