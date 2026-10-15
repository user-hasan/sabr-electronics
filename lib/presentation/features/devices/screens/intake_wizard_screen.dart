import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/datasources/local/database_helper.dart';
import '../../../../data/repositories/customer_repository_impl.dart';
import '../../../../domain/entities/customer_entity.dart';
import '../../../../domain/entities/device_entity.dart';
import '../../../../domain/entities/repair_record_entity.dart';
import '../../../../domain/enums/app_currency.dart';
import '../../../../domain/enums/device_category.dart';
import '../../../../domain/enums/payment_method.dart';
import '../../../../domain/enums/repair_status.dart';
import '../../../../services/image_service.dart';
import '../../../../services/printing_service.dart';
import '../../customers/screens/customer_form_dialog.dart';

class IntakeWizardScreen extends StatefulWidget {
  const IntakeWizardScreen({super.key});

  @override
  State<IntakeWizardScreen> createState() => _IntakeWizardScreenState();
}

class _IntakeWizardScreenState extends State<IntakeWizardScreen> {
  final CustomerRepositoryImpl _customerRepo = CustomerRepositoryImpl();
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final ImageService _imageService = ImageService();
  final ImagePicker _picker = ImagePicker();

  int _currentStep = 0;
  bool _isSaving = false;

  // الخطوة 1: العميل
  CustomerEntity? _selectedCustomer;
  final TextEditingController _customerSearchController = TextEditingController();
  List<CustomerEntity> _searchedCustomers = [];

  // الخطوة 2: توصيف الجهاز
  DeviceCategory _selectedCategory = DeviceCategory.carScreen;
  final _deviceTypeController = TextEditingController(text: 'شاشة أندرويد 9 إنش');
  final _brandController = TextEditingController();
  final _modelController = TextEditingController();
  final _serialController = TextEditingController();
  final _carInfoController = TextEditingController();
  final _medicalFacilityController = TextEditingController();
  final _voltageController = TextEditingController(text: '12V DC');
  final _problemController = TextEditingController();

  final List<String> _selectedAccessories = [];
  final List<String> _selectedConditions = [];

  final List<String> _commonAccessories = [
    'فيش التوصيل والكهرباء',
    'ضفيرة أسلاك كاملة',
    'محول طاقة (Adapter)',
    'كابلات الفحص والإشارة',
    'وحدة تحكم / ريموت',
    'قاعدة تثبيت',
  ];

  final List<String> _commonConditions = [
    'سليم ونظيف ظاهرياً',
    'خدوش سطحية بالشاسيه',
    'كسر أو شرخ في الإطار',
    'علامات فتح وتلاعب سابقة',
    'آثار حرق أو التماس ظاهرة',
  ];

  // الخطوة 3: الصور
  final List<File> _capturedImages = [];

  // الخطوة 4: الاتفاق المالي
  AppCurrency _selectedCurrency = AppCurrency.yer;
  final _estimatedCostController = TextEditingController(text: '0');
  final _advancePaidController = TextEditingController(text: '0');
  PaymentMethod _selectedPaymentMethod = PaymentMethod.cash;

  @override
  void initState() {
    super.initState();
    _loadRecentCustomers();
  }

  @override
  void dispose() {
    _customerSearchController.dispose();
    _deviceTypeController.dispose();
    _brandController.dispose();
    _modelController.dispose();
    _serialController.dispose();
    _carInfoController.dispose();
    _medicalFacilityController.dispose();
    _voltageController.dispose();
    _problemController.dispose();
    _estimatedCostController.dispose();
    _advancePaidController.dispose();
    super.dispose();
  }

  Future<void> _loadRecentCustomers() async {
    final list = await _customerRepo.getAllCustomers(limit: 5);
    if (mounted) setState(() => _searchedCustomers = list);
  }

  Future<void> _onSearchCustomer(String query) async {
    if (query.trim().isEmpty) {
      _loadRecentCustomers();
      return;
    }
    final results = await _customerRepo.searchCustomers(query);
    if (mounted) setState(() => _searchedCustomers = results);
  }

  Future<void> _pickImage(ImageSource source) async {
    final picked = await _picker.pickImage(source: source);
    if (picked != null) {
      setState(() => _capturedImages.add(File(picked.path)));
    }
  }

  Future<void> _saveIntakeTicket() async {
    if (_selectedCustomer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى اختيار أو تسجيل العميل أولاً')),
      );
      setState(() => _currentStep = 0);
      return;
    }

    if (_brandController.text.trim().isEmpty || _modelController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى إدخال الشركة الصانعة والموديل للجهاز')),
      );
      setState(() => _currentStep = 1);
      return;
    }

    if (_problemController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى كتابة وصف العطل وشكوى العميل')),
      );
      setState(() => _currentStep = 1);
      return;
    }

    setState(() => _isSaving = true);

    try {
      final now = DateTime.now();
      final db = await _dbHelper.database;
      RepairRecordEntity? createdRecord;

      // تنفيذ الحفظ داخل SQLite Transaction متكاملة
      await db.transaction((txn) async {
        // 1. حفظ الجهاز
        final device = DeviceEntity(
          customerId: _selectedCustomer!.id!,
          category: _selectedCategory,
          deviceType: _deviceTypeController.text.trim(),
          brand: _brandController.text.trim(),
          model: _modelController.text.trim(),
          serialNumber: _serialController.text.trim().isEmpty ? null : _serialController.text.trim(),
          carVehicleInfo: _selectedCategory == DeviceCategory.carScreen ? _carInfoController.text.trim() : null,
          medicalFacility: _selectedCategory == DeviceCategory.medical ? _medicalFacilityController.text.trim() : null,
          operatingVoltage: _voltageController.text.trim(),
          receivedAccessories: _selectedAccessories.join('، '),
          physicalCondition: _selectedConditions.join('، '),
          createdAt: now,
          updatedAt: now,
        );

        final deviceId = await txn.insert('devices', device.toMap());

        // 2. توليد رقم السند المعتمد REC-YYYY-XXXX
        final countRows = await txn.rawQuery('SELECT COUNT(*) as count FROM repair_records');
        final countRes = (countRows.first['count'] as int?) ?? 0;
        final recordNumber = 'REC-${now.year}-${(countRes + 1).toString().padLeft(4, '0')}';

        final estimatedCost = double.tryParse(_estimatedCostController.text.trim()) ?? 0.0;
        final advancePaid = double.tryParse(_advancePaidController.text.trim()) ?? 0.0;
        final remaining = (estimatedCost > advancePaid) ? (estimatedCost - advancePaid) : 0.0;

        // 3. حفظ سجل وتذكرة الصيانة
        final record = RepairRecordEntity(
          recordNumber: recordNumber,
          customerId: _selectedCustomer!.id!,
          deviceId: deviceId,
          receivedAt: now,
          status: RepairStatus.received,
          problemDescription: _problemController.text.trim(),
          currency: _selectedCurrency,
          estimatedCost: estimatedCost,
          totalAmount: estimatedCost,
          paidAmount: advancePaid,
          remainingAmount: remaining,
          createdAt: now,
          updatedAt: now,
        );

        createdRecord = record;

        final recordId = await txn.insert('repair_records', record.toMap());

        // 4. حفظ سند العربون إن وُجد
        if (advancePaid > 0) {
          final receiptNumber = 'PAY-${now.year}-${(countRes + 1).toString().padLeft(4, '0')}';
          await txn.insert('payments', {
            'receiptNumber': receiptNumber,
            'repairRecordId': recordId,
            'customerId': _selectedCustomer!.id!,
            'amount': advancePaid,
            'currency': _selectedCurrency.code,
            'paymentMethod': _selectedPaymentMethod.code,
            'receivedByUserId': 1, // المستخدم الافتراضي
            'paidAt': now.toIso8601String(),
            'notes': 'عربون استلام الجهاز',
          });
        }

        // 5. حفظ وتوثيق الصور محلياً
        for (final imgFile in _capturedImages) {
          try {
            final processed = await _imageService.processAndSaveDeviceImage(
              sourceImageFile: imgFile,
              deviceId: deviceId,
              imageType: 'intake',
            );
            await txn.insert('device_images', {
              'deviceId': deviceId,
              'repairRecordId': recordId,
              'imageType': 'intake',
              'originalPath': processed.originalPath,
              'thumbnailPath': processed.thumbnailPath,
              'createdAt': now.toIso8601String(),
            });
          } catch (_) {}
        }

        // 6. تدوين العملية في سجل الرقابة audit_logs
        await txn.insert('audit_logs', {
          'userId': 1,
          'action': 'INTAKE_DEVICE',
          'entityName': 'repair_records',
          'entityId': recordId.toString(),
          'details': 'استلام جهاز برقم $recordNumber للعميل ${_selectedCustomer!.name}',
          'createdAt': now.toIso8601String(),
        });
      });

      if (mounted && createdRecord != null) {
        setState(() => _isSaving = false);
        final currentContext = context;
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (dialogCtx) => Directionality(
            textDirection: TextDirection.rtl,
            child: AlertDialog(
              title: Row(
                children: const [
                  Icon(Icons.check_circle_rounded, color: AppColors.statusReady, size: 28),
                  SizedBox(width: 8),
                  Text('تم استلام الجهاز بنجاح'),
                ],
              ),
              content: SizedBox(
                width: 440,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'رقم السند: ${createdRecord!.recordNumber}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary),
                    ),
                    const SizedBox(height: 6),
                    Text('العميل: ${_selectedCustomer!.name}'),
                    Text('الجهاز: ${_brandController.text} ${_modelController.text}'),
                    const SizedBox(height: 16),
                    const Text('يمكنك الآن طباعة سند الاستلام أو ملصق الباركود:'),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              PrintingService.instance.printIntakeReceipt(
                                record: createdRecord!,
                                customerName: _selectedCustomer!.name,
                                customerPhone: _selectedCustomer!.phone,
                                deviceBrand: _brandController.text.trim(),
                                deviceModel: _modelController.text.trim(),
                                serialNumber: _serialController.text.trim(),
                                physicalCondition: _selectedConditions.join('، '),
                                accessories: _selectedAccessories.join('، '),
                              );
                            },
                            icon: const Icon(Icons.receipt_rounded),
                            label: const Text('طباعة السند'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              PrintingService.instance.printChassisSticker(
                                recordNumber: createdRecord!.recordNumber,
                                customerName: _selectedCustomer!.name,
                                customerPhone: _selectedCustomer!.phone,
                                deviceName: '${_brandController.text.trim()} ${_modelController.text.trim()}',
                                date: createdRecord!.receivedAt,
                              );
                            },
                            icon: const Icon(Icons.label_rounded),
                            label: const Text('ملصق الباركود'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(dialogCtx).pop();
                    Navigator.of(currentContext).pop(true);
                  },
                  child: const Text('إنهاء والعودة للرئيسية'),
                ),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: AppColors.error, content: Text('فشل حفظ السند: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('معالج استلام جهاز جديد (سند صيانة)'),
        ),
        body: Stepper(
          type: StepperType.horizontal,
          currentStep: _currentStep,
          onStepTapped: (step) => setState(() => _currentStep = step),
          onStepContinue: () {
            if (_currentStep < 3) {
              setState(() => _currentStep += 1);
            } else {
              _saveIntakeTicket();
            }
          },
          onStepCancel: () {
            if (_currentStep > 0) {
              setState(() => _currentStep -= 1);
            } else {
              Navigator.of(context).pop();
            }
          },
          controlsBuilder: (context, details) {
            final isLast = _currentStep == 3;
            return Padding(
              padding: const EdgeInsets.only(top: 24),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isSaving ? null : details.onStepContinue,
                      icon: _isSaving
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : Icon(isLast ? Icons.print_rounded : Icons.arrow_forward_rounded),
                      label: Text(
                        _isSaving
                            ? 'جاري الحفظ...'
                            : (isLast ? 'حفظ وطباعة السند فوراً' : 'الانتقال للخطوة التالية'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  OutlinedButton(
                    onPressed: details.onStepCancel,
                    child: Text(_currentStep == 0 ? 'إلغاء' : 'السابق'),
                  ),
                ],
              ),
            );
          },
          steps: [
            Step(
              title: const Text('العميل'),
              isActive: _currentStep >= 0,
              state: _selectedCustomer != null ? StepState.complete : StepState.indexed,
              content: _buildStepCustomer(),
            ),
            Step(
              title: const Text('الجهاز'),
              isActive: _currentStep >= 1,
              state: _problemController.text.isNotEmpty ? StepState.complete : StepState.indexed,
              content: _buildStepDevice(),
            ),
            Step(
              title: const Text('الصور'),
              isActive: _currentStep >= 2,
              content: _buildStepImages(),
            ),
            Step(
              title: const Text('المالية'),
              isActive: _currentStep >= 3,
              content: _buildStepFinancials(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepCustomer() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_selectedCustomer != null) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedCustomer!.name,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimaryDark),
                      ),
                      Text(
                        'هاتف: ${_selectedCustomer!.phone} — ${_selectedCustomer!.customerType == "individual" ? "فرد" : _selectedCustomer!.customerType}',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryDark),
                      ),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: () => setState(() => _selectedCustomer = null),
                  icon: const Icon(Icons.change_circle_rounded, size: 18),
                  label: const Text('تغيير'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ] else ...[
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _customerSearchController,
                  onChanged: _onSearchCustomer,
                  decoration: const InputDecoration(
                    hintText: 'ابحث برقم الهاتف أو اسم العميل...',
                    prefixIcon: Icon(Icons.search_rounded, color: AppColors.primary),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                onPressed: () {
                  CustomerFormDialog.show(
                    context: context,
                    initialPhone: _customerSearchController.text.trim(),
                    onSaved: (customer) {
                      setState(() {
                        _selectedCustomer = customer;
                        _customerSearchController.clear();
                      });
                    },
                  );
                },
                icon: const Icon(Icons.person_add_rounded),
                label: const Text('عميل جديد'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: AppColors.bgDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          if (_searchedCustomers.isNotEmpty) ...[
            const Text('نتائج البحث السريع:', style: TextStyle(fontSize: 12, color: AppColors.textSecondaryDark)),
            const SizedBox(height: 6),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _searchedCustomers.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final c = _searchedCustomers[index];
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                  leading: CircleAvatar(
                    backgroundColor: AppColors.surfaceDarkElevated,
                    child: const Icon(Icons.person_rounded, color: AppColors.primary, size: 20),
                  ),
                  title: Text(c.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  subtitle: Text(c.phone, style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryDark)),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textSecondaryDark),
                  onTap: () => setState(() => _selectedCustomer = c),
                );
              },
            ),
          ],
        ],
      ],
    );
  }

  Widget _buildStepDevice() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('تصنيف الجهاز التخصصي:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondaryDark)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: DeviceCategory.values.map((cat) {
            final isSelected = _selectedCategory == cat;
            return ChoiceChip(
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _selectedCategory = cat;
                    if (cat == DeviceCategory.medical) {
                      _deviceTypeController.text = 'جهاز مراقبة مرضى / تخطيط';
                      _voltageController.text = '220V AC';
                    } else if (cat == DeviceCategory.carScreen) {
                      _deviceTypeController.text = 'شاشة أندرويد للسيارة';
                      _voltageController.text = '12V DC';
                    } else if (cat == DeviceCategory.amplifier) {
                      _deviceTypeController.text = 'مضخم صوت قدرة';
                    }
                  });
                }
              },
              avatar: Icon(cat.icon, size: 18, color: isSelected ? AppColors.bgDark : AppColors.primary),
              label: Text(cat.label),
              selectedColor: AppColors.primary,
              backgroundColor: AppColors.surfaceDark,
              side: BorderSide(color: isSelected ? AppColors.primary : AppColors.borderDark),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),

        Row(
          children: [
            Expanded(
              flex: 2,
              child: TextFormField(
                controller: _deviceTypeController,
                decoration: const InputDecoration(labelText: 'نوع ووصف الجهاز *'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextFormField(
                controller: _voltageController,
                decoration: const InputDecoration(labelText: 'فولتية التشغيل'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _brandController,
                decoration: const InputDecoration(labelText: 'الشركة الصانعة (Brand) *', hintText: 'Pioneer, Mindray, Sony...'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextFormField(
                controller: _modelController,
                decoration: const InputDecoration(labelText: 'الموديل / رقم البوردة *'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // حقول متخصصة حسب التصنيف
        if (_selectedCategory == DeviceCategory.carScreen) ...[
          TextFormField(
            controller: _carInfoController,
            decoration: const InputDecoration(
              labelText: 'بيانات السيارة (النوع، الموديل، السنة)',
              prefixIcon: Icon(Icons.directions_car_rounded, color: AppColors.primary),
              hintText: 'تويوتا كامري 2020',
            ),
          ),
          const SizedBox(height: 12),
        ],

        if (_selectedCategory == DeviceCategory.medical) ...[
          TextFormField(
            controller: _medicalFacilityController,
            decoration: const InputDecoration(
              labelText: 'اسم العيادة أو المستشفى أو القسم الطبي',
              prefixIcon: Icon(Icons.local_hospital_rounded, color: AppColors.primary),
            ),
          ),
          const SizedBox(height: 12),
        ],

        TextFormField(
          controller: _serialController,
          decoration: const InputDecoration(
            labelText: 'الرقم التسلسلي (Serial Number / Barcode)',
            prefixIcon: Icon(Icons.qr_code_rounded, color: AppColors.textSecondaryDark),
          ),
        ),
        const SizedBox(height: 16),

        // الملحقات المستلمة
        const Text('الملحقات المستلمة مع الجهاز:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondaryDark)),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: _commonAccessories.map((acc) {
            final isSelected = _selectedAccessories.contains(acc);
            return FilterChip(
              selected: isSelected,
              label: Text(acc, style: const TextStyle(fontSize: 12)),
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedAccessories.add(acc);
                  } else {
                    _selectedAccessories.remove(acc);
                  }
                });
              },
              backgroundColor: AppColors.surfaceDark,
              selectedColor: AppColors.accent.withValues(alpha: 0.2),
              checkmarkColor: AppColors.accent,
            );
          }).toList(),
        ),
        const SizedBox(height: 16),

        // الحالة الفيزيائية
        const Text('الحالة الفيزيائية الظاهرية:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondaryDark)),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: _commonConditions.map((cond) {
            final isSelected = _selectedConditions.contains(cond);
            return FilterChip(
              selected: isSelected,
              label: Text(cond, style: const TextStyle(fontSize: 12)),
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedConditions.add(cond);
                  } else {
                    _selectedConditions.remove(cond);
                  }
                });
              },
              backgroundColor: AppColors.surfaceDark,
              selectedColor: AppColors.warning.withValues(alpha: 0.2),
              checkmarkColor: AppColors.warning,
            );
          }).toList(),
        ),
        const SizedBox(height: 16),

        // وصف العطل
        TextFormField(
          controller: _problemController,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'شكوى العميل وتوصيف العطل الهندسي *',
            hintText: 'قاطع باور، لا توجد إشارة صوتية، تجميد على الشعار...',
            alignLabelWithHint: true,
          ),
        ),
      ],
    );
  }

  Widget _buildStepImages() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'توثيق حالة الجهاز بالصور (محلياً بدون ذكاء اصطناعي توليدي):',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondaryDark),
        ),
        const SizedBox(height: 12),

        Row(
          children: [
            ElevatedButton.icon(
              onPressed: () => _pickImage(ImageSource.camera),
              icon: const Icon(Icons.photo_camera_rounded),
              label: const Text('التقاط بالكاميرا'),
            ),
            const SizedBox(width: 10),
            OutlinedButton.icon(
              onPressed: () => _pickImage(ImageSource.gallery),
              icon: const Icon(Icons.photo_library_rounded),
              label: const Text('من المعرض'),
            ),
          ],
        ),
        const SizedBox(height: 16),

        if (_capturedImages.isEmpty) ...[
          Container(
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.surfaceDark,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.borderDark, style: BorderStyle.solid),
            ),
            alignment: Alignment.center,
            child: const Text('لم يتم التقاط صور للجهاز بعد (اختياري)', style: TextStyle(color: AppColors.textSecondaryDark)),
          ),
        ] else ...[
          SizedBox(
            height: 120,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _capturedImages.length,
              separatorBuilder: (context, index) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final file = _capturedImages[index];
                return Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.file(file, width: 120, height: 120, fit: BoxFit.cover),
                    ),
                    Positioned(
                      top: 4,
                      left: 4,
                      child: InkWell(
                        onTap: () => setState(() => _capturedImages.removeAt(index)),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(color: Colors.black87, shape: BoxShape.circle),
                          child: const Icon(Icons.close_rounded, size: 14, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStepFinancials() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('عملة السند والحساب:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondaryDark)),
        const SizedBox(height: 8),

        Row(
          children: AppCurrency.values.map((cur) {
            final isSelected = _selectedCurrency == cur;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ChoiceChip(
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) setState(() => _selectedCurrency = cur);
                  },
                  label: Center(child: Text('${cur.label} (${cur.code})')),
                  selectedColor: AppColors.primary,
                  backgroundColor: AppColors.surfaceDark,
                  labelStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? AppColors.bgDark : AppColors.textPrimaryDark,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),

        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _estimatedCostController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'التكلفة التقديرية المتفق عليها',
                  suffixText: _selectedCurrency.symbol,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _advancePaidController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'العربون المدفوع نقداً/الآن',
                  suffixText: _selectedCurrency.symbol,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        const Text('طريقة استلام العربون:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondaryDark)),
        const SizedBox(height: 8),

        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: PaymentMethod.values.map((m) {
            final isSelected = _selectedPaymentMethod == m;
            return ChoiceChip(
              selected: isSelected,
              onSelected: (selected) {
                if (selected) setState(() => _selectedPaymentMethod = m);
              },
              label: Text(m.label),
              selectedColor: AppColors.accent,
              backgroundColor: AppColors.surfaceDark,
              labelStyle: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? AppColors.bgDark : AppColors.textPrimaryDark,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
