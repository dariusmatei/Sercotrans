import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'widgets/app_shell.dart';
import 'screens/login/login_screen.dart';
import 'screens/projects/projects_list_screen.dart';
import 'screens/projects/project_detail_screen.dart';
import 'state/auth_state.dart';

class ForbiddenScreen extends StatelessWidget {
  const ForbiddenScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      Center(child: Text('403 — Forbidden', style: Theme.of(context).textTheme.headlineSmall));
}

bool _requiresUserRole(String location) {
  // exemplu: toate rutele din /projects cer rolul 'user'
  return location.startsWith('/projects');
}

final routerProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/dashboard',
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Navigation error')),
      body: Center(child: Text(state.error.toString())),
    ),
    redirect: (context, state) {
      final location = state.matchedLocation;
      final loggingIn = location == '/login';

      // 1) protecție autentificare
      if (!auth.isAuthenticated) return loggingIn ? null : '/login';
      if (loggingIn) return '/dashboard';

      // 2) guard pe roluri
      if (_requiresUserRole(location) && !auth.hasRole('user')) {
        return '/forbidden';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/login', name: 'login', builder: (c, s) => const LoginScreen()),
      GoRoute(path: '/forbidden', name: 'forbidden', builder: (c, s) => const ForbiddenScreen()),
      ShellRoute(
        builder: (c, s, child) => AppShell(child: child),
        routes: [
          GoRoute(path: '/dashboard', name: 'dashboard', builder: (c, s) => const _Dashboard()),
          GoRoute(path: '/projects', name: 'projects', builder: (c, s) => const ProjectsListScreen()),
          GoRoute(
            path: '/projects/new',
            name: 'project_new',
            builder: (c, s) => const ProjectDetailScreen(projectId: 'new'),
          ),
          GoRoute(
            path: '/projects/:id',
            name: 'project_detail',
            builder: (c, s) {
              final id = s.pathParameters['id'];
              return ProjectDetailScreen(projectId: id);
            },
          ),
          GoRoute(path: '/boards', name: 'boards', builder: (c, s) => const _Placeholder('Boards')),
          GoRoute(path: '/files', name: 'files', builder: (c, s) => const _Placeholder('Files')),
        ],
      ),
    ],
  );
});

class _Dashboard extends ConsumerWidget {
  const _Dashboard();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).userName ?? 'User';
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Align(
        alignment: Alignment.topLeft,
        child: Text('Welcome, ' + user + ' 👋', style: Theme.of(context).textTheme.headlineSmall),
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  final String title;
  const _Placeholder(this.title);
  @override
  Widget build(BuildContext context) => Center(child: Text(title, style: Theme.of(context).textTheme.headlineSmall));
}
