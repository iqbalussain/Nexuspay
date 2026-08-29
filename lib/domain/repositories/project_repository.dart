import '../entities/project.dart';

abstract class ProjectRepository {
  Future<List<Project>> getProjects({ProjectStatus? status});
  Future<Project?> getProject(String id);
  Future<Project> create(Project project);
  Future<Project> update(Project project);
}
