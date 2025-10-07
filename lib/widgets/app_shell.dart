import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../router.dart';
import '../theme.dart';

class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.child});
  final Widget child;

  int _indexForLocation(String l) {
    if (l.startsWith('/projects')) return 1;
    if (l.startsWith('/boards')) return 2;
    if (l.startsWith('/files')) return 3;
    return 0; // dashboard
    }

  void _goByIndex(BuildContext context, int i) {
    switch (i) {
      case 0:
        context.go('/dashboard');
        break;
      case 1:
        context.go('/projects');
        break;
      case 2:
        context.go('/boards');
        break;
      case 3:
        context.go('/files');
        break;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).uri.toString();
    final isDesktop = MediaQuery.sizeOf(context).width >= AppBreakpoints.desktop;
    final isTablet = MediaQuery.sizeOf(context).width >= AppBreakpoints.tablet && !isDesktop;

    final selected = _indexForLocation(location);
    final authCtrl = ref.read(authProvider.notifier);
    final user = ref.watch(authProvider).userName ?? 'User';

    final destinations = const [
      NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Dashboard'),
      NavigationDestination(icon: Icon(Icons.work_outline), selectedIcon: Icon(Icons.work), label: 'Projects'),
      NavigationDestination(icon: Icon(Icons.view_kanban_outlined), selectedIcon: Icon(Icons.view_kanban), label: 'Boards'),
      NavigationDestination(icon: Icon(Icons.folder_open), selectedIcon: Icon(Icons.folder), label: 'Files'),
    ];

    final sidebar = NavigationRail(
      selectedIndex: selected,
      onDestinationSelected: (i) => _goByIndex(context, i),
      labelType: isDesktop ? NavigationRailLabelType.selected : NavigationRailLabelType.all,
      destinations: const [
        NavigationRailDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: Text('Dashboard')),
        NavigationRailDestination(icon: Icon(Icons.work_outline), selectedIcon: Icon(Icons.work), label: Text('Projects')),
        NavigationRailDestination(icon: Icon(Icons.view_kanban_outlined), selectedIcon: Icon(Icons.view_kanban), label: Text('Boards')),
        NavigationRailDestination(icon: Icon(Icons.folder_open), selectedIcon: Icon(Icons.folder), label: Text('Files')),
      ],
      leading: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Icon(Icons.blur_on, size: 28, color: Theme.of(context).colorScheme.primary),
      ),
      trailing: Expanded(
        child: Align(
          alignment: Alignment.bottomCenter,
          child: IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout),
            onPressed: () {
              authCtrl.signOut();
              context.go('/login');
            },
          ),
        ),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text('Workflow Manager', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(width: 12),
            if (!isDesktop) // chip mic pe mobil/tablet
              Chip(label: Text(user)),
          ],
        ),
        actions: isDesktop
            ? [
                Row(
                  children: [
                    Text(user),
                    const SizedBox(width: 12),
                    CircleAvatar(
                      radius: 14,
                      child: Text(user.isNotEmpty ? user[0].toUpperCase() : '?'),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      tooltip: 'Sign out',
                      icon: const Icon(Icons.logout),
                      onPressed: () {
                        authCtrl.signOut();
                        context.go('/login');
                      },
                    ),
                  ],
                )
              ]
            : null,
      ),
      bottomNavigationBar: (!isTablet && !isDesktop)
          ? NavigationBar(
              selectedIndex: selected,
              onDestinationSelected: (i) => _goByIndex(context, i),
              destinations: destinations,
            )
          : null,
      drawer: (isTablet && selected > 3) ? const Drawer() : null,
      body: Row(
        children: [
          if (isDesktop) SizedBox(width: 84, child: sidebar),
          Expanded(
            child: ColoredBox(
              color: Theme.of(context).colorScheme.surface,
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}
