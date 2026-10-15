/// العملات الثلاث المعتمدة في تطبيق صبر إلكترونكس
enum AppCurrency {
  yer('YER', 'ريال يمني', 'ر.ي'),
  sar('SAR', 'ريال سعودي', 'ر.س'),
  usd('USD', 'دولار أمريكي', '\$');

  final String code;
  final String label;
  final String symbol;

  const AppCurrency(this.code, this.label, this.symbol);

  static AppCurrency fromCode(String code) {
    return AppCurrency.values.firstWhere(
      (c) => c.code.toUpperCase() == code.toUpperCase(),
      orElse: () => AppCurrency.yer,
    );
  }
}
