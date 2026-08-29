import '../entities/deduction.dart';

abstract class DeductionRepository {
  Future<List<Deduction>> getForEmployeeInPeriod(String employeeId, String payrollPeriodId);
  Future<Deduction> upsert(Deduction deduction);
  Future<Deduction> approve(String id);
}
