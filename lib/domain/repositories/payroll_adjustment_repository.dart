import '../entities/payroll_adjustment.dart';

abstract class PayrollAdjustmentRepository {
  Future<List<PayrollAdjustment>> getForPayrollRecord(String payrollRecordId);

  /// Adjustments are append-only. There is deliberately no `update`
  /// or `delete` in this contract — corrections require a new,
  /// explicitly-reasoned adjustment (architecture §2, §15).
  Future<PayrollAdjustment> add(PayrollAdjustment adjustment);
}
