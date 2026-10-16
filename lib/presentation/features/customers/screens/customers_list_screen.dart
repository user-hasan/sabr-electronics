import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/repositories/customer_repository_impl.dart';
import '../../../../domain/entities/customer_entity.dart';
import '../../devices/screens/intake_wizard_screen.dart';
import 'customer_form_dialog.dart';

class CustomersListScreen extends StatefulWidget {
  const CustomersListScreen({super.key});

  @override
  State<CustomersListScreen> createState() => _CustomersListScreenState();
}

class _CustomersListScreenState extends State<CustomersListScreen> {
  final CustomerRepositoryImpl _customerRepo = CustomerRepositoryImpl();
  final TextEditingController _searchController = TextEditingController();

  List<CustomerEntity> _customers = [];
  bool _isLoading = true;
  String _selectedType = 'all';

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCustomers() async {
    setState(() => _isLoading = true);
    try {
      final query = _searchController.text.trim();
      List<CustomerEntity> list;
      if (query.isNotEmpty) {
        list = await _customerRepo.searchCustomers(query);
      } else {
        list = await _customerRepo.getAllCustomers(limit: 100);
      }

      if (_selectedType != 'all') {
        list = list.where((c) => c.customerType == _selectedType).toList();
      }

      setState(() {
        _customers = list;
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  String _getCustomerTypeLabel(String type) {
    switch (type) {
      case 'car_workshop':
        return 'ورشة سيارات';
      case 'medical_center':
        return 'مركز طبي / مختبر';
      case 'individual':
      default:
        return 'فردي';
    }
  }

  IconData _getCustomerTypeIcon(String type) {
    switch (type) {
      case 'car_workshop':
        return Icons.directions_car_rounded;
      case 'medical_center':
        return Icons.medical_services_rounded;
      case 'individual':
      default:
        return Icons.person_rounded;
    }
  }

  void _showCustomerDetailsModal(CustomerEntity customer) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border.all(color: AppColors.borderDark),
            ),
            child: FutureBuilder<Map<String, dynamic>>(
              future: _customerRepo.getCustomerStats(customer.id!),
              builder: (context, snapshot) {
                final stats = snapshot.data ?? {'deviceCount': 0, 'repairCount': 0, 'debt': 0.0};
                final isStatsLoading = snapshot.connectionState == ConnectionState.waiting;

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: AppColors.textSecondaryDark.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 26,
                          backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                          child: Icon(
                            _getCustomerTypeIcon(customer.customerType),
                            color: AppColors.primary,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                customer.name,
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${_getCustomerTypeLabel(customer.customerType)} • ${customer.phone}',
                                style: const TextStyle(fontSize: 13, color: AppColors.textSecondaryDark),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (customer.alternatePhone != null && customer.alternatePhone!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          'هاتف إضافي: ${customer.alternatePhone}',
                          style: const TextStyle(fontSize: 13, color: AppColors.textSecondaryDark),
                        ),
                      ),
                    if (customer.notes != null && customer.notes!.isNotEmpty)
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceDarkElevated,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'ملاحظات: ${customer.notes}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),

                    // إحصائيات سريعة للعميل
                    const Text('السجل الفني والمالي للعميل', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    if (isStatsLoading)
                      const Center(child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator()))
                    else
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatBadge('الأجهزة', '${stats['deviceCount']}', Icons.devices_other_rounded, AppColors.primary),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildStatBadge('عمليات الصيانة', '${stats['repairCount']}', Icons.build_circle_rounded, AppColors.statusInProgress),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildStatBadge(
                              'المديونية',
                              '${(stats['debt'] as num).toStringAsFixed(0)} ر.ي',
                              Icons.money_off_csred_rounded,
                              (stats['debt'] as num) > 0 ? AppColors.statusPending : AppColors.statusReady,
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 20),

                    // أزرار العمليات الميدانية
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.add_task_rounded),
                            label: const Text('استلام جهاز'),
                            onPressed: () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const IntakeWizardScreen()),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.edit_rounded),
                            label: const Text('تعديل البيانات'),
                            onPressed: () {
                              Navigator.pop(context);
                              CustomerFormDialog.show(
                                context: context,
                                customerToEdit: customer,
                                onSaved: (_) => _loadCustomers(),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: TextButton.icon(
                        style: TextButton.styleFrom(foregroundColor: AppColors.statusPending),
                        icon: const Icon(Icons.delete_outline_rounded, size: 18),
                        label: const Text('حذف هذا العميل'),
                        onPressed: () async {
                          Navigator.pop(context);
                          _confirmDeleteCustomer(customer);
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatBadge(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
          Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondaryDark)),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteCustomer(CustomerEntity customer) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('تأكيد حذف العميل'),
          content: Text('هل أنت متأكد من حذف العميل "${customer.name}"؟ لن يمكن التراجع عن هذا الإجراء.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.statusPending),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('حذف العميل'),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true && customer.id != null) {
      try {
        final success = await _customerRepo.deleteCustomer(customer.id!);
        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم حذف العميل بنجاح')),
          );
          _loadCustomers();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppColors.statusPending,
              content: const Text('تعذر حذف العميل لوجود أجهزة أو سجلات صيانة نشطة مرتبطة به.'),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('سجل وإدارة العملاء'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'تحديث القائمة',
              onPressed: _loadCustomers,
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            CustomerFormDialog.show(
              context: context,
              onSaved: (_) => _loadCustomers(),
            );
          },
          icon: const Icon(Icons.person_add_alt_1_rounded),
          label: const Text('عميل جديد'),
        ),
        body: Column(
          children: [
            // شريط البحث الميداني
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                controller: _searchController,
                onChanged: (_) => _loadCustomers(),
                decoration: InputDecoration(
                  hintText: 'البحث بالاسم أو رقم الهاتف...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded),
                          onPressed: () {
                            _searchController.clear();
                            _loadCustomers();
                          },
                        )
                      : null,
                ),
              ),
            ),

            // شرائح تصفية فئة العميل
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  _buildFilterChip('all', 'كافة العملاء', Icons.people_alt_rounded),
                  const SizedBox(width: 8),
                  _buildFilterChip('individual', 'أفراد', Icons.person_rounded),
                  const SizedBox(width: 8),
                  _buildFilterChip('car_workshop', 'ورش سيارات', Icons.directions_car_rounded),
                  const SizedBox(width: 8),
                  _buildFilterChip('medical_center', 'مراكز طبية', Icons.medical_services_rounded),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // قائمة العملاء
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _customers.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.person_search_rounded, size: 64, color: AppColors.textSecondaryDark.withValues(alpha: 0.4)),
                              const SizedBox(height: 12),
                              const Text('لا توجد سجلات مطابقة للبحث', style: TextStyle(color: AppColors.textSecondaryDark)),
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(12),
                          itemCount: _customers.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final customer = _customers[index];
                            return Card(
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                                  child: Icon(
                                    _getCustomerTypeIcon(customer.customerType),
                                    color: AppColors.primary,
                                  ),
                                ),
                                title: Text(customer.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text(
                                  '${_getCustomerTypeLabel(customer.customerType)} • ${customer.phone}',
                                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryDark),
                                ),
                                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                                onTap: () => _showCustomerDetailsModal(customer),
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

  Widget _buildFilterChip(String typeKey, String label, IconData icon) {
    final isSelected = _selectedType == typeKey;
    return ChoiceChip(
      selected: isSelected,
      avatar: Icon(icon, size: 16, color: isSelected ? Colors.white : AppColors.primary),
      label: Text(label),
      onSelected: (val) {
        if (val) {
          setState(() => _selectedType = typeKey);
          _loadCustomers();
        }
      },
    );
  }
}
