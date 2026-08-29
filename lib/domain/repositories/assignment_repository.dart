import '../entities/assignment.dart';

abstract class AssignmentRepository {
  Future<List<Assignment>> getForEmployee(String employeeId);

  /// All assignments overlapping [start]..[end] — an employee may have
  /// several during one payroll period.
  Future<List<Assignment>> getOverlapping(String employeeId, DateTime start, DateTime end);

  Future<Assignment> create(Assignment assignment);

  /// Closes the current open-ended assignment (sets effectiveTo) and
  /// creates a new one — used when an employee moves projects.
  Future<Assignment> reassign(Assignment newAssignment);
}
