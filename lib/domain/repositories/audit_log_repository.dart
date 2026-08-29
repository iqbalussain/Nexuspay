import '../entities/audit_log_entry.dart';

abstract class AuditLogRepository {
  Future<void> record(AuditLogEntry entry);
  Future<List<AuditLogEntry>> getForEntity(String entityType, String entityId);
  Future<List<AuditLogEntry>> getRecent({int limit = 100});
}
