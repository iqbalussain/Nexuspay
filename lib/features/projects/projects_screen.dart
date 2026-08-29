import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/di/providers.dart';
import '../../../core/utils/id_generator.dart';
import '../../../domain/entities/project.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../../shared/widgets/form_helpers.dart';

// ---- Viewmodel -------------------------------------------------------

class ProjectsState {
  final List<Project> projects;
  final String searchQuery;
  final ProjectStatus? statusFilter;

  const ProjectsState({
    this.projects = const [],
    this.searchQuery = '',
    this.statusFilter,
  });

  List<Project> get filtered => projects.where((p) {
    final q = searchQuery.toLowerCase();
    if (q.isNotEmpty &&
        !p.name.toLowerCase().contains(q) &&
        !p.code.toLowerCase().contains(q)) {
      return false;
    }
    if (statusFilter != null && p.status != statusFilter) return false;
    return true;
  }).toList();

  ProjectsState copyWith({
    List<Project>? projects,
    String? searchQuery,
    ProjectStatus? statusFilter,
    bool clearStatusFilter = false,
  }) => ProjectsState(
    projects: projects ?? this.projects,
    searchQuery: searchQuery ?? this.searchQuery,
    statusFilter: clearStatusFilter
        ? null
        : (statusFilter ?? this.statusFilter),
  );
}

class ProjectsNotifier extends AsyncNotifier<ProjectsState> {
  @override
  Future<ProjectsState> build() async {
    final repo = ref.watch(projectRepositoryProvider);
    return ProjectsState(projects: await repo.getProjects());
  }

  Future<void> reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      return ProjectsState(
        projects: await ref.read(projectRepositoryProvider).getProjects(),
      );
    });
  }

  void setSearch(String q) =>
      state = state.whenData((s) => s.copyWith(searchQuery: q));

  void setStatusFilter(ProjectStatus? f) => state = state.whenData(
    (s) => s.copyWith(statusFilter: f, clearStatusFilter: f == null),
  );

  Future<void> addProject(Project p) async {
    await ref.read(projectRepositoryProvider).create(p);
    await reload();
  }

  Future<void> updateProject(Project p) async {
    await ref.read(projectRepositoryProvider).update(p);
    await reload();
  }
}

final projectsProvider = AsyncNotifierProvider<ProjectsNotifier, ProjectsState>(
  ProjectsNotifier.new,
);

// ---- Form ------------------------------------------------------------

class ProjectForm extends ConsumerStatefulWidget {
  final Project? existing;
  const ProjectForm({super.key, this.existing});

  @override
  ConsumerState<ProjectForm> createState() => _ProjectFormState();
}

class _ProjectFormState extends ConsumerState<ProjectForm> {
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;
  late String _name, _code;
  String? _costCentre;
  ProjectStatus _status = ProjectStatus.active;

  @override
  void initState() {
    super.initState();
    final p = widget.existing;
    _name = p?.name ?? '';
    _code = p?.code ?? '';
    _costCentre = p?.costCentre;
    _status = p?.status ?? ProjectStatus.active;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();
    setState(() => _saving = true);
    try {
      final notifier = ref.read(projectsProvider.notifier);
      final proj = Project(
        id: widget.existing?.id ?? IdGenerator.newId(),
        code: _code,
        name: _name,
        status: _status,
        costCentre: _costCentre,
      );
      if (widget.existing == null) {
        await notifier.addProject(proj);
      } else {
        await notifier.updateProject(proj);
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
    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        16,
        24,
        MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  widget.existing == null ? 'Add Project' : 'Edit Project',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),
            formTextField(
              label: 'Project Name',
              initialValue: _name,
              required: true,
              onSaved: (v) => _name = v!.trim(),
            ),
            formTextField(
              label: 'Project Code',
              hint: 'e.g. PRJ-A',
              initialValue: _code,
              required: true,
              onSaved: (v) => _code = v!.trim(),
            ),
            formTextField(
              label: 'Cost Centre',
              initialValue: _costCentre,
              onSaved: (v) => _costCentre = v?.trim(),
            ),
            formDropdown<ProjectStatus>(
              label: 'Status',
              value: _status,
              required: true,
              items: ProjectStatus.values
                  .map(
                    (s) => DropdownMenuItem(
                      value: s,
                      child: Text(
                        s.name[0].toUpperCase() + s.name.substring(1),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _status = v!),
            ),
            formActions(context: context, saving: _saving, onSave: _save),
          ],
        ),
      ),
    );
  }
}

Future<void> showProjectForm(BuildContext context, {Project? existing}) =>
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => ProjectForm(existing: existing),
    );

// ---- Screen ----------------------------------------------------------

class ProjectsScreen extends ConsumerWidget {
  const ProjectsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref
        .watch(projectsProvider)
        .when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (state) => _ProjectsBody(state: state),
        );
  }
}

class _ProjectsBody extends ConsumerWidget {
  final ProjectsState state;
  const _ProjectsBody({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(projectsProvider.notifier);
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
                  'Projects',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const Spacer(),
                Text(
                  '${filtered.length} of ${state.projects.length}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search by name or code…',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: notifier.setSearch,
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('All'),
                  selected: state.statusFilter == null,
                  onSelected: (_) => notifier.setStatusFilter(null),
                ),
                const SizedBox(width: 8),
                for (final s in ProjectStatus.values)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(
                        s.name[0].toUpperCase() + s.name.substring(1),
                      ),
                      selected: state.statusFilter == s,
                      onSelected: (_) => notifier.setStatusFilter(
                        state.statusFilter == s ? null : s,
                      ),
                    ),
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
                          Icons.apartment_outlined,
                          size: 48,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          state.projects.isEmpty
                              ? 'No projects yet. Tap + to add one.'
                              : 'No projects match the filter.',
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
                      final p = filtered[i];
                      final statusColor = switch (p.status) {
                        ProjectStatus.active => Colors.green,
                        ProjectStatus.onHold => Colors.orange,
                        ProjectStatus.closed => Colors.grey,
                      };
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: statusColor.withValues(alpha: 0.15),
                          child: Icon(
                            Icons.apartment,
                            color: statusColor,
                            size: 20,
                          ),
                        ),
                        title: Text(p.name),
                        subtitle: Text(
                          '${p.code}'
                          '${p.costCentre != null ? ' · ${p.costCentre}' : ''}',
                        ),
                        trailing: PopupMenuButton<String>(
                          itemBuilder: (_) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: ListTile(
                                leading: Icon(Icons.edit_outlined),
                                title: Text('Edit'),
                                dense: true,
                              ),
                            ),
                          ],
                          onSelected: (action) {
                            if (action == 'edit') {
                              showProjectForm(context, existing: p);
                            }
                          },
                        ),
                        onTap: () => showProjectForm(context, existing: p),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Add Project',
        onPressed: () => showProjectForm(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}
