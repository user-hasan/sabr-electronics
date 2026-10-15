import 'package:flutter/material.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../domain/enums/device_category.dart';
import '../../../../domain/enums/repair_status.dart';
import '../../auth_lock/screens/pin_lock_dialog.dart';
import '../../devices/screens/intake_wizard_screen.dart';
import '../../inventory/screens/spare_parts_list_screen.dart';
import '../../repairs/screens/repairs_list_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                AppAssets.appLogo,
                width: 38,
                height: 38,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.memory_rounded, color: AppColors.bgDark, size: 24),
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.appName,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  AppStrings.appSubtitle,
                  style: TextStyle(fontSize: 11, color: AppColors.textSecondaryDark),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'سجل وتذاكر الصيانة',
            icon: const Icon(Icons.receipt_long_rounded, color: AppColors.primary),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const RepairsListScreen()),
              );
            },
          ),
          IconButton(
            tooltip: 'مستودع قطع الغيار والمكونات',
            icon: const Icon(Icons.inventory_2_rounded, color: AppColors.primary),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const SparePartsListScreen()),
              );
            },
          ),
          IconButton(
            tooltip: 'حالة الطابعة الحرارية',
            icon: const Icon(Icons.bluetooth_connected_rounded, color: AppColors.primary),
            onPressed: () {},
          ),
          IconButton(
            tooltip: 'قفل الشاشة السريع PIN',
            icon: const Icon(Icons.lock_person_rounded, color: AppColors.accent),
            onPressed: () {
              PinLockDialog.show(
                context: context,
                onSuccess: (user) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('تم التحقق بنجاح — مرحباً بك: ${user.displayName} (${user.role.label})'),
                    ),
                  );
                },
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // شريط العملات السريع
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.surfaceDark,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.borderDark),
                ),
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.payments_rounded, color: AppColors.primary, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'العملات المعتمدة:',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondaryDark),
                        ),
                      ],
                    ),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _buildCurrencyChip('ريال يمني (YER)', true),
                        _buildCurrencyChip('ريال سعودي (SAR)', false),
                        _buildCurrencyChip('دولار (USD)', false),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // بطاقات المؤشرات اللحظية (KPIs)
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.6,
                children: [
                  _buildKpiCard(
                    title: 'مستلمة اليوم',
                    count: '0',
                    subtitle: 'جاهز للاستقبال',
                    icon: Icons.inbox_rounded,
                    color: AppColors.statusReceived,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const RepairsListScreen(initialStatus: RepairStatus.received),
                        ),
                      );
                    },
                  ),
                  _buildKpiCard(
                    title: 'قيد الصيانة الفنية',
                    count: '0',
                    subtitle: 'على طاولة العمل',
                    icon: Icons.handyman_rounded,
                    color: AppColors.statusInProgress,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const RepairsListScreen(initialStatus: RepairStatus.inProgress),
                        ),
                      );
                    },
                  ),
                  _buildKpiCard(
                    title: 'جاهزة للتسليم',
                    count: '0',
                    subtitle: 'بانتظار العميل',
                    icon: Icons.verified_rounded,
                    color: AppColors.statusReady,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const RepairsListScreen(initialStatus: RepairStatus.ready),
                        ),
                      );
                    },
                  ),
                  _buildKpiCard(
                    title: 'الديون المتبقية',
                    count: '0 ر.ي',
                    subtitle: 'مستحقات التحصيل',
                    icon: Icons.account_balance_wallet_rounded,
                    color: AppColors.accent,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => const RepairsListScreen()),
                      );
                    },
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // أزرار الوصول السريع الرئيسية
              const Text(
                'الإجراءات الميدانية السريعة',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimaryDark),
              ),
              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (context) => const IntakeWizardScreen()),
                        );
                      },
                      icon: const Icon(Icons.add_task_rounded),
                      label: const Text('استلام جهاز جديد'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (context) => const SparePartsListScreen()),
                        );
                      },
                      icon: const Icon(Icons.inventory_2_rounded),
                      label: const Text('المستودع'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.qr_code_scanner_rounded),
                      label: const Text('مسح باركود'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // تخصصات المركز الهندسية
              const Text(
                'تخصصات المركز المعتمدة',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimaryDark),
              ),
              const SizedBox(height: 10),

              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: DeviceCategory.values.map((cat) {
                  return Chip(
                    avatar: Icon(cat.icon, size: 18, color: AppColors.primary),
                    label: Text(
                      cat.label,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    backgroundColor: AppColors.surfaceDark,
                    side: const BorderSide(color: AppColors.borderDark),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  );
                }).toList(),
              ),

              const SizedBox(height: 30),

              // شريط الحالة الأوفلاين
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.cloud_off_rounded, size: 16, color: AppColors.statusReady),
                    SizedBox(width: 6),
                    Text(
                      'النظام يعمل محلياً 100% بدون إنترنت (Offline-First)',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondaryDark),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrencyChip(String label, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primary.withValues(alpha: 0.15) : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isSelected ? AppColors.primary : AppColors.borderDark,
          width: 1,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? AppColors.primary : AppColors.textSecondaryDark,
        ),
      ),
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String count,
    required String subtitle,
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
  }) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondaryDark, fontWeight: FontWeight.w600),
                  ),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, size: 18, color: color),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    count,
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 10, color: AppColors.textSecondaryDark),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
