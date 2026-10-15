abstract class AuditRepository {
  Future<void> logAction({
    int? userId,
    required String action,
    required String entityName,
    required String entityId,
    String? details,
  });

  Future<List<Map<String, dynamic>>> getAuditLogs({int limit = 100, int offset = 0});
}
