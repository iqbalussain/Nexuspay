import '../entities/salary_history.dart';

abstract class SalaryHistoryRepository {
  Future<List<SalaryHistory>> getForEmployee(String employeeId);

  /// Returns the salary record(s) effective at any point within
  /// [start]..[end] — may be more than one if salary changed mid-period.
  Future<List<SalaryHistory>> getEffectiveInRange(
    String employeeId,
    DateTime start,
    DateTime end,
  );

  /// Adds a new salary record and closes the previous one's
  /// `effectiveTo`. Never mutates/overwrites an existing record's amount.
  Future<SalaryHistory> addSalaryChange(SalaryHistory newRecord);
}
