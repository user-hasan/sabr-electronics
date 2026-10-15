/// طرق الدفع والسداد المعتمدة في تطبيق صبر إلكترونكس
enum PaymentMethod {
  cash('cash', 'نقداً'),
  kuraimi('kuraimi', 'حساب الكريمي مميز'),
  jawali('jawali', 'محفظة جوالي / كاش إلكتروني'),
  bankTransfer('bank_transfer', 'تحويل بنكي مباشر');

  final String code;
  final String label;

  const PaymentMethod(this.code, this.label);

  static PaymentMethod fromCode(String code) {
    return PaymentMethod.values.firstWhere(
      (m) => m.code.toLowerCase() == code.toLowerCase(),
      orElse: () => PaymentMethod.cash,
    );
  }
}
