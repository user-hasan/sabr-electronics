import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../domain/entities/spare_part_entity.dart';
import '../../../../domain/enums/app_currency.dart';

class SparePartFormDialog extends StatefulWidget {
  final SparePartEntity? initialPart;

  const SparePartFormDialog({super.key, this.initialPart});

  static Future<SparePartEntity?> show(
    BuildContext context, {
    SparePartEntity? initialPart,
  }) {
    return showDialog<SparePartEntity>(
      context: context,
      barrierDismissible: false,
      builder: (context) => SparePartFormDialog(initialPart: initialPart),
    );
  }

  @override
  State<SparePartFormDialog> createState() => _SparePartFormDialogState();
}

class _SparePartFormDialogState extends State<SparePartFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _partCodeController;
  late TextEditingController _costPriceController;
  late TextEditingController _sellingPriceController;
  late TextEditingController _stockController;
  late TextEditingController _minAlertController;

  late String _category;
  late AppCurrency _currency;

  final List<Map<String, String>> _categories = const [
    {'id': 'integrated_circuit', 'name': 'دوائر متكاملة ومعالجات (ICs)'},
    {'id': 'power_semiconductor', 'name': 'ترانزستورات وموسفيت وقدرة'},
    {'id': 'capacitors_passives', 'name': 'مكثفات ومكونات سلبية'},
    {'id': 'car_screen_lcd', 'name': 'شاشات ولمس شاشات سيارات'},
    {'id': 'power_supply_inverter', 'name': 'محولات ودوائر تغذية وإنفرتر'},
    {'id': 'medical_components', 'name': 'حساسات وقطع أجهزة طبية'},
    {'id': 'audio_mixer_parts', 'name': 'فلاتر ومفاتيح صوت ومكسرات'},
    {'id': 'general', 'name': 'قطع ومكونات عامة'},
  ];

  @override
  void initState() {
    super.initState();
    final p = widget.initialPart;
    _nameController = TextEditingController(text: p?.name ?? '');
    _partCodeController = TextEditingController(text: p?.partCode ?? '');
    _costPriceController = TextEditingController(text: p != null ? p.costPrice.toStringAsFixed(0) : '0');
    _sellingPriceController = TextEditingController(text: p != null ? p.sellingPrice.toStringAsFixed(0) : '0');
    _stockController = TextEditingController(text: p != null ? p.stockQuantity.toString() : '5');
    _minAlertController = TextEditingController(text: p != null ? p.minStockAlert.toString() : '2');
    _category = p?.category ?? 'integrated_circuit';
    _currency = p?.currency ?? AppCurrency.yer;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _partCodeController.dispose();
    _costPriceController.dispose();
    _sellingPriceController.dispose();
    _stockController.dispose();
    _minAlertController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final now = DateTime.now();
    final part = SparePartEntity(
      id: widget.initialPart?.id,
      name: _nameController.text.trim(),
      partCode: _partCodeController.text.trim().isEmpty ? null : _partCodeController.text.trim(),
      category: _category,
      costPrice: double.tryParse(_costPriceController.text.trim()) ?? 0.0,
      sellingPrice: double.tryParse(_sellingPriceController.text.trim()) ?? 0.0,
      currency: _currency,
      stockQuantity: int.tryParse(_stockController.text.trim()) ?? 0,
      minStockAlert: int.tryParse(_minAlertController.text.trim()) ?? 2,
      createdAt: widget.initialPart?.createdAt ?? now,
      updatedAt: now,
    );

    Navigator.of(context).pop(part);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initialPart != null;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        title: Row(
          children: [
            Icon(
              isEditing ? Icons.edit_rounded : Icons.add_circle_outline_rounded,
              color: AppColors.primary,
            ),
            const SizedBox(width: 8),
            Text(
              isEditing ? 'تعديل بيانات القطعة' : 'إضافة قطعة إلكترونية جديدة',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: SizedBox(
          width: 520,
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'اسم القطعة أو المكون *',
                      hintText: 'مثال: TDA7294, Mosfet IRFP260N, شاشة 9 بوصة IPS',
                      prefixIcon: Icon(Icons.memory_rounded),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'يرجى إدخال اسم القطعة';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _partCodeController,
                          decoration: const InputDecoration(
                            labelText: 'الرقم المرجعي / الباركود',
                            hintText: 'مثال: IC-7294-01',
                            prefixIcon: Icon(Icons.qr_code_rounded),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _category,
                          decoration: const InputDecoration(
                            labelText: 'تصنيف القطعة *',
                            prefixIcon: Icon(Icons.category_rounded),
                          ),
                          items: _categories.map((c) {
                            return DropdownMenuItem(
                              value: c['id'],
                              child: Text(
                                c['name']!,
                                style: const TextStyle(fontSize: 13),
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: (v) {
                            if (v != null) setState(() => _category = v);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<AppCurrency>(
                          initialValue: _currency,
                          decoration: const InputDecoration(
                            labelText: 'عملة التسعير *',
                            prefixIcon: Icon(Icons.payments_rounded),
                          ),
                          items: AppCurrency.values.map((c) {
                            return DropdownMenuItem(
                              value: c,
                              child: Text('${c.label} (${c.symbol})'),
                            );
                          }).toList(),
                          onChanged: (v) {
                            if (v != null) setState(() => _currency = v);
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _costPriceController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'سعر التكلفة',
                            prefixIcon: const Icon(Icons.price_change_outlined),
                            suffixText: _currency.symbol,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _sellingPriceController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'سعر البيع للعميل *',
                            prefixIcon: const Icon(Icons.sell_rounded),
                            suffixText: _currency.symbol,
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'مطلوب';
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _stockController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'الكمية المتوفرة بالمخزن *',
                            prefixIcon: Icon(Icons.inventory_2_rounded),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'مطلوب';
                            final parsed = int.tryParse(v.trim());
                            if (parsed == null || parsed < 0) return 'قيمة غير صالحة';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _minAlertController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'حد التنبيه بالنقص *',
                            prefixIcon: Icon(Icons.warning_amber_rounded),
                            helperText: 'يظهر تنبيه أحمر عند الوصول لهذا الحد',
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'مطلوب';
                            final parsed = int.tryParse(v.trim());
                            if (parsed == null || parsed < 0) return 'قيمة غير صالحة';
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إلغاء'),
          ),
          ElevatedButton.icon(
            onPressed: _submit,
            icon: Icon(isEditing ? Icons.check_rounded : Icons.save_rounded),
            label: Text(isEditing ? 'حفظ التعديلات' : 'إضافة للمستودع'),
          ),
        ],
      ),
    );
  }
}
