import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/repositories/spare_part_repository_impl.dart';
import '../../../../domain/entities/spare_part_entity.dart';
import 'spare_part_form_dialog.dart';

class SparePartsListScreen extends StatefulWidget {
  const SparePartsListScreen({super.key});

  @override
  State<SparePartsListScreen> createState() => _SparePartsListScreenState();
}

class _SparePartsListScreenState extends State<SparePartsListScreen> {
  final _repository = SparePartRepositoryImpl();
  final _searchController = TextEditingController();

  List<SparePartEntity> _parts = [];
  bool _isLoading = true;
  String _selectedCategory = 'all';
  bool _onlyLowStock = false;

  final List<Map<String, String>> _categories = const [
    {'id': 'all', 'name': 'جميع القطع'},
    {'id': 'integrated_circuit', 'name': 'دوائر متكاملة (ICs)'},
    {'id': 'power_semiconductor', 'name': 'ترانزستورات وقدرة'},
    {'id': 'capacitors_passives', 'name': 'مكثفات ومكونات سلبية'},
    {'id': 'car_screen_lcd', 'name': 'شاشات سيارات'},
    {'id': 'power_supply_inverter', 'name': 'محولات وإنفرتر'},
    {'id': 'medical_components', 'name': 'أجهزة طبية'},
    {'id': 'audio_mixer_parts', 'name': 'صوتيات ومكسرات'},
    {'id': 'general', 'name': 'قطع عامة'},
  ];

  @override
  void initState() {
    super.initState();
    _loadParts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadParts() async {
    setState(() => _isLoading = true);
    try {
      List<SparePartEntity> result;
      final query = _searchController.text.trim();

      if (_onlyLowStock) {
        result = await _repository.getLowStockParts();
        if (query.isNotEmpty) {
          result = result.where((p) =>
            p.name.toLowerCase().contains(query.toLowerCase()) ||
            (p.partCode?.toLowerCase().contains(query.toLowerCase()) ?? false)
          ).toList();
        }
        if (_selectedCategory != 'all') {
          result = result.where((p) => p.category == _selectedCategory).toList();
        }
      } else if (query.isNotEmpty || _selectedCategory != 'all') {
        result = await _repository.searchSpareParts(
          query,
          category: _selectedCategory == 'all' ? null : _selectedCategory,
        );
      } else {
        result = await _repository.getAllSpareParts();
      }

      setState(() {
        _parts = result;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ أثناء تحميل المستودع: $e')),
        );
      }
    }
  }

  Future<void> _addNewPart() async {
    final newPart = await SparePartFormDialog.show(context);
    if (newPart != null) {
      await _repository.insertSparePart(newPart);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تمت إضافة القطعة بنجاح إلى المستودع')),
        );
      }
      _loadParts();
    }
  }

  Future<void> _editPart(SparePartEntity part) async {
    final updatedPart = await SparePartFormDialog.show(context, initialPart: part);
    if (updatedPart != null) {
      await _repository.updateSparePart(updatedPart);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تحديث بيانات القطعة بنجاح')),
        );
      }
      _loadParts();
    }
  }

  Future<void> _deletePart(SparePartEntity part) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('تأكيد حذف القطعة'),
          content: Text('هل أنت متأكد من حذف "${part.name}" من المستودع؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('حذف نهائي'),
            ),
          ],
        ),
      ),
    );

    if (confirm == true && part.id != null) {
      await _repository.deleteSparePart(part.id!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حذف القطعة من المستودع')),
        );
      }
      _loadParts();
    }
  }

  Future<void> _quickStockAdjust(SparePartEntity part, int delta) async {
    if (part.id == null) return;
    if (part.stockQuantity + delta < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا يمكن إنقاص المخزون لأقل من الصفر')),
      );
      return;
    }

    final success = await _repository.adjustStock(part.id!, delta);
    if (success) {
      _loadParts();
      if (mounted) {
        final actionText = delta > 0 ? 'إضافة $delta' : 'استهلاك ${delta.abs()}';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم $actionText من "${part.name}"'),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    }
  }

  String _getCategoryName(String id) {
    final match = _categories.firstWhere((c) => c['id'] == id, orElse: () => {'name': id});
    return match['name'] ?? id;
  }

  @override
  Widget build(BuildContext context) {
    final lowStockCount = _parts.where((p) => p.isLowStock).length;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('مستودع المكونات وقطع الغيار'),
          actions: [
            IconButton(
              tooltip: 'تحديث القائمة',
              icon: const Icon(Icons.refresh_rounded),
              onPressed: _loadParts,
            ),
            const SizedBox(width: 8),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _addNewPart,
          icon: const Icon(Icons.add_rounded),
          label: const Text('إضافة قطعة'),
        ),
        body: Column(
          children: [
            // شريط البحث والفلترة السريعة
            Container(
              padding: const EdgeInsets.all(12),
              color: AppColors.surfaceDark,
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'ابحث باسم القطعة أو الباركود...',
                            prefixIcon: const Icon(Icons.search_rounded),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear_rounded),
                                    onPressed: () {
                                      _searchController.clear();
                                      _loadParts();
                                    },
                                  )
                                : null,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          ),
                          onChanged: (val) => _loadParts(),
                        ),
                      ),
                      const SizedBox(width: 10),
                      FilterChip(
                        selected: _onlyLowStock,
                        avatar: Icon(
                          Icons.warning_amber_rounded,
                          size: 18,
                          color: _onlyLowStock ? AppColors.bgDark : AppColors.error,
                        ),
                        label: Text(
                          'نواقص المخزون ($lowStockCount)',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _onlyLowStock ? AppColors.bgDark : AppColors.error,
                          ),
                        ),
                        selectedColor: AppColors.error,
                        onSelected: (selected) {
                          setState(() => _onlyLowStock = selected);
                          _loadParts();
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // تصنيفات أفقية سريعة
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _categories.map((c) {
                        final isSelected = _selectedCategory == c['id'];
                        return Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: ChoiceChip(
                            label: Text(c['name']!),
                            selected: isSelected,
                            onSelected: (selected) {
                              if (selected) {
                                setState(() => _selectedCategory = c['id']!);
                                _loadParts();
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

            // قائمة القطع
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _parts.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.inventory_2_outlined, size: 64, color: AppColors.textSecondaryDark.withValues(alpha: 0.5)),
                              const SizedBox(height: 12),
                              const Text(
                                'لا توجد قطع مطابقة للبحث أو التصنيف',
                                style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 15),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: _addNewPart,
                                icon: const Icon(Icons.add_rounded),
                                label: const Text('إضافة قطعة جديدة الآن'),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(12),
                          itemCount: _parts.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final part = _parts[index];
                            final isLow = part.isLowStock;

                            return Container(
                              decoration: BoxDecoration(
                                color: AppColors.surfaceDark,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isLow ? AppColors.error.withValues(alpha: 0.6) : AppColors.borderDark,
                                  width: isLow ? 1.5 : 1.0,
                                ),
                              ),
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  // أيقونة الفئة
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: isLow
                                          ? AppColors.error.withValues(alpha: 0.15)
                                          : AppColors.primary.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      isLow ? Icons.warning_amber_rounded : Icons.memory_rounded,
                                      color: isLow ? AppColors.error : AppColors.primary,
                                      size: 26,
                                    ),
                                  ),
                                  const SizedBox(width: 12),

                                  // بيانات القطعة
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                part.name,
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            if (part.partCode != null && part.partCode!.isNotEmpty)
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: AppColors.bgDark,
                                                  borderRadius: BorderRadius.circular(4),
                                                  border: Border.all(color: AppColors.borderDark),
                                                ),
                                                child: Text(
                                                  part.partCode!,
                                                  style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Text(
                                              _getCategoryName(part.category),
                                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryDark),
                                            ),
                                            const SizedBox(width: 8),
                                            const Text('•', style: TextStyle(color: AppColors.textSecondaryDark)),
                                            const SizedBox(width: 8),
                                            Text(
                                              'سعر البيع: ${part.sellingPrice.toStringAsFixed(0)} ${part.currency.symbol}',
                                              style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.accent,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),

                                  // عداد المخزون وإجراءات الضبط السريع (+ / -)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: isLow
                                          ? AppColors.error.withValues(alpha: 0.1)
                                          : AppColors.statusReady.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: isLow ? AppColors.error : AppColors.statusReady,
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        Text(
                                          'المتوفر: ${part.stockQuantity}',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: isLow ? AppColors.error : AppColors.statusReady,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            InkWell(
                                              borderRadius: BorderRadius.circular(4),
                                              onTap: () => _quickStockAdjust(part, -1),
                                              child: Container(
                                                padding: const EdgeInsets.all(2),
                                                decoration: BoxDecoration(
                                                  color: AppColors.bgDark,
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: const Icon(Icons.remove_rounded, size: 16),
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            InkWell(
                                              borderRadius: BorderRadius.circular(4),
                                              onTap: () => _quickStockAdjust(part, 1),
                                              child: Container(
                                                padding: const EdgeInsets.all(2),
                                                decoration: BoxDecoration(
                                                  color: AppColors.bgDark,
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: const Icon(Icons.add_rounded, size: 16),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),

                                  // قائمة الخيارات الإضافية (تعديل / حذف)
                                  PopupMenuButton<String>(
                                    icon: const Icon(Icons.more_vert_rounded),
                                    onSelected: (val) {
                                      if (val == 'edit') {
                                        _editPart(part);
                                      } else if (val == 'delete') {
                                        _deletePart(part);
                                      }
                                    },
                                    itemBuilder: (context) => [
                                      const PopupMenuItem(
                                        value: 'edit',
                                        child: Row(
                                          children: [
                                            Icon(Icons.edit_rounded, size: 18),
                                            SizedBox(width: 8),
                                            Text('تعديل البيانات'),
                                          ],
                                        ),
                                      ),
                                      const PopupMenuItem(
                                        value: 'delete',
                                        child: Row(
                                          children: [
                                            Icon(Icons.delete_rounded, size: 18, color: AppColors.error),
                                            SizedBox(width: 8),
                                            Text('حذف من المستودع', style: TextStyle(color: AppColors.error)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
