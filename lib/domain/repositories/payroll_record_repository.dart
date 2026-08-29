import '../entities/payroll_record.dart';

abstract class PayrollRecordRepository {
  Future<List<PayrollRecord>> getForPeriod(String payrollPeriodId);
  Future<PayrollRecord?> getForEmployeeInPeriod(String employeeId, String payrollPeriodId);

  /// Persists a new calculation snapshot. Implementations must increment
  /// [PayrollCalculationSnapshot.version] rather than overwrite history,
  /// and must reject this call entirely if the parent period is already
  /// finalized (use an adjustment instead).
  Future<PayrollRecord> saveCalculation(PayrollRecord record);

  Future<PayrollRecord> approve(String id);
}
