import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// حالات دورة الصيانة الهندسية للأجهزة
enum RepairStatus {
  received('received', 'تم الاستلام', Icons.inbox_rounded, AppColors.statusReceived),
  inspection('inspection', 'قيد الفحص الهندسي', Icons.biotech_rounded, AppColors.statusInspection),
  waitingApproval('waiting_approval', 'بانتظار موافقة العميل', Icons.hourglass_top_rounded, AppColors.statusWaiting),
  inProgress('in_progress', 'قيد الإصلاح الفني', Icons.handyman_rounded, AppColors.statusInProgress),
  waitingParts('waiting_parts', 'بانتظار قطع غيار', Icons.pending_actions_rounded, AppColors.statusWaitingParts),
  ready('ready', 'جاهز للتسليم', Icons.verified_rounded, AppColors.statusReady),
  delivered('delivered', 'تم التسليم والقبض', Icons.task_alt_rounded, AppColors.statusDone),
  cancelled('cancelled', 'تعذر الإصلاح / ملغي', Icons.cancel_rounded, AppColors.statusCancelled);

  final String code;
  final String label;
  final IconData icon;
  final Color color;

  const RepairStatus(this.code, this.label, this.icon, this.color);

  static RepairStatus fromCode(String code) {
    return RepairStatus.values.firstWhere(
      (s) => s.code.toLowerCase() == code.toLowerCase(),
      orElse: () => RepairStatus.received,
    );
  }
}
