import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/di/providers.dart';
import '../../../core/utils/id_generator.dart';
import '../../../domain/entities/assignment.dart';
import '../../../domain/entities/employee.dart';
import '../../../domain/entities/project.dart';
import '../../../domain/entities/supervisor.dart';
import '../../../shared/widgets/form_helpers.dart';

// ---- Viewmodel -------------------------------------------------------

/// Bundles an Assignment with its resolved Employee/Project/Supervisor
/// names so the list doesn't need repeated async calls to display labels.
class ResolvedAssignment {
  final Assignment assignment;
  final String employeeName;
  final String employeeCode;
  final String projectName;
  final String supervisorName;

  const ResolvedAssignment({
    required this.assignment,
    required this.employeeName,
    required this.employeeCode,
    required this.projectName,
    required this.supervisorName,
  });

  bool get isActive => assignment.effectiveTo == null;
}

class AssignmentsState {
  final List<ResolvedAssignment> assignments;
  final String searchQuery;
  final bool activeOnly;

  const AssignmentsState({
    this.assignments = const [],
    this.searchQuery = '',
    this.activeOnly = false,
  });

  List<ResolvedAssignment> get filtered => assignments.where((a) {
    if (activeOnly && !a.isActive) return false;
    final q = searchQuery.toLowerCase();
    if (q.isNotEmpty &&
        !a.employeeName.toLowerCase().contains(q) &&
        !a.projectName.toLowerCase().contains(q) &&
        !a.supervisorName.toLowerCase().contains(q)) {
      return false;
    }
    return true;
  }).toList();

  AssignmentsState copyWith({
    List<ResolvedAssignment>? assignments,
    String? searchQuery,
    bool? activeOnly,
  }) => AssignmentsState(
    assignments: assignments ?? this.assignments,
    searchQuery: searchQuery ?? this.searchQuery,
    activeOnly: activeOnly ?? this.activeOnly,
  );
}

class AssignmentsNotifier extends AsyncNotifier<AssignmentsState> {
  @override
  Future<AssignmentsState> build() async {
    final assignRepo = ref.watch(assignmentRepositoryProvider);
    final empRepo = ref.watch(employeeRepositoryProvider);
    final projRepo = ref.watch(projectRepositoryProvider);
    final supRepo = ref.watch(supervisorRepositoryProvider);

    final employees = await empRepo.getEmployees(const EmployeeFilter());
    final projects = await projRepo.getProjects();
    final supervisors = await supRepo.getSupervisors(activeOnly: false);

    final empMap = {for (final e in employees) e.id: e};
    final projMap = {for (final p in projects) p.id: p};
    final supMap = {for (final s in supervisors) s.id: s};

    // Collect all assignments for all employees
    final resolved = <ResolvedAssignment>[];
    for (final emp in employees) {
      final assignments = await assignRepo.getForEmployee(emp.id);
      for (final a in assignments) {
        final e = empMap[a.employeeId];
        final p = projMap[a.projectId];
        final s = supMap[a.supervisorId];
        resolved.add(
          ResolvedAssignment(
            assignment: a,
            employeeName: e?.fullName ?? a.employeeId,
            employeeCode: e?.employeeCode ?? '',
            projectName: p?.name ?? a.projectId,
            supervisorName: s?.fullName ?? a.supervisorId,
          ),
        );
      }
    }

    // Sort: active first, then by start date desc
    resolved.sort((a, b) {
      if (a.isActive != b.isActive) return a.isActive ? -1 : 1;
      return b.assignment.effectiveFrom.compareTo(a.assignment.effectiveFrom);
    });

    return AssignmentsState(assignments: resolved);
  }

  Future<void> reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => build());
  }

  void setSearch(String q) =>
      state = state.whenData((s) => s.copyWith(searchQuery: q));
  void setActiveOnly(bool v) =>
      state = state.whenData((s) => s.copyWith(activeOnly: v));

  Future<void> createAssignment(Assignment a) async {
    await ref.read(assignmentRepositoryProvider).create(a);
    await reload();
  }

  Future<void> reassign(Assignment newAssignment) async {
    await ref.read(assignmentRepositoryProvider).reassign(newAssignment);
    await reload();
  }
}

final assignmentsProvider =
    AsyncNotifierProvider<AssignmentsNotifier, AssignmentsState>(
      AssignmentsNotifier.new,
    );

// ---- Helpers for the form (shared employee/project/supervisor lists) --

final _formSupportProvider =
    FutureProvider<
      ({
        List<Employee> employees,
        List<Project> projects,
        List<Supervisor> supervisors,
      })
    >((ref) async {
      final employees = await ref
          .read(employeeRepositoryProvider)
          .getEmployees(const EmployeeFilter());
      final projects = await ref.read(projectRepositoryProvider).getProjects();
      final supervisors = await ref
          .read(supervisorRepositoryProvider)
          .getSupervisors();
      return (
        employees: employees,
        projects: projects,
        supervisors: supervisors,
      );
    });

// ---- Form ------------------------------------------------------------

class AssignmentForm extends ConsumerStatefulWidget {
  /// If non-null, this is a reassignment (will close the existing one).
  final String? employeeId;
  final String? employeeName;
  const AssignmentForm({super.key, this.employeeId, this.employeeName});

  @override
  ConsumerState<AssignmentForm> createState() => _AssignmentFormState();
}

class _AssignmentFormState extends ConsumerState<AssignmentForm> {
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;
  String? _employeeId;
  String? _projectId;
  String? _supervisorId;
  DateTime _effectiveFrom = DateTime.now();

  @override
  void initState() {
    super.initState();
    _employeeId = widget.employeeId;
  }

  Future<void> _save(
    List<Employee> employees,
    List<Project> projects,
    List<Supervisor> supervisors,
  ) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final notifier = ref.read(assignmentsProvider.notifier);
      final newAssignment = Assignment(
        id: IdGenerator.newId(),
        employeeId: _employeeId!,
        projectId: _projectId!,
        supervisorId: _supervisorId!,
        effectiveFrom: _effectiveFrom,
      );
      if (widget.employeeId != null) {
        // Reassignment — close previous open assignment for this employee
        await notifier.reassign(newAssignment);
      } else {
        await notifier.createAssignment(newAssignment);
      }
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final supportAsync = ref.watch(_formSupportProvider);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        16,
        24,
        MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: supportAsync.when(
        loading: () => const SizedBox(
          height: 120,
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (e, _) => Text('Error loading form data: $e'),
        data: (data) => Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    widget.employeeId != null
                        ? 'Reassign ${widget.employeeName ?? 'Employee'}'
                        : 'New Assignment',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              if (widget.employeeId != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    'This will close the current open assignment and create '
                    'a new one from the selected effective date.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              const SizedBox(height: 8),
              if (widget.employeeId == null)
                formDropdown<String>(
                  label: 'Employee',
                  value: _employeeId,
                  required: true,
                  items: data.employees
                      .map(
                        (e) => DropdownMenuItem(
                          value: e.id,
                          child: Text('${e.fullName} (${e.employeeCode})'),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => _employeeId = v),
                ),
              formDropdown<String>(
                label: 'Project',
                value: _projectId,
                required: true,
                items: data.projects
                    .map(
                      (p) => DropdownMenuItem(value: p.id, child: Text(p.name)),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _projectId = v),
              ),
              formDropdown<String>(
                label: 'Supervisor',
                value: _supervisorId,
                required: true,
                items: data.supervisors
                    .map(
                      (s) => DropdownMenuItem(
                        value: s.id,
                        child: Text(s.fullName),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _supervisorId = v),
              ),
              formDateField(
                context: context,
                label: 'Effective From',
                value: _effectiveFrom,
                required: true,
                onPicked: (d) => setState(() => _effectiveFrom = d),
              ),
              const SizedBox(height: 8),
              formActions(
                context: context,
                saving: _saving,
                onSave: () =>
                    _save(data.employees, data.projects, data.supervisors),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> showAssignmentForm(
  BuildContext context, {
  String? employeeId,
  String? employeeName,
}) => showModalBottomSheet(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
  ),
  builder: (_) =>
      AssignmentForm(employeeId: employeeId, employeeName: employeeName),
);

// ---- Screen ----------------------------------------------------------

class AssignmentsScreen extends ConsumerWidget {
  const AssignmentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref
        .watch(assignmentsProvider)
        .when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (state) => _AssignmentsBody(state: state),
        );
  }
}

class _AssignmentsBody extends ConsumerWidget {
  final AssignmentsState state;
  const _AssignmentsBody({required this.state});

  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(assignmentsProvider.notifier);
    final filtered = state.filtered;

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Text(
                  'Assignments',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const Spacer(),
                Text(
                  '${filtered.length} shown',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search employee, project or supervisor…',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: notifier.setSearch,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('Active only'),
                  selected: state.activeOnly,
                  onSelected: notifier.setActiveOnly,
                ),
              ],
            ),
          ),
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.assignment_ind_outlined,
                          size: 48,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          state.assignments.isEmpty
                              ? 'No assignments yet. Tap + to create one.'
                              : 'No assignments match the filter.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.only(bottom: 80),
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final ra = filtered[i];
                      final a = ra.assignment;
                      final until = a.effectiveTo != null
                          ? _fmt(a.effectiveTo!)
                          : 'present';

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: ra.isActive
                              ? Colors.green.withValues(alpha: 0.15)
                              : Colors.grey.withValues(alpha: 0.15),
                          child: Icon(
                            Icons.person,
                            color: ra.isActive ? Colors.green : Colors.grey,
                            size: 20,
                          ),
                        ),
                        title: Text(ra.employeeName),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${ra.projectName} · ${ra.supervisorName}'),
                            Text(
                              '${_fmt(a.effectiveFrom)} → $until',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                        isThreeLine: true,
                        trailing: ra.isActive
                            ? PopupMenuButton<String>(
                                itemBuilder: (_) => [
                                  const PopupMenuItem(
                                    value: 'reassign',
                                    child: ListTile(
                                      leading: Icon(Icons.swap_horiz_outlined),
                                      title: Text('Reassign'),
                                      dense: true,
                                    ),
                                  ),
                                ],
                                onSelected: (action) {
                                  if (action == 'reassign') {
                                    showAssignmentForm(
                                      context,
                                      employeeId: a.employeeId,
                                      employeeName: ra.employeeName,
                                    );
                                  }
                                },
                              )
                            : null,
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'New Assignment',
        onPressed: () => showAssignmentForm(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}
