import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'widgets/app_shell.dart';

/// --- Auth state (simplu) ----------------------------------------------------

class AuthState {
  final bool isAuthenticated;
  final String? userName;

  const AuthState({required this.isAuthenticated, this.userName});

  AuthState copyWith({bool? isAuthenticated, String? userName}) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      userName: userName ?? this.userName,
    );
  }
}

class AuthController extends StateNotifier<AuthState> {
  AuthController() : super(const AuthState(isAuthenticated: false));

  Future<void> signIn({required String email, required String password}) async {
    // TODO: Integrare cu API real; aici doar simulăm succesul.
    state = AuthState(isAuthenticated: true, userName: email.split('@').first);
  }

  void signOut() => state = const AuthState(isAuthenticated: false);
}

final authProvider = StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController();
});

/// --- Router + redirect logic ------------------------------------------------

final routerProvider = Provider<GoRouter>((ref) {
  // Observăm auth; orice schimbare recreează routerul (simplu și robust).
  final auth = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/dashboard',
    redirect: (context, state) {
      final bool loggingIn = state.matchedLocation == '/login';
      if (!auth.isAuthenticated) {
        return loggingIn ? null : '/login';
      }
      if (loggingIn) return '/dashboard';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const _LoginScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            name: 'dashboard',
            builder: (context, state) => const _DashboardScreen(),
          ),
          GoRoute(
            path: '/projects',
            name: 'projects',
            builder: (context, state) => const _PlaceholderScreen(title: 'Projects'),
          ),
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

/// --- Ecrane temporare (MVP scaffolding) -------------------------------------

class _LoginScreen extends ConsumerStatefulWidget {
  const _LoginScreen();
  @override
  ConsumerState<_LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<_LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _pass = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _form,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Sign in', style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _email,
                      decoration: const InputDecoration(labelText: 'Email'),
                      validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _pass,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'Password'),
                      validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () async {
                          if (_form.currentState!.validate()) {
                            await ref.read(authProvider.notifier).signIn(
                              email: _email.text.trim(),
                              password: _pass.text,
                            );
                            if (context.mounted) context.go('/dashboard');
                          }
                        },
                        child: const Text('Continue'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DashboardScreen extends ConsumerWidget {
  const _DashboardScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).userName ?? 'User';
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ListView(
        children: [
          Text('Welcome, $user 👋', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: const [
              _KpiCard(title: 'Active Projects', value: '12'),
              _KpiCard(title: 'Overdue Tasks', value: '5'),
              _KpiCard(title: 'Files Updated', value: '27'),
            ],
          ),
          const SizedBox(height: 24),
          Text('Getting started', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            'Use the sidebar to access Projects, Boards and Files. '
            'This is the MVP scaffold — connect the real API next.',
          ),
        ],
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({required this.title, required this.value});
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      height: 120,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.labelLarge),
              const Spacer(),
              Text(value, style: Theme.of(context).textTheme.headlineMedium),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlaceholderScreen extends StatelessWidget {
  const _PlaceholderScreen({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(title, style: Theme.of(context).textTheme.headlineSmall),
    );
  }
}
