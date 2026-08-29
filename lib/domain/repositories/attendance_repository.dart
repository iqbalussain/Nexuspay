import '../entities/attendance_record.dart';

abstract class AttendanceRepository {
  Future<List<AttendanceRecord>> getForEmployeeInRange(
    String employeeId,
    DateTime start,
    DateTime end,
  );
  Future<List<AttendanceRecord>> getForPeriod(DateTime start, DateTime end);
  Future<AttendanceRecord> upsert(AttendanceRecord record);
}
