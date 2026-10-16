import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../domain/entities/app_settings_entity.dart';
import '../../../../domain/entities/repair_record_entity.dart';
import '../../../../domain/enums/app_currency.dart';
import '../../../../domain/enums/repair_status.dart';
import '../../../../services/printing_service.dart';
import '../../../providers/settings_provider.dart';
import '../../auth_lock/screens/pin_lock_dialog.dart';
import '../../audit/screens/audit_log_screen.dart';
import '../../../../data/services/backup_service.dart';

/// شاشة الإعدادات الشاملة لنظام صبر إلكترونكس
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Controllers
  late TextEditingController _shopNameController;
  late TextEditingController _shopPhoneController;
  late TextEditingController _shopAddressController;
  late TextEditingController _receiptTermsController;
  late TextEditingController _warrantyDaysController;
  late TextEditingController _lowStockController;
  late TextEditingController _geminiApiKeyController;

  bool _isSaving = false;
  bool _obscureApiKey = true;

  final BackupService _backupService = BackupService();
  List<BackupFileInfo> _backups = [];
  bool _isLoadingBackups = false;
  bool _isCreatingBackup = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _loadBackups();

    final settings = ref.read(settingsProvider);
    _shopNameController = TextEditingController(text: settings.shopName);
    _shopPhoneController = TextEditingController(text: settings.shopPhone);
    _shopAddressController = TextEditingController(text: settings.shopAddress);
    _receiptTermsController = TextEditingController(text: settings.receiptTerms);
    _warrantyDaysController = TextEditingController(text: settings.defaultWarrantyDays.toString());
    _lowStockController = TextEditingController(text: settings.lowStockThreshold.toString());
    _geminiApiKeyController = TextEditingController();

    _loadApiKey();
  }

  Future<void> _loadApiKey() async {
    final key = await ref.read(settingsProvider.notifier).getGeminiApiKey();
    if (key != null && mounted) {
      setState(() => _geminiApiKeyController.text = key);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _shopNameController.dispose();
    _shopPhoneController.dispose();
    _shopAddressController.dispose();
    _receiptTermsController.dispose();
    _warrantyDaysController.dispose();
    _lowStockController.dispose();
    _geminiApiKeyController.dispose();
    super.dispose();
  }

  Future<void> _saveAllSettings() async {
    setState(() => _isSaving = true);
    final current = ref.read(settingsProvider);

    final updated = current.copyWith(
      shopName: _shopNameController.text.trim(),
      shopPhone: _shopPhoneController.text.trim(),
      shopAddress: _shopAddressController.text.trim(),
      receiptTerms: _receiptTermsController.text.trim(),
      defaultWarrantyDays: int.tryParse(_warrantyDaysController.text.trim()) ?? 30,
      lowStockThreshold: int.tryParse(_lowStockController.text.trim()) ?? 2,
    );

    await ref.read(settingsProvider.notifier).saveSettings(updated);

    if (_geminiApiKeyController.text.trim().isNotEmpty) {
      await ref.read(settingsProvider.notifier).setGeminiApiKey(_geminiApiKeyController.text.trim());
    }

    if (mounted) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم حفظ وتطبيق كافة الإعدادات بنجاح'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  Future<void> _runTestPrint() async {
    final settings = ref.read(settingsProvider);
    final now = DateTime.now();
    final dummyRecord = RepairRecordEntity(
      recordNumber: 'TEST-58MM-PRINT',
      customerId: 0,
      deviceId: 0,
      receivedAt: now,
      status: RepairStatus.received,
      problemDescription: 'طباعة تجريبية لاختبار الطابعة الحرارية وتشكيل الحروف العربية',
      currency: settings.defaultCurrency,
      estimatedCost: 0,
      paidAmount: 0,
      createdAt: now,
      updatedAt: now,
    );

    try {
      await PrintingService.instance.printIntakeReceipt(
        record: dummyRecord,
        customerName: 'عميل تجريبي',
        customerPhone: '777000000',
        deviceBrand: 'طابعة حرارية',
        deviceModel: settings.printerPaperWidth,
        is80mm: settings.printerPaperWidth == '80mm',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ أثناء الطباعة التجريبية: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('إعدادات النظام العامة'),
          actions: [
            TextButton.icon(
              onPressed: _isSaving ? null : _saveAllSettings,
              icon: _isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.check_rounded, color: AppColors.primary),
              label: const Text('حفظ التعديلات', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 8),
          ],
          bottom: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            indicatorColor: AppColors.primary,
            labelColor: AppColors.primary,
            unselectedLabelColor: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            tabs: const [
              Tab(icon: Icon(Icons.storefront_rounded), text: 'بيانات المركز'),
              Tab(icon: Icon(Icons.print_rounded), text: 'الطباعة والعتاد'),
              Tab(icon: Icon(Icons.account_balance_rounded), text: 'المالية والعملات'),
              Tab(icon: Icon(Icons.palette_rounded), text: 'المظهر والعرض'),
              Tab(icon: Icon(Icons.security_rounded), text: 'الأمان والقفل'),
              Tab(icon: Icon(Icons.info_outline_rounded), text: 'عن النظام'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildShopInfoTab(settings),
            _buildPrinterTab(settings),
            _buildFinancialsTab(settings),
            _buildAppearanceTab(settings),
            _buildSecurityTab(settings),
            _buildAboutTab(settings),
          ],
        ),
      ),
    );
  }

  // 1. بيانات المركز وترويسة السندات
  Widget _buildShopInfoTab(AppSettingsEntity settings) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('ترويسة وهوية المركز على الفواتير', Icons.store_rounded),
          const SizedBox(height: 12),
          TextField(
            controller: _shopNameController,
            decoration: const InputDecoration(
              labelText: 'اسم المركز / الورشة *',
              prefixIcon: Icon(Icons.badge_rounded),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _shopPhoneController,
            decoration: const InputDecoration(
              labelText: 'أرقام هواتف التواصل (تطبع على السند) *',
              prefixIcon: Icon(Icons.phone_rounded),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _shopAddressController,
            decoration: const InputDecoration(
              labelText: 'العنوان الفعلي للورشة *',
              prefixIcon: Icon(Icons.location_on_rounded),
            ),
          ),
          const SizedBox(height: 16),
          _buildSectionHeader('شروط الضمان وتذييل السند', Icons.policy_rounded),
          const SizedBox(height: 12),
          TextField(
            controller: _warrantyDaysController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'فترة الضمان الافتراضية (بالأيام) *',
              prefixIcon: Icon(Icons.verified_user_rounded),
              suffixText: 'يوماً',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _receiptTermsController,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'شروط وضوابط الاستلام المطبوعة أسفل الإيصال',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            title: const Text('طباعة شعار المركز على السندات الحرارية'),
            subtitle: const Text('تضمين شعار الشريحة الإلكترونية في رأس الفاتورة'),
            value: settings.printLogoOnReceipt,
            onChanged: (val) {
              ref.read(settingsProvider.notifier).saveSettings(
                    settings.copyWith(printLogoOnReceipt: val),
                  );
            },
          ),
        ],
      ),
    );
  }

  // 2. العتاد والطباعة الحرارية
  Widget _buildPrinterTab(AppSettingsEntity settings) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('إعدادات الطابعة والمقاس المعتمد', Icons.receipt_long_rounded),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: RadioGroup<String>(
                groupValue: settings.printerPaperWidth,
                onChanged: (val) {
                  if (val != null) {
                    ref.read(settingsProvider.notifier).setPrinterPaperWidth(val);
                  }
                },
                child: Column(
                  children: const [
                    RadioListTile<String>(
                      title: Text('طابعة صغيرة مقاس 58mm (الافتراضي للورش المحمولة)'),
                      subtitle: Text('عرض 384 نقطة - طابعات البلوتوث المحمولة'),
                      value: '58mm',
                    ),
                    Divider(),
                    RadioListTile<String>(
                      title: Text('طابعة كاشير مقاس 80mm'),
                      subtitle: Text('عرض 576 نقطة - طابعات نقاط البيع الكبيرة وUSB'),
                      value: '80mm',
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildSectionHeader('الأتمتة الميدانية للطباعة', Icons.auto_mode_rounded),
          const SizedBox(height: 8),
          SwitchListTile(
            title: const Text('طباعة سند استلام العميل تلقائياً عند الحفظ'),
            subtitle: const Text('فتح نافذة الطباعة فور انتهاء معالج الاستلام'),
            value: settings.autoPrintIntakeReceipt,
            onChanged: (val) {
              ref.read(settingsProvider.notifier).saveSettings(
                    settings.copyWith(autoPrintIntakeReceipt: val),
                  );
            },
          ),
          SwitchListTile(
            title: const Text('طباعة ملصق الشاسيه اللاصق تلقائياً'),
            subtitle: const Text('طباعة ملصق الباركود الصغير اللاصق على ظهر الجهاز'),
            value: settings.autoPrintStickyTag,
            onChanged: (val) {
              ref.read(settingsProvider.notifier).saveSettings(
                    settings.copyWith(autoPrintStickyTag: val),
                  );
            },
          ),
          const SizedBox(height: 20),
          Center(
            child: ElevatedButton.icon(
              onPressed: _runTestPrint,
              icon: const Icon(Icons.print_rounded),
              label: const Text('إجراء طباعة تجريبية فورية (Test Print)'),
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14)),
            ),
          ),
        ],
      ),
    );
  }

  // 3. المالية والعملات
  Widget _buildFinancialsTab(AppSettingsEntity settings) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('العملة الافتراضية للمعاملات', Icons.payments_rounded),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: RadioGroup<AppCurrency>(
                groupValue: settings.defaultCurrency,
                onChanged: (val) {
                  if (val != null) {
                    ref.read(settingsProvider.notifier).setDefaultCurrency(val);
                  }
                },
                child: Column(
                  children: AppCurrency.values.map((cur) {
                    return RadioListTile<AppCurrency>(
                      title: Text('${cur.label} (${cur.code})'),
                      subtitle: Text('الرمز المعتمد: ${cur.symbol}'),
                      value: cur,
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildSectionHeader('المخزون والرقابة المالية', Icons.inventory_2_rounded),
          const SizedBox(height: 12),
          TextField(
            controller: _lowStockController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'حد التنبيه الحرج لنفاد قطع الغيار *',
              prefixIcon: Icon(Icons.warning_amber_rounded),
              suffixText: 'قطع',
            ),
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            title: const Text('اشتراط PIN المدير لمنح الخصومات المالية'),
            subtitle: const Text('منع الفني من تطبيق أي خصم مالي على التذكرة دون موافقة المالك'),
            value: settings.requirePinForDiscounts,
            onChanged: (val) {
              ref.read(settingsProvider.notifier).saveSettings(
                    settings.copyWith(requirePinForDiscounts: val),
                  );
            },
          ),
        ],
      ),
    );
  }

  // 4. المظهر والعرض
  Widget _buildAppearanceTab(AppSettingsEntity settings) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('نمط مظهر التطبيق (Theme Mode)', Icons.palette_rounded),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: RadioGroup<ThemeMode>(
                groupValue: settings.themeMode,
                onChanged: (val) {
                  if (val != null) {
                    ref.read(settingsProvider.notifier).setThemeMode(val);
                  }
                },
                child: Column(
                  children: const [
                    RadioListTile<ThemeMode>(
                      title: Text('الوضع الداكن (Midnight Indigo) — الافتراضي'),
                      subtitle: Text('كحلي نيلي عميق مريح للعين تحت إضاءة الورش القوية'),
                      value: ThemeMode.dark,
                    ),
                    Divider(),
                    RadioListTile<ThemeMode>(
                      title: Text('الوضع الفاتح (Pearl Light)'),
                      subtitle: Text('أسطح لؤلؤية نقية مريحة وعالية التباين'),
                      value: ThemeMode.light,
                    ),
                    Divider(),
                    RadioListTile<ThemeMode>(
                      title: Text('تلقائي (حسب إعدادات نظام الجهاز)'),
                      value: ThemeMode.system,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildSectionHeader('تخصيص حجم الخطوط', Icons.format_size_rounded),
          const SizedBox(height: 8),
          Slider(
            value: settings.textScale,
            min: 0.9,
            max: 1.25,
            divisions: 7,
            label: '${(settings.textScale * 100).toInt()}%',
            onChanged: (val) {
              ref.read(settingsProvider.notifier).setTextScale(val);
            },
          ),
          Center(
            child: Text(
              'حجم الخط الحالي: ${(settings.textScale * 100).toInt()}%',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // 5. الأمان والقفل
  Widget _buildSecurityTab(AppSettingsEntity settings) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('القفل السريع للشاشة', Icons.lock_clock_rounded),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  const Text('المهلة الزمنية للقفل التلقائي عند عدم اللمس:'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [0, 1, 3, 5, 15].map((mins) {
                      final isSelected = settings.autoLockTimeout == mins;
                      final label = mins == 0 ? 'معطل' : '$mins د';
                      return ChoiceChip(
                        label: Text(label),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            ref.read(settingsProvider.notifier).saveSettings(
                                  settings.copyWith(autoLockTimeout: mins),
                                );
                          }
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildSectionHeader('تغيير رمز PIN للمدير العام', Icons.pin_rounded),
          const SizedBox(height: 12),
          ListTile(
            tileColor: AppColors.surfaceDarkElevated,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            leading: const Icon(Icons.password_rounded, color: AppColors.primary),
            title: const Text('التحقق وتحديث رمز PIN'),
            subtitle: const Text('الرمز الافتراضي: 1234'),
            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
            onTap: () {
              PinLockDialog.show(
                context: context,
                onSuccess: (user) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('تم التحقق بنجاح بصلاحية: ${user.displayName}')),
                  );
                },
              );
            },
          ),
          const SizedBox(height: 16),
          _buildSectionHeader('سجل الرقابة والتدقيق', Icons.policy_rounded),
          const SizedBox(height: 12),
          ListTile(
            tileColor: AppColors.surfaceDarkElevated,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            leading: const Icon(Icons.history_edu_rounded, color: AppColors.primary),
            title: const Text('استعراض سجل الرقابة والعمليات'),
            subtitle: const Text('توثيق العمليات الحساسة، تعديل الحالات، والتخفيضات المالية'),
            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AuditLogScreen()),
              );
            },
          ),
          const SizedBox(height: 20),
          _buildSectionHeader('النسخ الاحتياطي واستعادة البيانات', Icons.backup_rounded),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'قاعدة البيانات المحلية (SQLite)',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      ElevatedButton.icon(
                        icon: _isCreatingBackup
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                              )
                            : const Icon(Icons.add_to_photos_rounded, size: 16),
                        label: const Text('إنشاء نسخة الآن'),
                        onPressed: _isCreatingBackup ? null : _handleCreateBackup,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_isLoadingBackups)
                    const Center(child: Padding(padding: EdgeInsets.all(8), child: CircularProgressIndicator()))
                  else if (_backups.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceDarkElevated,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Text(
                          'لا توجد نسخ احتياطية سابقة محفوظة محلياً.',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondaryDark),
                        ),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _backups.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, idx) {
                        final b = _backups[idx];
                        return ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.storage_rounded, color: AppColors.primary, size: 20),
                          title: Text(b.fileName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          subtitle: Text('${b.formattedDate} • ${b.formattedSize}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryDark)),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TextButton(
                                onPressed: () => _handleRestoreBackup(b),
                                child: const Text('استعادة', style: TextStyle(fontSize: 12)),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.statusPending),
                                onPressed: () => _handleDeleteBackup(b),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          _buildSectionHeader('الوسائط والذكاء الاصطناعي (v2 الاختياري)', Icons.auto_awesome_rounded),
          const SizedBox(height: 12),
          TextField(
            controller: _geminiApiKeyController,
            obscureText: _obscureApiKey,
            decoration: InputDecoration(
              labelText: 'مفتاح Gemini API Key السحابي المشفر',
              hintText: 'AIzaSy...',
              prefixIcon: const Icon(Icons.key_rounded),
              suffixIcon: IconButton(
                icon: Icon(_obscureApiKey ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setState(() => _obscureApiKey = !_obscureApiKey),
              ),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'يُحفظ المفتاح مشفراً محلياً في FlutterSecureStorage ولا يُرسل لأي جهة.',
            style: TextStyle(fontSize: 11, color: AppColors.textSecondaryDark),
          ),
        ],
      ),
    );
  }

  Future<void> _loadBackups() async {
    setState(() => _isLoadingBackups = true);
    try {
      final list = await _backupService.listBackups();
      if (mounted) {
        setState(() {
          _backups = list;
          _isLoadingBackups = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingBackups = false);
    }
  }

  Future<void> _handleCreateBackup() async {
    setState(() => _isCreatingBackup = true);
    try {
      final backup = await _backupService.createBackup();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.statusReady,
            content: Text('تم إنشاء النسخة الاحتياطية بنجاح: ${backup.fileName} (${backup.formattedSize})'),
          ),
        );
        _loadBackups();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.statusPending,
            content: Text('فشل إنشاء النسخة الاحتياطية: $e'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isCreatingBackup = false);
    }
  }

  Future<void> _handleRestoreBackup(BackupFileInfo backup) async {
    PinLockDialog.show(
      context: context,
      onSuccess: (user) async {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => Directionality(
            textDirection: TextDirection.rtl,
            child: AlertDialog(
              title: const Text('تأكيد استعادة قاعدة البيانات'),
              content: Text(
                'سيتم استبدال البيانات الحالية بالنسخة الاحتياطية المؤرخة في ${backup.formattedDate}.\n\nهل ترغب بالمتابعة؟',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('إلغاء'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.statusPending),
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('استعادة الآن'),
                ),
              ],
            ),
          ),
        );

        if (confirmed == true && mounted) {
          try {
            await _backupService.restoreBackup(backup.path, activeUserId: user.id);
            await ref.read(settingsProvider.notifier).loadSettings();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  backgroundColor: AppColors.statusReady,
                  content: Text('تمت استعادة قاعدة البيانات بنجاح ومزامنة الإعدادات!'),
                ),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: AppColors.statusPending,
                  content: Text('فشل استعادة النسخة الاحتياطية: $e'),
                ),
              );
            }
          }
        }
      },
    );
  }

  Future<void> _handleDeleteBackup(BackupFileInfo backup) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('حذف النسخة الاحتياطية'),
          content: Text('هل أنت متأكد من حذف الملف "${backup.fileName}"؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.statusPending),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('حذف'),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true) {
      await _backupService.deleteBackup(backup.path);
      _loadBackups();
    }
  }

  // 6. عن النظام والجهة المطورة
  Widget _buildAboutTab(AppSettingsEntity settings) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primary, width: 2),
              ),
              child: const Icon(Icons.memory_rounded, size: 48, color: AppColors.primary),
            ),
            const SizedBox(height: 16),
            const Text(
              AppStrings.appName,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const Text(
              AppStrings.appSubtitle,
              style: TextStyle(fontSize: 13, color: AppColors.textSecondaryDark),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surfaceDarkElevated,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.borderDark),
              ),
              child: const Text('الإصدار: v1.0.0 (بناء 100) — محلي أوفلاين 100%', style: TextStyle(fontSize: 11)),
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 12),
            _buildAboutRow('المطور المسؤول', 'Alzabidi'),
            _buildAboutRow('الجهة المطورة', 'System Yemen Assist'),
            _buildAboutRow('البريد الإلكتروني', 'has7749an@gmail.com'),
            _buildAboutRow('هاتف الدعم الميداني', '+967 774 918 638'),
            _buildAboutRow('حقوق النشر', '© 2026 System Yemen Assist. All rights reserved.'),
            const SizedBox(height: 20),
            const Text(
              'النظام مبني وفق معمارية Clean Architecture ومحرك SQLite المحلي للعمل المستمر بلا إنترنت.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppColors.textSecondaryDark),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildAboutRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryDark)),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
