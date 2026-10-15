import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/repositories/customer_repository_impl.dart';
import '../../../../domain/entities/customer_entity.dart';

class CustomerFormDialog extends StatefulWidget {
  final CustomerEntity? customerToEdit;
  final String? initialPhone;
  final Function(CustomerEntity savedCustomer) onSaved;

  const CustomerFormDialog({
    super.key,
    this.customerToEdit,
    this.initialPhone,
    required this.onSaved,
  });

  static Future<CustomerEntity?> show({
    required BuildContext context,
    CustomerEntity? customerToEdit,
    String? initialPhone,
    required Function(CustomerEntity savedCustomer) onSaved,
  }) async {
    return await showDialog<CustomerEntity>(
      context: context,
      barrierDismissible: false,
      builder: (context) => CustomerFormDialog(
        customerToEdit: customerToEdit,
        initialPhone: initialPhone,
        onSaved: onSaved,
      ),
    );
  }

  @override
  State<CustomerFormDialog> createState() => _CustomerFormDialogState();
}

class _CustomerFormDialogState extends State<CustomerFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final CustomerRepositoryImpl _customerRepo = CustomerRepositoryImpl();

  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _altPhoneController;
  late final TextEditingController _notesController;
  String _customerType = 'individual';
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final c = widget.customerToEdit;
    _nameController = TextEditingController(text: c?.name ?? '');
    _phoneController = TextEditingController(text: c?.phone ?? widget.initialPhone ?? '');
    _altPhoneController = TextEditingController(text: c?.alternatePhone ?? '');
    _notesController = TextEditingController(text: c?.notes ?? '');
    _customerType = c?.customerType ?? 'individual';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _altPhoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveCustomer() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    final now = DateTime.now();
    final phone = _phoneController.text.trim();

    try {
      // التحقق من تكرار رقم الهاتف لعميل آخر
      final existing = await _customerRepo.getCustomerByPhone(phone);
      if (existing != null && existing.id != widget.customerToEdit?.id) {
        setState(() {
          _errorMessage = 'رقم الهاتف مسجل بالفعل للعميل: ${existing.name}';
          _isSaving = false;
        });
        return;
      }

      final customer = CustomerEntity(
        id: widget.customerToEdit?.id,
        name: _nameController.text.trim(),
        phone: phone,
        alternatePhone: _altPhoneController.text.trim().isEmpty ? null : _altPhoneController.text.trim(),
        customerType: _customerType,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        createdAt: widget.customerToEdit?.createdAt ?? now,
        updatedAt: now,
      );

      if (widget.customerToEdit == null) {
        final id = await _customerRepo.createCustomer(customer);
        final saved = CustomerEntity(
          id: id,
          name: customer.name,
          phone: customer.phone,
          alternatePhone: customer.alternatePhone,
          customerType: customer.customerType,
          notes: customer.notes,
          createdAt: customer.createdAt,
          updatedAt: customer.updatedAt,
        );
        widget.onSaved(saved);
        if (mounted) Navigator.of(context).pop(saved);
      } else {
        await _customerRepo.updateCustomer(customer);
        widget.onSaved(customer);
        if (mounted) Navigator.of(context).pop(customer);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'تعذر حفظ بيانات العميل: $e';
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.customerToEdit != null;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Dialog(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.borderDark),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          isEdit ? Icons.edit_note_rounded : Icons.person_add_rounded,
                          color: AppColors.primary,
                          size: 24,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          isEdit ? 'تعديل بيانات العميل' : 'تسجيل عميل جديد',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimaryDark),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: AppColors.textSecondaryDark),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                    const Divider(height: 24),

                    if (_errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(10),
                        margin: const EdgeInsets.only(bottom: 14),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.error),
                        ),
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: AppColors.error, fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],

                    // نوع العميل
                    const Text('نوع العميل أو الجهة:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondaryDark)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      children: [
                        _buildTypeChip('individual', 'فرد / شخص', Icons.person_rounded),
                        _buildTypeChip('car_workshop', 'ورشة أو مهندس سيارات', Icons.directions_car_rounded),
                        _buildTypeChip('medical_center', 'مستشفى أو عيادة طبية', Icons.medical_services_rounded),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // الاسم
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'اسم العميل / الجهة *',
                        prefixIcon: Icon(Icons.badge_rounded, color: AppColors.primary),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'يرجى إدخال اسم العميل';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    // الهاتف الأساسي
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'رقم الهاتف الأساسي *',
                        prefixIcon: Icon(Icons.phone_rounded, color: AppColors.primary),
                        hintText: '777xxxxxx',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'يرجى إدخال رقم الهاتف';
                        }
                        if (value.trim().length < 6) {
                          return 'رقم الهاتف غير صالح';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    // الهاتف البديل
                    TextFormField(
                      controller: _altPhoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'هاتف بديل أو رقم واتساب (اختياري)',
                        prefixIcon: Icon(Icons.phone_forwarded_rounded, color: AppColors.textSecondaryDark),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // ملاحظات
                    TextFormField(
                      controller: _notesController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'ملاحظات عن العميل أو الحساب (اختياري)',
                        prefixIcon: Icon(Icons.notes_rounded, color: AppColors.textSecondaryDark),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // أزرار الحفظ والإلغاء
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isSaving ? null : _saveCustomer,
                            icon: _isSaving
                                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Icon(Icons.check_circle_rounded),
                            label: Text(_isSaving ? 'جاري الحفظ...' : 'حفظ بيانات العميل'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('إلغاء'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTypeChip(String type, String label, IconData icon) {
    final isSelected = _customerType == type;
    return ChoiceChip(
      selected: isSelected,
      onSelected: (selected) {
        if (selected) setState(() => _customerType = type);
      },
      avatar: Icon(icon, size: 16, color: isSelected ? AppColors.bgDark : AppColors.primary),
      label: Text(label),
      selectedColor: AppColors.primary,
      backgroundColor: AppColors.surfaceDarkElevated,
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected ? AppColors.bgDark : AppColors.textPrimaryDark,
      ),
      side: BorderSide(color: isSelected ? AppColors.primary : AppColors.borderDark),
    );
  }
}
