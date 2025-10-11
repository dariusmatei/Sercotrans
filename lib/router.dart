import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// păstrăm shell-ul existent
import 'widgets/app_shell.dart';

// S1-F2: ecranul de login + state de auth
import 'screens/login/login_screen.dart';
import 'state/auth_state.dart';

// S1-F3: lista reală de proiecte
import 'screens/projects/projects_list_screen.dart';

/// Router global — protejat de auth; se recreează automat când se schimbă auth state.
final routerProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authProvider);

  return GoRouter(
    // dacă în proiectul tău era altă rootă inițială, păstreaz-o
    initialLocation: '/dashboard',
    // dacă aveai observers/redirecturi suplimentare, adaugă-le aici
    redirect: (context, state) {
      final loggingIn = state.matchedLocation == '/login';
      if (!auth.isAuthenticated) return loggingIn ? null : '/login';
      if (loggingIn) return '/dashboard';
      return null;
    },
    routes: [
      // --- public
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),

      // --- private (wrap în AppShell)
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            name: 'dashboard',
            builder: (context, state) => const _DashboardScreen(),
          ),
          // S1-F3 — listă proiecte (table) + sort/filter basic
          GoRoute(
            path: '/projects',
            name: 'projects',
            builder: (context, state) => const ProjectsListScreen(),
          ),
          // lăsăm placeholder-ele existente până legăm ecranele reale
          GoRoute(
            path: '/boards',
            name: 'boards',
            builder: (context, state) => const _PlaceholderScreen(title: 'Boards'),
          ),
          GoRoute(
            path: '/files',
            name: 'files',
            builder: (context, state) => const _PlaceholderScreen(title: 'Files'),
          ),
        ],
      ),
    ],
  );
});

/// --- Ecrane simple „la pachet” (păstrăm stilul din router-ul vechi) ---------

class _DashboardScreen extends ConsumerWidget {
  const _DashboardScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).userName ?? 'User';
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Align(
        alignment: Alignment.topLeft,
        child: Text('Welcome, $user 👋', style: Theme.of(context).textTheme.headlineSmall),
      ),
    );
  }
}

class _PlaceholderScreen extends StatelessWidget {
  const _PlaceholderScreen({required this.title, super.key});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(title, style: Theme.of(context).textTheme.headlineSmall),
    );
  }
}
