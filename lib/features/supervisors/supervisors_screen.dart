import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/di/providers.dart';
import '../../../core/utils/id_generator.dart';
import '../../../domain/entities/supervisor.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../../shared/widgets/form_helpers.dart';

// ---- Viewmodel -------------------------------------------------------

class SupervisorsState {
  final List<Supervisor> supervisors;
  final String searchQuery;
  final bool? activeFilter;

  const SupervisorsState({
    this.supervisors = const [],
    this.searchQuery = '',
    this.activeFilter,
  });

  List<Supervisor> get filtered => supervisors.where((s) {
    final q = searchQuery.toLowerCase();
    if (q.isNotEmpty && !s.fullName.toLowerCase().contains(q)) return false;
    if (activeFilter != null && s.active != activeFilter) return false;
    return true;
  }).toList();

  SupervisorsState copyWith({
    List<Supervisor>? supervisors,
    String? searchQuery,
    bool? activeFilter,
    bool clearActiveFilter = false,
  }) => SupervisorsState(
    supervisors: supervisors ?? this.supervisors,
    searchQuery: searchQuery ?? this.searchQuery,
    activeFilter: clearActiveFilter
        ? null
        : (activeFilter ?? this.activeFilter),
  );
}

class SupervisorsNotifier extends AsyncNotifier<SupervisorsState> {
  @override
  Future<SupervisorsState> build() async {
    final repo = ref.watch(supervisorRepositoryProvider);
    return SupervisorsState(
      supervisors: await repo.getSupervisors(activeOnly: false),
    );
  }

  Future<void> reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      return SupervisorsState(
        supervisors: await ref
            .read(supervisorRepositoryProvider)
            .getSupervisors(activeOnly: false),
      );
    });
  }

  void setSearch(String q) =>
      state = state.whenData((s) => s.copyWith(searchQuery: q));
  void setActiveFilter(bool? f) => state = state.whenData(
    (s) => s.copyWith(activeFilter: f, clearActiveFilter: f == null),
  );

  Future<void> addSupervisor(Supervisor s) async {
    await ref.read(supervisorRepositoryProvider).create(s);
    await reload();
  }

  Future<void> updateSupervisor(Supervisor s) async {
    await ref.read(supervisorRepositoryProvider).update(s);
    await reload();
  }
}

final supervisorsProvider =
    AsyncNotifierProvider<SupervisorsNotifier, SupervisorsState>(
      SupervisorsNotifier.new,
    );

// ---- Form ------------------------------------------------------------

class SupervisorForm extends ConsumerStatefulWidget {
  final Supervisor? existing;
  const SupervisorForm({super.key, this.existing});

  @override
  ConsumerState<SupervisorForm> createState() => _SupervisorFormState();
}

class _SupervisorFormState extends ConsumerState<SupervisorForm> {
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;
  late String _fullName;
  late bool _active;

  @override
  void initState() {
    super.initState();
    _fullName = widget.existing?.fullName ?? '';
    _active = widget.existing?.active ?? true;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();
    setState(() => _saving = true);
    try {
      final notifier = ref.read(supervisorsProvider.notifier);
      final sup = Supervisor(
        id: widget.existing?.id ?? IdGenerator.newId(),
        fullName: _fullName,
        active: _active,
      );
      if (widget.existing == null) {
        await notifier.addSupervisor(sup);
      } else {
        await notifier.updateSupervisor(sup);
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
                  widget.existing == null
                      ? 'Add Supervisor'
                      : 'Edit Supervisor',
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
              label: 'Full Name',
              initialValue: _fullName,
              required: true,
              onSaved: (v) => _fullName = v!.trim(),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Active'),
              subtitle: const Text(
                'Inactive supervisors cannot receive new assignments',
              ),
              value: _active,
              onChanged: (v) => setState(() => _active = v),
            ),
            const SizedBox(height: 8),
            formActions(context: context, saving: _saving, onSave: _save),
          ],
        ),
      ),
    );
  }
}

Future<void> showSupervisorForm(BuildContext context, {Supervisor? existing}) =>
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SupervisorForm(existing: existing),
    );

// ---- Screen ----------------------------------------------------------

class SupervisorsScreen extends ConsumerWidget {
  const SupervisorsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref
        .watch(supervisorsProvider)
        .when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (state) => _SupervisorsBody(state: state),
        );
  }
}

class _SupervisorsBody extends ConsumerWidget {
  final SupervisorsState state;
  const _SupervisorsBody({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(supervisorsProvider.notifier);
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
                  'Supervisors',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const Spacer(),
                Text(
                  '${filtered.length} of ${state.supervisors.length}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search by name…',
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
                  selected: state.activeFilter == null,
                  onSelected: (_) => notifier.setActiveFilter(null),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Active'),
                  selected: state.activeFilter == true,
                  onSelected: (_) => notifier.setActiveFilter(
                    state.activeFilter == true ? null : true,
                  ),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Inactive'),
                  selected: state.activeFilter == false,
                  onSelected: (_) => notifier.setActiveFilter(
                    state.activeFilter == false ? null : false,
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
                          Icons.supervisor_account_outlined,
                          size: 48,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          state.supervisors.isEmpty
                              ? 'No supervisors yet. Tap + to add one.'
                              : 'No supervisors match the filter.',
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
                      final s = filtered[i];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: s.active
                              ? Colors.blue.withValues(alpha: 0.15)
                              : Colors.grey.withValues(alpha: 0.15),
                          child: Icon(
                            Icons.person,
                            color: s.active ? Colors.blue : Colors.grey,
                            size: 20,
                          ),
                        ),
                        title: Text(s.fullName),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (!s.active) const Chip(label: Text('Inactive')),
                            PopupMenuButton<String>(
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
                                  showSupervisorForm(context, existing: s);
                                }
                              },
                            ),
                          ],
                        ),
                        onTap: () => showSupervisorForm(context, existing: s),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Add Supervisor',
        onPressed: () => showSupervisorForm(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}
