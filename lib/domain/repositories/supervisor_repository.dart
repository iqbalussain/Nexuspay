import '../entities/supervisor.dart';

abstract class SupervisorRepository {
  Future<List<Supervisor>> getSupervisors({bool activeOnly = true});
  Future<Supervisor?> getSupervisor(String id);
  Future<Supervisor> create(Supervisor supervisor);
  Future<Supervisor> update(Supervisor supervisor);
}
