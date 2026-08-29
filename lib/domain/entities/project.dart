enum ProjectStatus { active, onHold, closed }

/// Projects/sites are independent master data. Closing a project must not
/// hide historical timesheets tied to it (architecture §18).
class Project {
  final String id;
  final String code;
  final String name;
  final ProjectStatus status;
  final String? costCentre;

  const Project({
    required this.id,
    required this.code,
    required this.name,
    required this.status,
    this.costCentre,
  });
}
