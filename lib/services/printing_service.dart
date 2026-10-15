import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../domain/entities/payment_entity.dart';
import '../domain/entities/repair_item_entity.dart';
import '../domain/entities/repair_record_entity.dart';

class PrintingService {
  PrintingService._internal();
  static final PrintingService instance = PrintingService._internal();

  pw.Font? _arabicFont;

  Future<pw.Font> _getArabicFont() async {
    if (_arabicFont != null) return _arabicFont!;
    try {
      final fontData = await rootBundle.load('assets/fonts/arabic_font.ttf');
      _arabicFont = pw.Font.ttf(fontData);
    } catch (_) {
      // احتياطي للأجهزة الافتراضية
      _arabicFont = pw.Font.helvetica();
    }
    return _arabicFont!;
  }

  /// 1. طباعة سند استلام جهاز حراري (58mm أو 80mm)
  Future<void> printIntakeReceipt({
    required RepairRecordEntity record,
    required String customerName,
    required String customerPhone,
    required String deviceBrand,
    required String deviceModel,
    String? serialNumber,
    String? physicalCondition,
    String? accessories,
    bool is80mm = true,
  }) async {
    final font = await _getArabicFont();
    final doc = pw.Document();
    final pageFormat = is80mm ? PdfPageFormat.roll80 : PdfPageFormat.roll57;

    doc.addPage(
      pw.Page(
        pageFormat: pageFormat,
        textDirection: pw.TextDirection.rtl,
        theme: pw.ThemeData.withFont(base: font, bold: font),
        build: (context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                // رأس السند
                pw.Text(
                  'صبر إلكترونكس',
                  style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
                ),
                pw.Text(
                  'للصيانة الإلكترونية التخصصية',
                  style: const pw.TextStyle(fontSize: 10),
                ),
                pw.Text(
                  'أجهزة طبية • شاشات سيارات • صوتيات • إنفرتر',
                  style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
                ),
                pw.Divider(thickness: 1),

                // رقم التذكرة والباركود
                pw.Text(
                  'سند استلام رقم: ${record.recordNumber}',
                  style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
                ),
                pw.Text(
                  'التاريخ: ${record.receivedAt.toString().substring(0, 16)}',
                  style: const pw.TextStyle(fontSize: 9),
                ),
                pw.SizedBox(height: 6),

                // رمز QR
                pw.BarcodeWidget(
                  barcode: pw.Barcode.qrCode(),
                  data: record.recordNumber,
                  width: 55,
                  height: 55,
                ),
                pw.SizedBox(height: 8),

                pw.Divider(borderStyle: pw.BorderStyle.dashed),

                // بيانات العميل والجهاز
                pw.Align(
                  alignment: pw.Alignment.centerRight,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('العميل: $customerName', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                      pw.Text('الهاتف: $customerPhone', style: const pw.TextStyle(fontSize: 9)),
                      pw.SizedBox(height: 4),
                      pw.Text('الجهاز: $deviceBrand $deviceModel', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                      if (serialNumber != null && serialNumber.isNotEmpty)
                        pw.Text('الرقم التسلسلي: $serialNumber', style: const pw.TextStyle(fontSize: 8)),
                      if (accessories != null && accessories.isNotEmpty)
                        pw.Text('الملحقات المستلمة: $accessories', style: const pw.TextStyle(fontSize: 8)),
                      if (physicalCondition != null && physicalCondition.isNotEmpty)
                        pw.Text('الحالة الظاهرية: $physicalCondition', style: const pw.TextStyle(fontSize: 8)),
                      pw.SizedBox(height: 4),
                      pw.Text('العطل المشكو منه:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                      pw.Text(record.problemDescription, style: const pw.TextStyle(fontSize: 8)),
                    ],
                  ),
                ),

                pw.Divider(borderStyle: pw.BorderStyle.dashed),

                // الدفعة المقدمة إن وجدت
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('العربون المدفوع:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                    pw.Text(
                      '${record.paidAmount.toStringAsFixed(0)} ${record.currency.symbol}',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                    ),
                  ],
                ),

                pw.Divider(thickness: 1),

                // شروط الاستلام
                pw.Text(
                  '• الجهاز يسلم بموجب هذا السند الأصلي فقط.',
                  style: const pw.TextStyle(fontSize: 7),
                ),
                pw.Text(
                  '• المركز غير مسؤول عن الأجهزة المتروكة لأكثر من 30 يوماً من إشعار الجاهزية.',
                  style: const pw.TextStyle(fontSize: 7),
                ),
                pw.SizedBox(height: 6),
                pw.Text(
                  'خدمة العملاء: 777000000',
                  style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
                ),
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => doc.save(),
      name: 'Intake_${record.recordNumber}',
    );
  }

  /// 2. طباعة ملصق هيكل لاصق صغير (Chassis Sticker)
  Future<void> printChassisSticker({
    required String recordNumber,
    required String customerName,
    required String customerPhone,
    required String deviceName,
    required DateTime date,
  }) async {
    final font = await _getArabicFont();
    final doc = pw.Document();

    // مقاس ملصق لاصق قياسي 50مم × 30مم
    const stickerFormat = PdfPageFormat(50 * PdfPageFormat.mm, 30 * PdfPageFormat.mm, marginAll: 2 * PdfPageFormat.mm);

    doc.addPage(
      pw.Page(
        pageFormat: stickerFormat,
        textDirection: pw.TextDirection.rtl,
        theme: pw.ThemeData.withFont(base: font, bold: font),
        build: (context) {
          return pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  children: [
                    pw.Text('صبر إلكترونكس', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                    pw.Text(recordNumber, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                    pw.Text(customerName, style: const pw.TextStyle(fontSize: 7), overflow: pw.TextOverflow.clip),
                    pw.Text(customerPhone, style: const pw.TextStyle(fontSize: 7)),
                    pw.Text(deviceName, style: const pw.TextStyle(fontSize: 6), overflow: pw.TextOverflow.clip),
                  ],
                ),
              ),
              pw.BarcodeWidget(
                barcode: pw.Barcode.qrCode(),
                data: recordNumber,
                width: 32,
                height: 32,
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => doc.save(),
      name: 'Sticker_$recordNumber',
    );
  }

  /// 3. فاتورة الصيانة والتسليم النهائي والضمان (Invoice & Warranty Receipt)
  Future<void> printFinalDeliveryInvoice({
    required RepairRecordEntity record,
    required String customerName,
    required String customerPhone,
    required String deviceName,
    required List<RepairItemEntity> items,
    required List<PaymentEntity> payments,
    bool is80mm = true,
  }) async {
    final font = await _getArabicFont();
    final doc = pw.Document();
    final pageFormat = is80mm ? PdfPageFormat.roll80 : PdfPageFormat.roll57;
    final currency = record.currency.symbol;

    doc.addPage(
      pw.Page(
        pageFormat: pageFormat,
        textDirection: pw.TextDirection.rtl,
        theme: pw.ThemeData.withFont(base: font, bold: font),
        build: (context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Text('صبر إلكترونكس', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                pw.Text('فاتورة صيانة وتسليم نهائي', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                pw.Divider(thickness: 1),

                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('سند: ${record.recordNumber}', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                    pw.Text('التسليم: ${DateTime.now().toString().substring(0, 10)}', style: const pw.TextStyle(fontSize: 8)),
                  ],
                ),
                pw.Align(
                  alignment: pw.Alignment.centerRight,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('العميل: $customerName ($customerPhone)', style: const pw.TextStyle(fontSize: 9)),
                      pw.Text('الجهاز: $deviceName', style: const pw.TextStyle(fontSize: 9)),
                    ],
                  ),
                ),
                pw.Divider(borderStyle: pw.BorderStyle.dashed),

                // جدول بنود الصيانة
                pw.Align(
                  alignment: pw.Alignment.centerRight,
                  child: pw.Text('بيان الأعمال والقطع:', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                ),
                pw.SizedBox(height: 4),

                ...items.map((item) {
                  return pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 2),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Expanded(
                          child: pw.Text(
                            '${item.description} (${item.quantity}×)',
                            style: const pw.TextStyle(fontSize: 8),
                          ),
                        ),
                        pw.Text(
                          '${item.totalPrice.toStringAsFixed(0)} $currency',
                          style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
                        ),
                      ],
                    ),
                  );
                }),

                pw.Divider(borderStyle: pw.BorderStyle.dashed),

                // الملخص المالي
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('إجمالي الحساب:', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                    pw.Text('${record.totalAmount.toStringAsFixed(0)} $currency', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                  ],
                ),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('المسدد:', style: const pw.TextStyle(fontSize: 9)),
                    pw.Text('${record.paidAmount.toStringAsFixed(0)} $currency', style: const pw.TextStyle(fontSize: 9)),
                  ],
                ),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('المتبقي:', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                    pw.Text(
                      record.remainingAmount > 0
                          ? '${record.remainingAmount.toStringAsFixed(0)} $currency'
                          : 'خالص الحساب',
                      style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
                    ),
                  ],
                ),

                pw.Divider(thickness: 1),

                // شريط الضمان المعتمد
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.black, width: 1),
                  ),
                  child: pw.Column(
                    children: [
                      pw.Text(
                        'الضمان الفني المعتمد: ${record.warrantyDays} يوماً',
                        style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
                      ),
                      pw.Text(
                        'يسري الضمان على الأعمال والقطع المبينة أعلاه.',
                        style: const pw.TextStyle(fontSize: 7),
                      ),
                      pw.Text(
                        'لا يشمل الضمان الكسر، السوائل، وسوء الاستخدام.',
                        style: const pw.TextStyle(fontSize: 7),
                      ),
                    ],
                  ),
                ),

                pw.SizedBox(height: 12),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('توقيع الفني المسؤول: ________', style: const pw.TextStyle(fontSize: 7)),
                    pw.Text('توقيع المستلم: ________', style: const pw.TextStyle(fontSize: 7)),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => doc.save(),
      name: 'Invoice_${record.recordNumber}',
    );
  }
}
