import '../entities/payment_entity.dart';
import '../entities/repair_item_entity.dart';
import '../entities/repair_record_entity.dart';
import '../enums/repair_status.dart';

abstract class RepairRepository {
  Future<List<RepairRecordEntity>> getAllRepairs({RepairStatus? status});
  Future<RepairRecordEntity?> getRepairById(int id);
  Future<RepairRecordEntity?> getRepairByRecordNumber(String recordNumber);
  Future<List<Map<String, dynamic>>> searchRepairsWithDetails(String query, {RepairStatus? status});
  Future<Map<String, dynamic>?> getRepairFullDetails(int repairId);
  Future<bool> updateRepairStatus(int id, RepairStatus newStatus, {String? diagnosticNotes});
  Future<bool> updateDiagnosticNotes(int id, String notes);
  Future<bool> addRepairItem(RepairItemEntity item);
  Future<bool> deleteRepairItem(int itemId);
  Future<List<RepairItemEntity>> getRepairItems(int repairRecordId);
  Future<int> recordPayment(PaymentEntity payment);
  Future<List<PaymentEntity>> getPaymentsForRepair(int repairRecordId);
  Future<bool> updateDiscount(int repairId, double discountAmount);
  Future<Map<String, dynamic>> getDashboardStats();
  String generateWhatsAppMessage({
    required RepairRecordEntity record,
    required String customerName,
    required String deviceName,
    String? shopName,
    String? shopPhone,
  });
}
