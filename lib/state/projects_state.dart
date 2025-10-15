import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/projects_api.dart';
import '../models/project.dart';
import 'auth_state.dart';

enum ProjectSort { name, client, status, owner, dueDate }

class ProjectsFilter {
  final String search;
  final String status;
  final ProjectSort sortBy;
  final bool ascending;

  const ProjectsFilter({
    this.search = '',
    this.status = '',
    this.sortBy = ProjectSort.name,
    this.ascending = true,
  });

  ProjectsFilter copyWith({
    String? search,
    String? status,
    ProjectSort? sortBy,
    bool? ascending,
  }) =>
      ProjectsFilter(
        search: search ?? this.search,
        status: status ?? this.status,
        sortBy: sortBy ?? this.sortBy,
        ascending: ascending ?? this.ascending,
      );
}

class ProjectsState {
  final List<Project> items;
  final bool loading;
  final String? error;
  final ProjectsFilter filter;

  const ProjectsState({
    required this.items,
    required this.loading,
    required this.filter,
    this.error,
  });

  ProjectsState copyWith({
    List<Project>? items,
    bool? loading,
    String? error,
    ProjectsFilter? filter,
  }) =>
      ProjectsState(
        items: items ?? this.items,
        loading: loading ?? this.loading,
        filter: filter ?? this.filter,
        error: error,
      );

  static const initial = ProjectsState(items: <Project>[], loading: false, filter: ProjectsFilter());
}

final projectsApiProvider = Provider<ProjectsApi>((ref) {
  final api = ref.watch(apiClientProvider);
  return ProjectsApi(api);
});

final projectsProvider = StateNotifierProvider<ProjectsController, ProjectsState>((ref) {
  return ProjectsController(ref.watch(projectsApiProvider));
});

class ProjectsController extends StateNotifier<ProjectsState> {
  final ProjectsApi _api;
  ProjectsController(this._api) : super(ProjectsState.initial) {
    fetch();
  }

  Future<void> fetch() async {
    state = state.copyWith(loading: true, error: null);
    try {
      final sortKey = _toSortKey(state.filter.sortBy);
      final dir = state.filter.ascending ? 'asc' : 'desc';
      final items = await _api.list(
        search: state.filter.search,
        status: state.filter.status,
        sort: sortKey,
        dir: dir,
      );
      state = state.copyWith(items: items, loading: false);
    } catch (e) {
      state = state.copyWith(loading: false, error: 'Nu am putut încărca proiectele');
    }
  }

  void setSearch(String q) {
    state = state.copyWith(filter: state.filter.copyWith(search: q));
  }

  void setStatus(String status) {
    state = state.copyWith(filter: state.filter.copyWith(status: status));
  }

  Future<void> applyFilters() => fetch();

  Future<void> toggleSort(ProjectSort column) async {
    final same = column == state.filter.sortBy;
    final nextAsc = same ? !state.filter.ascending : true;
    state = state.copyWith(filter: state.filter.copyWith(sortBy: column, ascending: nextAsc));
    await fetch();
  }

  String _toSortKey(ProjectSort s) {
    switch (s) {
      case ProjectSort.name:
        return 'name';
      case ProjectSort.client:
        return 'client';
      case ProjectSort.status:
        return 'status';
      case ProjectSort.owner:
        return 'owner';
      case ProjectSort.dueDate:
        return 'dueDate';
    }
  }
}
