import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/repositories/repair_repository_impl.dart';
import '../../../../domain/enums/repair_status.dart';
import 'repair_details_screen.dart';

class RepairsListScreen extends StatefulWidget {
  final RepairStatus? initialStatus;

  const RepairsListScreen({super.key, this.initialStatus});

  @override
  State<RepairsListScreen> createState() => _RepairsListScreenState();
}

class _RepairsListScreenState extends State<RepairsListScreen> {
  final _repository = RepairRepositoryImpl();
  final _searchController = TextEditingController();

  List<Map<String, dynamic>> _repairs = [];
  bool _isLoading = true;
  RepairStatus? _selectedStatus;

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.initialStatus;
    _loadRepairs();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadRepairs() async {
    setState(() => _isLoading = true);
    try {
      final results = await _repository.searchRepairsWithDetails(
        _searchController.text.trim(),
        status: _selectedStatus,
      );
      setState(() {
        _repairs = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ أثناء تحميل التذاكر: $e')),
        );
      }
    }
  }

  Color _getStatusColor(String code) {
    switch (code) {
      case 'received':
        return AppColors.statusReceived;
      case 'in_progress':
        return AppColors.statusInProgress;
      case 'waiting_for_parts':
        return AppColors.statusWaitingParts;
      case 'ready':
        return AppColors.statusReady;
      case 'delivered':
        return AppColors.textSecondaryDark;
      default:
        return AppColors.accent;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('سجل وتذاكر الصيانة'),
          actions: [
            IconButton(
              tooltip: 'تحديث القائمة',
              icon: const Icon(Icons.refresh_rounded),
              onPressed: _loadRepairs,
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: Column(
          children: [
            // شريط البحث والفلترة
            Container(
              padding: const EdgeInsets.all(12),
              color: AppColors.surfaceDark,
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'ابحث برقم السند، اسم العميل، الهاتف، أو موديل الجهاز...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded),
                              onPressed: () {
                                _searchController.clear();
                                _loadRepairs();
                              },
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                    onChanged: (val) => _loadRepairs(),
                  ),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: ChoiceChip(
                            label: const Text('جميع الحالات'),
                            selected: _selectedStatus == null,
                            onSelected: (selected) {
                              if (selected) {
                                setState(() => _selectedStatus = null);
                                _loadRepairs();
                              }
                            },
                          ),
                        ),
                        ...RepairStatus.values.map((s) {
                          final isSelected = _selectedStatus == s;
                          return Padding(
                            padding: const EdgeInsets.only(left: 6),
                            child: ChoiceChip(
                              label: Text(s.label),
                              selected: isSelected,
                              onSelected: (selected) {
                                setState(() => _selectedStatus = selected ? s : null);
                                _loadRepairs();
                              },
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // قائمة التذاكر
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _repairs.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.inbox_outlined, size: 64, color: AppColors.textSecondaryDark.withValues(alpha: 0.5)),
                              const SizedBox(height: 12),
                              const Text(
                                'لا توجد تذاكر صيانة مطابقة للبحث',
                                style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 15),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(12),
                          itemCount: _repairs.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final r = _repairs[index];
                            final status = RepairStatus.fromCode(r['status'] as String);
                            final remaining = (r['remainingAmount'] as num).toDouble();
                            final currency = r['currency'] as String? ?? 'YER';

                            return InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () async {
                                await Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => RepairDetailsScreen(repairId: r['id'] as int),
                                  ),
                                );
                                _loadRepairs();
                              },
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
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: AppColors.primary.withValues(alpha: 0.15),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                r['recordNumber'] as String,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontFamily: 'monospace',
                                                  color: AppColors.primary,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              r['receivedAt']?.toString().substring(0, 10) ?? '',
                                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryDark),
                                            ),
                                          ],
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: _getStatusColor(status.code).withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(color: _getStatusColor(status.code)),
                                          ),
                                          child: Text(
                                            status.label,
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: _getStatusColor(status.code),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Row(
                                      children: [
                                        const Icon(Icons.devices_other_rounded, size: 18, color: AppColors.primary),
                                        const SizedBox(width: 6),
                                        Text(
                                          '${r['deviceBrand']} ${r['deviceModel']}',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(Icons.person_outline_rounded, size: 16, color: AppColors.textSecondaryDark),
                                        const SizedBox(width: 6),
                                        Text(
                                          '${r['customerName']} (${r['customerPhone']})',
                                          style: const TextStyle(fontSize: 13, color: AppColors.textSecondaryDark),
                                        ),
                                      ],
                                    ),
                                    const Divider(height: 16),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'العطل: ${r['problemDescription']}',
                                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryDark),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          remaining > 0
                                              ? 'متبقي: ${remaining.toStringAsFixed(0)} $currency'
                                              : 'خالص الحساب',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: remaining > 0 ? AppColors.error : AppColors.statusReady,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
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
