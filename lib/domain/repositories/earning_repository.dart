import '../entities/earning.dart';

abstract class EarningRepository {
  Future<List<Earning>> getForEmployeeInPeriod(String employeeId, String payrollPeriodId);
  Future<Earning> upsert(Earning earning);
  Future<Earning> approve(String id);
}
