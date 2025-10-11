import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/project.dart';
import '../../state/projects_state.dart';
import '../../theme.dart';

class ProjectsListScreen extends ConsumerStatefulWidget {
  const ProjectsListScreen({super.key});

  @override
  ConsumerState<ProjectsListScreen> createState() => _ProjectsListScreenState();
}

class _ProjectsListScreenState extends ConsumerState<ProjectsListScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(projectsProvider);
    final ctrl = ref.read(projectsProvider.notifier);
    final isDesktop = MediaQuery.sizeOf(context).width >= AppBreakpoints.desktop;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 360),
                child: TextField(
                  controller: _searchCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Search projects',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onSubmitted: (v) => ctrl.applyFilters(),
                  onChanged: (v) => ctrl.setSearch(v),
                ),
              ),
              DropdownButtonFormField<String>(
                value: vm.filter.status.isEmpty ? null : vm.filter.status,
                items: const [
                  DropdownMenuItem(value: 'Draft', child: Text('Draft')),
                  DropdownMenuItem(value: 'InProgress', child: Text('In progress')),
                  DropdownMenuItem(value: 'Approved', child: Text('Approved')),
                  DropdownMenuItem(value: 'Closed', child: Text('Closed')),
                ],
                decoration: const InputDecoration(labelText: 'Status'),
                onChanged: (v) => ctrl.setStatus(v ?? ''),
              ),
              FilledButton.icon(
                onPressed: vm.loading ? null : ctrl.applyFilters,
                icon: const Icon(Icons.filter_alt),
                label: const Text('Apply'),
              ),
              if (!vm.loading)
                IconButton(
                  tooltip: 'Refresh',
                  onPressed: ctrl.fetch,
                  icon: const Icon(Icons.refresh),
                ),
              if (vm.loading) const Padding(
                padding: EdgeInsets.only(left: 8),
                child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Card(
              child: vm.items.isEmpty && !vm.loading
                  ? const _EmptyState()
                  : _ProjectsTable(
                      items: vm.items,
                      sortBy: vm.filter.sortBy,
                      ascending: vm.filter.ascending,
                      onSort: (c) => ref.read(projectsProvider.notifier).toggleSort(c),
                      dense: !isDesktop,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox, size: 48, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 8),
            Text('No projects found', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text('Adjust filters or add a new project.', style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

class _ProjectsTable extends StatelessWidget {
  const _ProjectsTable({
    required this.items,
    required this.sortBy,
    required this.ascending,
    required this.onSort,
    this.dense = false,
  });

  final List<Project> items;
  final ProjectSort sortBy;
  final bool ascending;
  final void Function(ProjectSort column) onSort;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final rows = items.map((p) {
      return DataRow(cells: [
        DataCell(Text(p.name)),
        DataCell(Text(p.client)),
        DataCell(_StatusBadge(p.status)),
        DataCell(Text(p.owner)),
        DataCell(Text(p.dueDate != null ? _fmtDate(p.dueDate!) : '-')),
      ]);
    }).toList();

    int? sortColumnIndex;
    switch (sortBy) {
      case ProjectSort.name: sortColumnIndex = 0; break;
      case ProjectSort.client: sortColumnIndex = 1; break;
      case ProjectSort.status: sortColumnIndex = 2; break;
      case ProjectSort.owner: sortColumnIndex = 3; break;
      case ProjectSort.dueDate: sortColumnIndex = 4; break;
    }

    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          sortColumnIndex: sortColumnIndex,
          sortAscending: ascending,
          columns: [
            DataColumn(
              label: const Text('Name'),
              onSort: (_, __) => onSort(ProjectSort.name),
            ),
            DataColumn(
              label: const Text('Client'),
              onSort: (_, __) => onSort(ProjectSort.client),
            ),
            DataColumn(
              label: const Text('Status'),
              onSort: (_, __) => onSort(ProjectSort.status),
            ),
            DataColumn(
              label: const Text('Owner'),
              onSort: (_, __) => onSort(ProjectSort.owner),
            ),
            DataColumn(
              label: const Text('Due'),
              numeric: false,
              onSort: (_, __) => onSort(ProjectSort.dueDate),
            ),
          ],
          rows: rows,
          dataRowMinHeight: dense ? 36 : null,
          dataRowMaxHeight: dense ? 44 : null,
        ),
      ),
    );
  }

  String _fmtDate(DateTime d) {
    return '\{0:04d\}-\{1:02d\}-\{2:02d\}'.format(d.year, d.month, d.day) if False else
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge(this.status);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Color bg;
    switch (status.toLowerCase()) {
      case 'approved':
        bg = Colors.green.withOpacity(0.15);
        break;
      case 'inprogress':
      case 'in progress':
        bg = Colors.blue.withOpacity(0.15);
        break;
      case 'closed':
        bg = Colors.grey.withOpacity(0.15);
        break;
      default:
        bg = Colors.orange.withOpacity(0.15);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(status, style: theme.textTheme.labelMedium),
    );
  }
}
