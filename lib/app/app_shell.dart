import 'package:flutter/material.dart';

import '../features/home/home_page.dart';
import '../features/settings/settings_page.dart';
import '../features/tools/tools_list_page.dart';
import 'routes.dart';

/// Home, Tools, Settings in a Material 3 `NavigationBar`. The three pages are
/// kept alive together, so each tab is where the user left it. A tool opens
/// full screen over the shell and back returns to the tab (no custom back
/// handling).
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          HomePage(onOpen: (entry, input) => openTool(context, entry, input)),
          ToolsListPage(onOpen: (entry, input) => openTool(context, entry, input)),
          const SettingsPage(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Home'),
          NavigationDestination(
              icon: Icon(Icons.build_outlined),
              selectedIcon: Icon(Icons.build),
              label: 'Tools'),
          NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings),
              label: 'Settings'),
        ],
      ),
    );
  }
}
