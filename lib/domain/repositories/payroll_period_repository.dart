import '../entities/payroll_period.dart';
import '../enums/enums.dart';

abstract class PayrollPeriodRepository {
  Future<List<PayrollPeriod>> getAll();
  Future<PayrollPeriod?> getById(String id);
  Future<PayrollPeriod?> getContaining(DateTime date);
  Future<PayrollPeriod> create(PayrollPeriod period);
  Future<PayrollPeriod> updateStatus(String id, PayrollPeriodStatus status);

  /// Locks the period. Implementations must make this a single atomic
  /// operation (architecture §13: "use database transactions for payroll
  /// finalization") and must be irreversible through normal UI actions.
  Future<PayrollPeriod> finalizePeriod(String id, String finalizedBy);
}
