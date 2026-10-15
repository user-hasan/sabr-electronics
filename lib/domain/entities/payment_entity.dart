import '../enums/app_currency.dart';
import '../enums/payment_method.dart';

class PaymentEntity {
  final int? id;
  final String receiptNumber;
  final int repairRecordId;
  final int customerId;
  final double amount;
  final AppCurrency currency;
  final PaymentMethod paymentMethod;
  final int receivedByUserId;
  final DateTime paidAt;
  final String? notes;

  const PaymentEntity({
    this.id,
    required this.receiptNumber,
    required this.repairRecordId,
    required this.customerId,
    required this.amount,
    this.currency = AppCurrency.yer,
    this.paymentMethod = PaymentMethod.cash,
    required this.receivedByUserId,
    required this.paidAt,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'receiptNumber': receiptNumber,
      'repairRecordId': repairRecordId,
      'customerId': customerId,
      'amount': amount,
      'currency': currency.code,
      'paymentMethod': paymentMethod.code,
      'receivedByUserId': receivedByUserId,
      'paidAt': paidAt.toIso8601String(),
      'notes': notes,
    };
  }

  factory PaymentEntity.fromMap(Map<String, dynamic> map) {
    return PaymentEntity(
      id: map['id'] as int?,
      receiptNumber: map['receiptNumber'] as String,
      repairRecordId: map['repairRecordId'] as int,
      customerId: map['customerId'] as int,
      amount: (map['amount'] as num).toDouble(),
      currency: AppCurrency.fromCode((map['currency'] as String?) ?? 'YER'),
      paymentMethod: PaymentMethod.fromCode(map['paymentMethod'] as String),
      receivedByUserId: map['receivedByUserId'] as int,
      paidAt: DateTime.parse(map['paidAt'] as String),
      notes: map['notes'] as String?,
    );
  }
}
