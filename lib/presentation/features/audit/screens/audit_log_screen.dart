import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/repositories/audit_repository_impl.dart';

class AuditLogScreen extends StatefulWidget {
  const AuditLogScreen({super.key});

  @override
  State<AuditLogScreen> createState() => _AuditLogScreenState();
}

class _AuditLogScreenState extends State<AuditLogScreen> {
  final AuditRepositoryImpl _auditRepo = AuditRepositoryImpl();
  List<Map<String, dynamic>> _logs = [];
  bool _isLoading = true;
  String _selectedCategory = 'all';

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    setState(() => _isLoading = true);
    try {
      final list = await _auditRepo.getAuditLogs(limit: 150);
      setState(() {
        _logs = list;
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _filteredLogs {
    if (_selectedCategory == 'all') return _logs;
    return _logs.where((log) {
      final action = (log['action'] as String? ?? '').toLowerCase();
      if (_selectedCategory == 'backup') return action.startsWith('backup_');
      if (_selectedCategory == 'repairs') return action.contains('repair') || action.contains('intake');
      if (_selectedCategory == 'finance') return action.contains('payment') || action.contains('discount');
      if (_selectedCategory == 'inventory') return action.contains('part') || action.contains('stock');
      return true;
    }).toList();
  }

  String _formatActionTitle(String action) {
    switch (action) {
      case 'repair_intake':
        return 'استلام جهاز جديد وصيانة';
      case 'repair_status_update':
        return 'تحديث حالة الصيانة';
      case 'repair_item_add':
        return 'إضافة بند صيانة / قطعة';
      case 'discount_applied':
        return 'تطبيق خصم مالي (بإذن PIN)';
      case 'payment_recorded':
        return 'سداد دفعة مالية';
      case 'backup_create':
        return 'إنشاء نسخة احتياطية';
      case 'backup_restore':
        return 'استعادة قاعدة البيانات';
      case 'backup_delete':
        return 'حذف نسخة احتياطية';
      default:
        return action;
    }
  }

  IconData _getActionIcon(String action) {
    if (action.startsWith('backup_')) return Icons.backup_rounded;
    if (action.contains('discount')) return Icons.discount_rounded;
    if (action.contains('payment')) return Icons.payments_rounded;
    if (action.contains('part') || action.contains('stock')) return Icons.inventory_2_rounded;
    if (action.contains('repair') || action.contains('intake')) return Icons.build_circle_rounded;
    return Icons.security_rounded;
  }

  Color _getActionColor(String action) {
    if (action.contains('restore') || action.contains('delete')) return AppColors.statusPending;
    if (action.contains('discount')) return AppColors.accent;
    if (action.contains('payment') || action.contains('create')) return AppColors.statusReady;
    if (action.contains('part')) return AppColors.primary;
    return AppColors.statusInProgress;
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredLogs;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('سجل الرقابة والتدقيق (Audit Log)'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'تحديث السجل',
              onPressed: _loadLogs,
            ),
          ],
        ),
        body: Column(
          children: [
            // شرائح تصفية التصنيف
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('all', 'كافة العمليات', Icons.list_alt_rounded),
                    const SizedBox(width: 8),
                    _buildFilterChip('repairs', 'الصيانة والاستلام', Icons.build_circle_rounded),
                    const SizedBox(width: 8),
                    _buildFilterChip('finance', 'المالية والخصومات', Icons.payments_rounded),
                    const SizedBox(width: 8),
                    _buildFilterChip('inventory', 'المخزون والقطع', Icons.inventory_2_rounded),
                    const SizedBox(width: 8),
                    _buildFilterChip('backup', 'النسخ الاحتياطي', Icons.backup_rounded),
                  ],
                ),
              ),
            ),

            // قائمة السجلات الرقابية
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : filtered.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.policy_rounded, size: 64, color: AppColors.textSecondaryDark.withValues(alpha: 0.4)),
                              const SizedBox(height: 12),
                              const Text('لا توجد سجلات رقابية مسجلة في هذا التصنيف', style: TextStyle(color: AppColors.textSecondaryDark)),
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(12),
                          itemCount: filtered.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final log = filtered[index];
                            final action = (log['action'] as String?) ?? 'unknown';
                            final entityName = (log['entityName'] as String?) ?? '';
                            final entityId = log['entityId']?.toString() ?? '';
                            final details = (log['details'] as String?) ?? '';
                            final createdAt = (log['createdAt'] as String?) ?? '';
                            final userId = log['userId']?.toString() ?? 'نظام';
                            final color = _getActionColor(action);

                            return Card(
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 18,
                                          backgroundColor: color.withValues(alpha: 0.15),
                                          child: Icon(_getActionIcon(action), color: color, size: 20),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                _formatActionTitle(action),
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                '$entityName ${entityId.isNotEmpty ? '#$entityId' : ''} • المستخدم: $userId',
                                                style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryDark),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Text(
                                          createdAt.length >= 16 ? createdAt.substring(0, 16).replaceAll('T', ' ') : createdAt,
                                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryDark),
                                        ),
                                      ],
                                    ),
                                    if (details.isNotEmpty) ...[
                                      const SizedBox(height: 10),
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: AppColors.surfaceDarkElevated,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          details,
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ),
                                    ],
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

  Widget _buildFilterChip(String categoryKey, String label, IconData icon) {
    final isSelected = _selectedCategory == categoryKey;
    return ChoiceChip(
      selected: isSelected,
      avatar: Icon(icon, size: 16, color: isSelected ? Colors.white : AppColors.primary),
      label: Text(label),
      onSelected: (val) {
        if (val) {
          setState(() => _selectedCategory = categoryKey);
        }
      },
    );
  }
}
