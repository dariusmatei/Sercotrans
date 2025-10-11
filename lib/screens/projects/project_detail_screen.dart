import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../state/project_detail_state.dart';
import '../../models/project.dart';

class ProjectDetailScreen extends ConsumerStatefulWidget {
  const ProjectDetailScreen({super.key, required this.projectId});
  final String? projectId;

  @override
  ConsumerState<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends ConsumerState<ProjectDetailScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _client = TextEditingController();
  final _owner = TextEditingController();
  String _status = 'Draft';
  DateTime? _due;

  @override
  void initState() {
    super.initState();
    // init values will be set in build when state loads
  }

  @override
  void dispose() {
    _name.dispose();
    _client.dispose();
    _owner.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(projectDetailProvider(widget.projectId));
    final ctrl = ref.read(projectDetailProvider(widget.projectId).notifier);

    if (vm.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final p = vm.project ?? const Project(id: '', name: '', client: '', status: 'Draft', owner: '');
    _name.value = TextEditingValue(text: p.name);
    _client.value = TextEditingValue(text: p.client);
    _owner.value = TextEditingValue(text: p.owner);
    _status = p.status;
    _due = p.dueDate;

    return Scaffold(
      appBar: AppBar(
        title: Text(vm.isNew ? 'New Project' : 'Project: ${p.name.isEmpty ? p.id : p.name}'),
        actions: [
          TextButton.icon(
            onPressed: vm.saving
                ? null
                : () async {
                    if (_form.currentState!.validate()) {
                      final ok = await ctrl.save(
                        name: _name.text.trim(),
                        client: _client.text.trim(),
                        status: _status,
                        owner: _owner.text.trim(),
                        dueDate: _due,
                      );
                      if (ok && mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved')));
                        if (vm.isNew) context.go('/projects'); // back to list after create
                      }
                    }
                  },
            icon: const Icon(Icons.save),
            label: vm.saving ? const Text('Saving...') : const Text('Save'),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 860),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _name,
                          decoration: const InputDecoration(labelText: 'Name'),
                          validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _client,
                          decoration: const InputDecoration(labelText: 'Client'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _status.isEmpty ? 'Draft' : _status,
                          items: const [
                            DropdownMenuItem(value: 'Draft', child: Text('Draft')),
                            DropdownMenuItem(value: 'InProgress', child: Text('In progress')),
                            DropdownMenuItem(value: 'Approved', child: Text('Approved')),
                            DropdownMenuItem(value: 'Closed', child: Text('Closed')),
                          ],
                          decoration: const InputDecoration(labelText: 'Status'),
                          onChanged: (v) => setState(() => _status = v ?? 'Draft'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _owner,
                          decoration: const InputDecoration(labelText: 'Owner'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: InputDecorator(
                          decoration: const InputDecoration(labelText: 'Due date'),
                          child: Row(
                            children: [
                              Text(_due != null ? _fmtDate(_due!) : '-'),
                              const Spacer(),
                              IconButton(
                                icon: const Icon(Icons.date_range),
                                onPressed: () async {
                                  final now = DateTime.now();
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: _due ?? now,
                                    firstDate: DateTime(now.year - 5),
                                    lastDate: DateTime(now.year + 5),
                                  );
                                  if (picked != null) setState(() => _due = picked);
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (vm.error != null) ...[
                    const SizedBox(height: 12),
                    Text(vm.error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _fmtDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
