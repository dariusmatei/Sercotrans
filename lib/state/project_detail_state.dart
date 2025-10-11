import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/projects_api.dart';
import '../api/api_client.dart';
import '../models/project.dart';

final projectsApiProvider = Provider<ProjectsApi>((ref) {
  final api = ref.watch(apiClientProvider);
  return ProjectsApi(api);
});

class ProjectDetailState {
  final Project? project;
  final bool loading;
  final bool saving;
  final String? error;
  final bool isNew;

  const ProjectDetailState({
    required this.project,
    required this.loading,
    required this.saving,
    required this.isNew,
    this.error,
  });

  ProjectDetailState copyWith({
    Project? project,
    bool? loading,
    bool? saving,
    String? error,
    bool? isNew,
  }) =>
      ProjectDetailState(
        project: project ?? this.project,
        loading: loading ?? this.loading,
        saving: saving ?? this.saving,
        isNew: isNew ?? this.isNew,
        error: error,
      );

  static const initial = ProjectDetailState(project: null, loading: false, saving: false, isNew: false);
}

final projectDetailProvider = StateNotifierProvider.family<ProjectDetailController, ProjectDetailState, String?>(
  (ref, id) {
    return ProjectDetailController(ref.watch(projectsApiProvider), id: id);
  },
);

class ProjectDetailController extends StateNotifier<ProjectDetailState> {
  final ProjectsApi _api;
  final String? id;

  ProjectDetailController(this._api, {required this.id}) : super(ProjectDetailState.initial) {
    if (id == null || id == 'new') {
      state = ProjectDetailState(
        project: const Project(id: '', name: '', client: '', status: 'Draft', owner: ''),
        loading: false,
        saving: false,
        isNew: true,
      );
    } else {
      load();
    }
  }

  Future<void> load() async {
    if (id == null) return;
    state = state.copyWith(loading: true, error: null);
    try {
      final p = await _api.getById(id!);
      state = state.copyWith(project: p, loading: false);
    } catch (e) {
      state = state.copyWith(loading: false, error: 'Nu am putut încărca proiectul');
    }
  }

  Future<bool> save({
    required String name,
    required String client,
    required String status,
    required String owner,
    DateTime? dueDate,
  }) async {
    state = state.copyWith(saving: true, error: null);
    try {
      if (state.isNew) {
        final created = await _api.create(name: name, client: client, status: status, owner: owner, dueDate: dueDate);
        state = state.copyWith(project: created, saving: false, isNew: false);
      } else {
        final updated = await _api.update(
          state.project!.copyWith(name: name, client: client, status: status, owner: owner, dueDate: dueDate),
        );
        state = state.copyWith(project: updated, saving: false);
      }
      return true;
    } catch (e) {
      state = state.copyWith(saving: false, error: 'Salvarea a eșuat');
      return false;
    }
  }
}
