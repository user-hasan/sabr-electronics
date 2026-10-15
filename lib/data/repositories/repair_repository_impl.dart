import 'package:sqflite/sqflite.dart';
import '../../domain/entities/payment_entity.dart';
import '../../domain/entities/repair_item_entity.dart';
import '../../domain/entities/repair_record_entity.dart';
import '../../domain/enums/repair_status.dart';
import '../../domain/repositories/repair_repository.dart';
import '../datasources/local/database_helper.dart';

class RepairRepositoryImpl implements RepairRepository {
  final DatabaseHelper dbHelper;

  RepairRepositoryImpl({DatabaseHelper? dbHelper})
      : dbHelper = dbHelper ?? DatabaseHelper.instance;

  @override
  Future<List<RepairRecordEntity>> getAllRepairs({RepairStatus? status}) async {
    final db = await dbHelper.database;
    final results = await db.query(
      'repair_records',
      where: status != null ? 'status = ?' : null,
      whereArgs: status != null ? [status.code] : null,
      orderBy: 'id DESC',
    );
    return results.map((m) => RepairRecordEntity.fromMap(m)).toList();
  }

  @override
  Future<RepairRecordEntity?> getRepairById(int id) async {
    final db = await dbHelper.database;
    final results = await db.query(
      'repair_records',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (results.isEmpty) return null;
    return RepairRecordEntity.fromMap(results.first);
  }

  @override
  Future<RepairRecordEntity?> getRepairByRecordNumber(String recordNumber) async {
    final db = await dbHelper.database;
    final cleanNum = recordNumber.trim();
    final results = await db.query(
      'repair_records',
      where: 'recordNumber = ?',
      whereArgs: [cleanNum],
      limit: 1,
    );
    if (results.isEmpty) return null;
    return RepairRecordEntity.fromMap(results.first);
  }

  @override
  Future<List<Map<String, dynamic>>> searchRepairsWithDetails(String query, {RepairStatus? status}) async {
    final db = await dbHelper.database;
    final cleanQuery = '%${query.trim()}%';

    String whereSql = '''
      (r.recordNumber LIKE ? OR c.name LIKE ? OR c.phone LIKE ? OR d.brand LIKE ? OR d.model LIKE ?)
    ''';
    List<dynamic> args = [cleanQuery, cleanQuery, cleanQuery, cleanQuery, cleanQuery];

    if (status != null) {
      whereSql += ' AND r.status = ?';
      args.add(status.code);
    }

    final sql = '''
      SELECT 
        r.*,
        c.name AS customerName,
        c.phone AS customerPhone,
        d.brand AS deviceBrand,
        d.model AS deviceModel,
        d.category AS deviceCategory,
        d.deviceType AS deviceType
      FROM repair_records r
      JOIN customers c ON r.customerId = c.id
      JOIN devices d ON r.deviceId = d.id
      WHERE $whereSql
      ORDER BY r.id DESC
      LIMIT 100
    ''';

    return await db.rawQuery(sql, args);
  }

  @override
  Future<Map<String, dynamic>?> getRepairFullDetails(int repairId) async {
    final db = await dbHelper.database;

    final repairRes = await db.query(
      'repair_records',
      where: 'id = ?',
      whereArgs: [repairId],
      limit: 1,
    );
    if (repairRes.isEmpty) return null;

    final repair = RepairRecordEntity.fromMap(repairRes.first);

    final custRes = await db.query('customers', where: 'id = ?', whereArgs: [repair.customerId], limit: 1);
    final devRes = await db.query('devices', where: 'id = ?', whereArgs: [repair.deviceId], limit: 1);
    final itemsRes = await db.query('repair_items', where: 'repairRecordId = ?', whereArgs: [repairId], orderBy: 'id ASC');
    final paymentsRes = await db.query('payments', where: 'repairRecordId = ?', whereArgs: [repairId], orderBy: 'id DESC');

    return {
      'record': repair,
      'customer': custRes.isNotEmpty ? custRes.first : null,
      'device': devRes.isNotEmpty ? devRes.first : null,
      'items': itemsRes.map((m) => RepairItemEntity.fromMap(m)).toList(),
      'payments': paymentsRes.map((m) => PaymentEntity.fromMap(m)).toList(),
    };
  }

  @override
  Future<bool> updateRepairStatus(int id, RepairStatus newStatus, {String? diagnosticNotes}) async {
    final db = await dbHelper.database;
    final now = DateTime.now().toIso8601String();

    final values = <String, dynamic>{
      'status': newStatus.code,
      'updatedAt': now,
    };

    if (newStatus == RepairStatus.delivered) {
      values['deliveredAt'] = now;
    }
    if (diagnosticNotes != null) {
      values['diagnosticNotes'] = diagnosticNotes;
    }

    final rows = await db.update(
      'repair_records',
      values,
      where: 'id = ?',
      whereArgs: [id],
    );
    return rows > 0;
  }

  @override
  Future<bool> updateDiagnosticNotes(int id, String notes) async {
    final db = await dbHelper.database;
    final now = DateTime.now().toIso8601String();

    final rows = await db.update(
      'repair_records',
      {
        'diagnosticNotes': notes,
        'updatedAt': now,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
    return rows > 0;
  }

  @override
  Future<bool> addRepairItem(RepairItemEntity item) async {
    final db = await dbHelper.database;
    return await db.transaction((txn) async {
      // 1. إذا كان البند قطعة غيار، خصم الكمية من المستودع
      if (item.sparePartId != null) {
        final partRes = await txn.query(
          'spare_parts',
          columns: ['stockQuantity'],
          where: 'id = ?',
          whereArgs: [item.sparePartId],
          limit: 1,
        );

        if (partRes.isEmpty) return false;
        final currentStock = partRes.first['stockQuantity'] as int;
        if (currentStock < item.quantity) {
          throw Exception('الكمية المطلوبة ($item.quantity) تتجاوز المخزون المتوفر ($currentStock)');
        }

        await txn.update(
          'spare_parts',
          {
            'stockQuantity': currentStock - item.quantity,
            'updatedAt': DateTime.now().toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: [item.sparePartId],
        );
      }

      // 2. إدراج البند
      await txn.insert('repair_items', item.toMap());

      // 3. إعادة حساب التكاليف والإجمالي في التذكرة
      await _recalculateRepairTotals(txn, item.repairRecordId);
      return true;
    });
  }

  @override
  Future<bool> deleteRepairItem(int itemId) async {
    final db = await dbHelper.database;
    return await db.transaction((txn) async {
      final itemRes = await txn.query(
        'repair_items',
        where: 'id = ?',
        whereArgs: [itemId],
        limit: 1,
      );
      if (itemRes.isEmpty) return false;

      final item = RepairItemEntity.fromMap(itemRes.first);

      // استعادة المخزون إذا كان قطعة غيار
      if (item.sparePartId != null) {
        final partRes = await txn.query(
          'spare_parts',
          columns: ['stockQuantity'],
          where: 'id = ?',
          whereArgs: [item.sparePartId],
          limit: 1,
        );

        if (partRes.isNotEmpty) {
          final currentStock = partRes.first['stockQuantity'] as int;
          await txn.update(
            'spare_parts',
            {
              'stockQuantity': currentStock + item.quantity,
              'updatedAt': DateTime.now().toIso8601String(),
            },
            where: 'id = ?',
            whereArgs: [item.sparePartId],
          );
        }
      }

      await txn.delete('repair_items', where: 'id = ?', whereArgs: [itemId]);
      await _recalculateRepairTotals(txn, item.repairRecordId);
      return true;
    });
  }

  @override
  Future<List<RepairItemEntity>> getRepairItems(int repairRecordId) async {
    final db = await dbHelper.database;
    final results = await db.query(
      'repair_items',
      where: 'repairRecordId = ?',
      whereArgs: [repairRecordId],
      orderBy: 'id ASC',
    );
    return results.map((m) => RepairItemEntity.fromMap(m)).toList();
  }

  @override
  Future<int> recordPayment(PaymentEntity payment) async {
    final db = await dbHelper.database;
    return await db.transaction((txn) async {
      final paymentId = await txn.insert('payments', payment.toMap());

      // جمع كافة المدفوعات المسجلة للتذكرة
      final paySumRes = await txn.rawQuery(
        'SELECT SUM(amount) AS totalPaid FROM payments WHERE repairRecordId = ?',
        [payment.repairRecordId],
      );
      final totalPaid = (paySumRes.first['totalPaid'] as num?)?.toDouble() ?? 0.0;

      // قراءة الإجمالي الحالي
      final recRes = await txn.query(
        'repair_records',
        columns: ['totalAmount'],
        where: 'id = ?',
        whereArgs: [payment.repairRecordId],
        limit: 1,
      );
      final totalAmount = (recRes.first['totalAmount'] as num).toDouble();
      final remaining = (totalAmount - totalPaid) > 0 ? (totalAmount - totalPaid) : 0.0;

      await txn.update(
        'repair_records',
        {
          'paidAmount': totalPaid,
          'remainingAmount': remaining,
          'updatedAt': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [payment.repairRecordId],
      );

      return paymentId;
    });
  }

  @override
  Future<List<PaymentEntity>> getPaymentsForRepair(int repairRecordId) async {
    final db = await dbHelper.database;
    final results = await db.query(
      'payments',
      where: 'repairRecordId = ?',
      whereArgs: [repairRecordId],
      orderBy: 'id DESC',
    );
    return results.map((m) => PaymentEntity.fromMap(m)).toList();
  }

  @override
  Future<bool> updateDiscount(int repairId, double discountAmount) async {
    final db = await dbHelper.database;
    return await db.transaction((txn) async {
      await txn.update(
        'repair_records',
        {
          'discountAmount': discountAmount,
          'updatedAt': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [repairId],
      );

      await _recalculateRepairTotals(txn, repairId);
      return true;
    });
  }

  Future<void> _recalculateRepairTotals(DatabaseExecutor txn, int repairRecordId) async {
    // 1. حساب تكلفة القطع وأجور الصيانة
    final partsRes = await txn.rawQuery(
      "SELECT SUM(totalPrice) AS partsTotal FROM repair_items WHERE repairRecordId = ? AND itemType = 'spare_part'",
      [repairRecordId],
    );
    final laborRes = await txn.rawQuery(
      "SELECT SUM(totalPrice) AS laborTotal FROM repair_items WHERE repairRecordId = ? AND itemType = 'labor'",
      [repairRecordId],
    );

    final partsCost = (partsRes.first['partsTotal'] as num?)?.toDouble() ?? 0.0;
    final laborCost = (laborRes.first['laborTotal'] as num?)?.toDouble() ?? 0.0;

    // 2. قراءة الخصم والمدفوع
    final recRes = await txn.query(
      'repair_records',
      columns: ['discountAmount', 'paidAmount'],
      where: 'id = ?',
      whereArgs: [repairRecordId],
      limit: 1,
    );

    if (recRes.isEmpty) return;

    final discount = (recRes.first['discountAmount'] as num?)?.toDouble() ?? 0.0;
    final paidAmount = (recRes.first['paidAmount'] as num?)?.toDouble() ?? 0.0;

    final totalAmount = (partsCost + laborCost) - discount;
    final remainingAmount = (totalAmount - paidAmount) > 0 ? (totalAmount - paidAmount) : 0.0;

    await txn.update(
      'repair_records',
      {
        'partsCost': partsCost,
        'laborCost': laborCost,
        'totalAmount': totalAmount > 0 ? totalAmount : 0.0,
        'remainingAmount': remainingAmount,
        'updatedAt': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [repairRecordId],
    );
  }

  @override
  String generateWhatsAppMessage({
    required RepairRecordEntity record,
    required String customerName,
    required String deviceName,
    String? shopName,
    String? shopPhone,
  }) {
    final title = shopName ?? 'صبر إلكترونكس للصيانة التخصصية';
    final currency = record.currency.symbol;

    switch (record.status) {
      case RepairStatus.received:
        return '''
عزيزنا العميل $customerName المحترم،
تحية طيبة من مركز $title.

تم استلام جهازكم ($deviceName) بنجاح.
* رقم التذكرة: ${record.recordNumber}
* العطل المذكور: ${record.problemDescription}
* العربون المدفوع: ${record.paidAmount.toStringAsFixed(0)} $currency

سيتم إبلاغكم فور انتهاء الفحص الهندسي الأولي.
نشكر ثقتكم بنا.
'''.trim();

      case RepairStatus.inspection:
        return '''
عزيزنا العميل $customerName المحترم،
من مركز $title.

جهازكم ($deviceName) - تذكرة رقم: ${record.recordNumber} قيد الفحص والتشخيص الهندسي المخبري حالياً.
سنوافيكم بتقرير الفحص قريباً.
'''.trim();

      case RepairStatus.waitingApproval:
        return '''
عزيزنا العميل $customerName المحترم،
من مركز $title.

اكتمل فحص جهازكم ($deviceName) - تذكرة رقم: ${record.recordNumber}.
* تكلفة الصيانة المقدرة: ${record.estimatedCost.toStringAsFixed(0)} $currency
* الملاحظات: ${record.diagnosticNotes ?? 'بانتظار موافقتكم الكريمة للبدء بالإصلاح'}

يرجى إفادتنا بالموافقة للمتابعة.
'''.trim();

      case RepairStatus.inProgress:
        return '''
عزيزنا العميل $customerName المحترم،
من مركز $title.

نفيدكم بأنه جارٍ العمل حالياً على صيانة جهازكم ($deviceName) - تذكرة رقم: ${record.recordNumber}.
* الفحص والتشخيص الفني: ${record.diagnosticNotes ?? 'قيد المعالجة المخبرية'}

سنوافيكم بالمستجدات فور جهوزية الجهاز.
'''.trim();

      case RepairStatus.waitingParts:
        return '''
عزيزنا العميل $customerName المحترم،
من مركز $title.

نحيطكم علماً بأن جهازكم ($deviceName) - تذكرة رقم: ${record.recordNumber} بانتظار توفير القطع الإلكترونية الأصلية اللازمة لإتمام عملية الصيانة بأعلى معايير الجودة.
'''.trim();

      case RepairStatus.ready:
        return '''
بشرى سارة عزيزنا العميل $customerName المحترم،
من مركز $title.

جهازكم ($deviceName) جاهز للاستلام الآن بعد اكتمال الصيانة والفحص النهائي بنجاح!
* رقم السند: ${record.recordNumber}
* إجمالي الحساب: ${record.totalAmount.toStringAsFixed(0)} $currency
* المدفوع سابقاً: ${record.paidAmount.toStringAsFixed(0)} $currency
* المبلغ المتبقي: ${record.remainingAmount.toStringAsFixed(0)} $currency
* فترة الضمان المعتمدة: ${record.warrantyDays} يوماً

أوقات الدوام واستقبال العملاء: يومياً من 8 صباحاً حتى 9 مساءً.
أهلاً وسهلاً بكم.
'''.trim();

      case RepairStatus.delivered:
        return '''
عزيزنا العميل $customerName المحترم،
شكراً لاختياركم مركز $title.

تم تسليم جهازكم ($deviceName) بحمد الله - سند رقم: ${record.recordNumber}.
* الضمان الفني سارٍ لمدة ${record.warrantyDays} يوماً من تاريخ اليوم.
يسعدنا دائماً خدمتكم.
'''.trim();

      case RepairStatus.cancelled:
        return '''
عزيزنا العميل $customerName المحترم،
من مركز $title.

نفيدكم بأن تذكرة الصيانة رقم ${record.recordNumber} الخاصة بجهازكم ($deviceName) قد أُلغيت. يرجى مراجعة المركز لاستلام الجهاز.
'''.trim();
    }
  }
}
