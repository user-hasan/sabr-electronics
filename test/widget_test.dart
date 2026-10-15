import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sabr_electronics/app.dart';

void main() {
  testWidgets('Sabr Electronics App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: SabrElectronicsApp(),
      ),
    );

    // التحقق من ظهور اسم التطبيق والتخصص المعتمد
    expect(find.text('صبر إلكترونكس'), findsWidgets);
    expect(find.text('العملات المعتمدة:'), findsOneWidget);
  });
}
