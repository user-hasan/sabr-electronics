import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/repositories/repair_repository_impl.dart';
import '../../../../data/repositories/spare_part_repository_impl.dart';
import '../../../../domain/entities/payment_entity.dart';
import '../../../../domain/entities/repair_item_entity.dart';
import '../../../../domain/entities/repair_record_entity.dart';
import '../../../../domain/entities/spare_part_entity.dart';
import '../../../../domain/enums/payment_method.dart';
import '../../../../domain/enums/repair_status.dart';
import '../../../../data/repositories/auth_repository_impl.dart';
import '../../../../domain/entities/user_entity.dart';
import '../../../../services/printing_service.dart';

class RepairDetailsScreen extends StatefulWidget {
  final int repairId;

  const RepairDetailsScreen({super.key, required this.repairId});

  @override
  State<RepairDetailsScreen> createState() => _RepairDetailsScreenState();
}

class _RepairDetailsScreenState extends State<RepairDetailsScreen> {
  final _repairRepo = RepairRepositoryImpl();
  final _sparePartRepo = SparePartRepositoryImpl();
  final _authRepo = AuthRepositoryImpl();
  UserEntity? _currentUser;

  bool _isLoading = true;
  Map<String, dynamic>? _details;

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    setState(() => _isLoading = true);
    final data = await _repairRepo.getRepairFullDetails(widget.repairId);
    final user = await _authRepo.getCurrentUser();
    if (mounted) {
      setState(() {
        _details = data;
        _currentUser = user;
        _isLoading = false;
      });
    }
  }

  Future<void> _updateStatus(RepairStatus newStatus) async {
    final success = await _repairRepo.updateRepairStatus(widget.repairId, newStatus);
    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تم تحديث حالة الجهاز إلى: ${newStatus.label}')),
        );
      }
      _loadDetails();
    }
  }

  Future<void> _editDiagnosticNotes(String currentNotes) async {
    final controller = TextEditingController(text: currentNotes);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('تقرير الفحص والتشخيص الهندسي'),
          content: SizedBox(
            width: 450,
            child: TextField(
              controller: controller,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'اكتب نتائج الفحص المخبري، الدوائر التالفة، الملاحظات الفنية...',
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('حفظ التقرير'),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true) {
      await _repairRepo.updateDiagnosticNotes(widget.repairId, controller.text.trim());
      _loadDetails();
    }
  }

  Future<void> _addSparePartItem() async {
    final parts = await _sparePartRepo.getAllSpareParts();
    if (!mounted) return;

    if (parts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('المستودع فارغ، يرجى إضافة قطع غيار أولاً')),
      );
      return;
    }

    SparePartEntity selectedPart = parts.first;
    int qty = 1;
    final priceController = TextEditingController(text: selectedPart.sellingPrice.toStringAsFixed(0));

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text('إضافة قطعة غيار من المستودع'),
            content: SizedBox(
              width: 450,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<SparePartEntity>(
                    initialValue: selectedPart,
                    decoration: const InputDecoration(labelText: 'اختر القطعة *'),
                    items: parts.map((p) {
                      return DropdownMenuItem(
                        value: p,
                        child: Text('${p.name} (متوفر: ${p.stockQuantity})'),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() {
                          selectedPart = val;
                          priceController.text = val.sellingPrice.toStringAsFixed(0);
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          initialValue: qty.toString(),
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'الكمية المستهلكة'),
                          onChanged: (v) => qty = int.tryParse(v) ?? 1,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: priceController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'سعر الوحدة'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('إلغاء')),
              ElevatedButton(
                onPressed: () {
                  if (selectedPart.stockQuantity < qty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('الكمية المتوفرة بالمخزن (${selectedPart.stockQuantity}) أقل من المطلوب')),
                    );
                    return;
                  }
                  Navigator.of(context).pop(true);
                },
                child: const Text('إضافة وخصم من المخزن'),
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed == true) {
      final unitPrice = double.tryParse(priceController.text) ?? selectedPart.sellingPrice;
      final item = RepairItemEntity(
        repairRecordId: widget.repairId,
        itemType: 'spare_part',
        sparePartId: selectedPart.id,
        description: selectedPart.name,
        unitCost: selectedPart.costPrice,
        unitPrice: unitPrice,
        quantity: qty,
        totalPrice: unitPrice * qty,
        createdAt: DateTime.now(),
      );

      try {
        await _repairRepo.addRepairItem(item);
        _loadDetails();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e')));
        }
      }
    }
  }

  Future<void> _addLaborItem() async {
    final descController = TextEditingController();
    final priceController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('إضافة أجور صيانة وفحص فني'),
          content: SizedBox(
            width: 450,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(
                    labelText: 'وصف العمل الهندسي *',
                    hintText: 'مثال: لحام معالج، إصلاح مسار تغذية، تنظيف وإعادة معايرة',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: priceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'أجور اليد والخدمة *',
                    hintText: 'المبلغ',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: () {
                if (descController.text.trim().isEmpty || priceController.text.trim().isEmpty) return;
                Navigator.of(context).pop(true);
              },
              child: const Text('إضافة'),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true) {
      final price = double.tryParse(priceController.text.trim()) ?? 0.0;
      final item = RepairItemEntity(
        repairRecordId: widget.repairId,
        itemType: 'labor',
        description: descController.text.trim(),
        unitPrice: price,
        quantity: 1,
        totalPrice: price,
        createdAt: DateTime.now(),
      );

      await _repairRepo.addRepairItem(item);
      _loadDetails();
    }
  }

  Future<void> _deleteItem(int itemId) async {
    await _repairRepo.deleteRepairItem(itemId);
    _loadDetails();
  }

  Future<void> _recordPaymentDialog(RepairRecordEntity record, Map<String, dynamic> customer) async {
    final amountController = TextEditingController(text: record.remainingAmount.toStringAsFixed(0));
    final notesController = TextEditingController();
    PaymentMethod method = PaymentMethod.cash;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text('تسجيل دفعة نقدية / سند قبض'),
            content: SizedBox(
              width: 420,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'المتبقي على العميل: ${record.remainingAmount.toStringAsFixed(0)} ${record.currency.symbol}',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.accent, fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'المبلغ المدفوع *',
                      suffixText: record.currency.symbol,
                      prefixIcon: const Icon(Icons.payments_rounded),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<PaymentMethod>(
                    initialValue: method,
                    decoration: const InputDecoration(labelText: 'طريقة الدفع *'),
                    items: PaymentMethod.values.map((m) {
                      return DropdownMenuItem(value: m, child: Text(m.label));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setDialogState(() => method = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: notesController,
                    decoration: const InputDecoration(
                      labelText: 'ملاحظات الدفعة (اختياري)',
                      hintText: 'رقم حوالة، اسم المستلم...',
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('إلغاء')),
              ElevatedButton.icon(
                onPressed: () => Navigator.of(context).pop(true),
                icon: const Icon(Icons.check_rounded),
                label: const Text('حفظ السند والترحيل'),
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed == true) {
      final amount = double.tryParse(amountController.text.trim()) ?? 0.0;
      if (amount <= 0) return;

      final now = DateTime.now();
      final receiptNumber = 'PAY-${now.year}-${now.millisecondsSinceEpoch.toString().substring(7)}';

      final payment = PaymentEntity(
        receiptNumber: receiptNumber,
        repairRecordId: widget.repairId,
        customerId: customer['id'] as int,
        amount: amount,
        currency: record.currency,
        paymentMethod: method,
        receivedByUserId: _currentUser?.id ?? 1,
        paidAt: now,
        notes: notesController.text.trim().isEmpty ? null : notesController.text.trim(),
      );

      await _repairRepo.recordPayment(payment);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تم تسجيل سند القبض $receiptNumber بنجاح')),
        );
      }
      _loadDetails();
    }
  }

  void _showWhatsAppDialog(RepairRecordEntity record, Map<String, dynamic> customer, Map<String, dynamic> device) {
    final message = _repairRepo.generateWhatsAppMessage(
      record: record,
      customerName: customer['name'] as String,
      deviceName: '${device['brand']} ${device['model']}',
    );

    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: Row(
            children: const [
              Icon(Icons.chat_rounded, color: AppColors.statusReady),
              SizedBox(width: 8),
              Text('إشعار العميل عبر واتساب'),
            ],
          ),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: SelectableText(
                message,
                style: const TextStyle(fontSize: 14, height: 1.5),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('إغلاق'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: message));
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم نسخ نص الرسالة إلى الحافظة بنجاح')),
                );
              },
              icon: const Icon(Icons.copy_rounded),
              label: const Text('نسخ الرسالة'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_details == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('تفاصيل الصيانة')),
        body: const Center(child: Text('لم يتم العثور على تذكرة الصيانة')),
      );
    }

    final record = _details!['record'] as RepairRecordEntity;
    final customer = _details!['customer'] as Map<String, dynamic>? ?? {};
    final device = _details!['device'] as Map<String, dynamic>? ?? {};
    final items = (_details!['items'] as List<RepairItemEntity>?) ?? [];
    final payments = (_details!['payments'] as List<PaymentEntity>?) ?? [];

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text('تذكرة: ${record.recordNumber}'),
          actions: [
            PopupMenuButton<String>(
              tooltip: 'الطباعة الحرارية والمستندات',
              icon: const Icon(Icons.print_rounded, color: AppColors.primary),
              onSelected: (val) {
                if (val == 'intake') {
                  PrintingService.instance.printIntakeReceipt(
                    record: record,
                    customerName: customer['name'] as String? ?? '',
                    customerPhone: customer['phone'] as String? ?? '',
                    deviceBrand: device['brand'] as String? ?? '',
                    deviceModel: device['model'] as String? ?? '',
                    serialNumber: device['serialNumber'] as String?,
                    physicalCondition: device['physicalCondition'] as String?,
                    accessories: device['receivedAccessories'] as String?,
                  );
                } else if (val == 'sticker') {
                  PrintingService.instance.printChassisSticker(
                    recordNumber: record.recordNumber,
                    customerName: customer['name'] as String? ?? '',
                    customerPhone: customer['phone'] as String? ?? '',
                    deviceName: '${device['brand'] ?? ''} ${device['model'] ?? ''}',
                    date: record.receivedAt,
                  );
                } else if (val == 'invoice') {
                  PrintingService.instance.printFinalDeliveryInvoice(
                    record: record,
                    customerName: customer['name'] as String? ?? '',
                    customerPhone: customer['phone'] as String? ?? '',
                    deviceName: '${device['brand'] ?? ''} ${device['model'] ?? ''}',
                    items: items,
                    payments: payments,
                  );
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'intake',
                  child: Row(
                    children: [
                      Icon(Icons.receipt_rounded, size: 18),
                      SizedBox(width: 8),
                      Text('سند استلام الجهاز (حراري)'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'sticker',
                  child: Row(
                    children: [
                      Icon(Icons.label_rounded, size: 18),
                      SizedBox(width: 8),
                      Text('ملصق باركود الهيكل اللاصق'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'invoice',
                  child: Row(
                    children: [
                      Icon(Icons.task_alt_rounded, size: 18, color: AppColors.statusReady),
                      SizedBox(width: 8),
                      Text('فاتورة التسليم والضمان'),
                    ],
                  ),
                ),
              ],
            ),
            IconButton(
              tooltip: 'مشاركة إشعار واتساب للعميل',
              icon: const Icon(Icons.chat_rounded, color: AppColors.statusReady),
              onPressed: () => _showWhatsAppDialog(record, customer, device),
            ),
            IconButton(
              tooltip: 'تسجيل دفعة مالية',
              icon: const Icon(Icons.add_card_rounded, color: AppColors.accent),
              onPressed: () => _recordPaymentDialog(record, customer),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. شريط مراحل الحالة الهندسية التفاعلي
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceDark,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderDark),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'مراحل مسار الصيانة الميدانية:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textSecondaryDark),
                    ),
                    const SizedBox(height: 10),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          RepairStatus.received,
                          RepairStatus.inspection,
                          RepairStatus.inProgress,
                          RepairStatus.waitingParts,
                          RepairStatus.ready,
                          RepairStatus.delivered,
                        ].map<Widget>((RepairStatus s) {
                          final isCurrent = record.status == s;
                          return Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: ChoiceChip(
                              avatar: Icon(
                                isCurrent ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                                size: 16,
                                color: isCurrent ? AppColors.bgDark : AppColors.textSecondaryDark,
                              ),
                              label: Text(s.label),
                              selected: isCurrent,
                              selectedColor: AppColors.primary,
                              onSelected: (selected) {
                                if (selected && !isCurrent) {
                                  _updateStatus(s);
                                }
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 2. بطاقة معلومات العميل والجهاز
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceDark,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.borderDark),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.person_rounded, size: 18, color: AppColors.primary),
                              SizedBox(width: 6),
                              Text('بيانات العميل', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            ],
                          ),
                          const Divider(height: 16),
                          Text('الاسم: ${customer['name'] ?? '—'}', style: const TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          Text('الهاتف: ${customer['phone'] ?? '—'}', style: const TextStyle(color: AppColors.textSecondaryDark)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceDark,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.borderDark),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.devices_other_rounded, size: 18, color: AppColors.primary),
                              SizedBox(width: 6),
                              Text('بيانات الجهاز', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            ],
                          ),
                          const Divider(height: 16),
                          Text('الموديل: ${device['brand'] ?? ''} ${device['model'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          Text('العطل: ${record.problemDescription}', style: const TextStyle(color: AppColors.textSecondaryDark)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // 3. تقرير التشخيص والفحص الهندسي
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceDark,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderDark),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.biotech_rounded, size: 20, color: AppColors.primary),
                            SizedBox(width: 8),
                            Text('تقرير التشخيص المخبري والفحص', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          ],
                        ),
                        TextButton.icon(
                          onPressed: () => _editDiagnosticNotes(record.diagnosticNotes ?? ''),
                          icon: const Icon(Icons.edit_note_rounded, size: 18),
                          label: const Text('تعديل التقرير'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      record.diagnosticNotes?.isNotEmpty == true
                          ? record.diagnosticNotes!
                          : 'لم يتم تدوين ملاحظات فحص بعد. انقر على تعديل لتدوين التشخيص.',
                      style: TextStyle(
                        color: record.diagnosticNotes?.isNotEmpty == true ? AppColors.textPrimaryDark : AppColors.textSecondaryDark,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 4. جدول بنود الصيانة (قطع غيار + أجور يد)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('بنود الصيانة والمكونات المستهلكة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Row(
                    children: [
                      OutlinedButton.icon(
                        onPressed: _addSparePartItem,
                        icon: const Icon(Icons.memory_rounded, size: 18),
                        label: const Text('قطعة من المستودع'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: _addLaborItem,
                        icon: const Icon(Icons.handyman_rounded, size: 18),
                        label: const Text('أجور صيانة'),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),

              Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceDark,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderDark),
                ),
                child: items.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(
                          child: Text(
                            'لم تتم إضافة أي قطع أو أجور صيانة حتى الآن',
                            style: TextStyle(color: AppColors.textSecondaryDark),
                          ),
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: items.length,
                        separatorBuilder: (context, index) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final item = items[index];
                          final isPart = item.itemType == 'spare_part';

                          return ListTile(
                            leading: Icon(
                              isPart ? Icons.memory_rounded : Icons.handyman_rounded,
                              color: isPart ? AppColors.primary : AppColors.accent,
                            ),
                            title: Text(item.description, style: const TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: Text('الكمية: ${item.quantity} × ${item.unitPrice.toStringAsFixed(0)} ${record.currency.symbol}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${item.totalPrice.toStringAsFixed(0)} ${record.currency.symbol}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded, size: 20, color: AppColors.error),
                                  onPressed: () => _deleteItem(item.id!),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),

              const SizedBox(height: 20),

              // 5. بطاقة الحساب المالي المباشر
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceDark,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderDark),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('إجمالي قطع الغيار:'),
                        Text('${record.partsCost.toStringAsFixed(0)} ${record.currency.symbol}'),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('أجور الصيانة واليد:'),
                        Text('${record.laborCost.toStringAsFixed(0)} ${record.currency.symbol}'),
                      ],
                    ),
                    const Divider(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('الإجمالي العام المستحق:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text(
                          '${record.totalAmount.toStringAsFixed(0)} ${record.currency.symbol}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.primary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('المدفوع (عربونات ودفعات):'),
                        Text(
                          '${record.paidAmount.toStringAsFixed(0)} ${record.currency.symbol}',
                          style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.statusReady),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('المتبقي للتحصيل:', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(
                          '${record.remainingAmount.toStringAsFixed(0)} ${record.currency.symbol}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: record.remainingAmount > 0 ? AppColors.error : AppColors.statusReady,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 6. سجل سندات القبض والدفعات
              if (payments.isNotEmpty) ...[
                const Text('سجل الدفعات وسندات القبض المسجلة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 10),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: payments.length,
                  itemBuilder: (context, index) {
                    final pay = payments[index];
                    return Card(
                      color: AppColors.surfaceDark,
                      child: ListTile(
                        leading: const Icon(Icons.receipt_long_rounded, color: AppColors.primary),
                        title: Text('سند: ${pay.receiptNumber} (${pay.paymentMethod.label})'),
                        subtitle: Text('التاريخ: ${pay.paidAt.toString().substring(0, 16)}'),
                        trailing: Text(
                          '${pay.amount.toStringAsFixed(0)} ${pay.currency.symbol}',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.statusReady, fontSize: 15),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
