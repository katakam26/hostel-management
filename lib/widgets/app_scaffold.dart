import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';

/// One navigation destination in a role shell.
class NavItem {
  final String label;
  final IconData icon;
  final Widget page;
  const NavItem({required this.label, required this.icon, required this.page});
}

/// Shared shell with a responsive nav (NavigationRail on wide screens,
/// NavigationBar on narrow) plus a logout action. Each role passes its own
/// list of [NavItem]s.
class AppShellScaffold extends StatefulWidget {
  final String title;
  final List<NavItem> items;

  const AppShellScaffold({super.key, required this.title, required this.items});

  @override
  State<AppShellScaffold> createState() => _AppShellScaffoldState();
}

class _AppShellScaffoldState extends State<AppShellScaffold> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 800;
    final items = widget.items;
    final current = items[_index];
    final auth = context.read<AuthService>();

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.title} · ${current.label}'),
        actions: [
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout),
            onPressed: () => auth.logout(),
          ),
        ],
      ),
      body: Row(
        children: [
          if (wide)
            NavigationRail(
              selectedIndex: _index,
              labelType: NavigationRailLabelType.all,
              onDestinationSelected: (i) => setState(() => _index = i),
              destinations: [
                for (final item in items)
                  NavigationRailDestination(
                    icon: Icon(item.icon),
                    label: Text(item.label),
                  ),
              ],
            ),
          if (wide) const VerticalDivider(width: 1),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: current.page,
            ),
          ),
        ],
      ),
      bottomNavigationBar: wide
          ? null
          : NavigationBar(
              selectedIndex: _index,
              onDestinationSelected: (i) => setState(() => _index = i),
              destinations: [
                for (final item in items)
                  NavigationDestination(
                    icon: Icon(item.icon),
                    label: item.label,
                  ),
              ],
            ),
    );
  }
}
