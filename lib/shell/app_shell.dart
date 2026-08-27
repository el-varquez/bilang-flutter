import 'package:flutter/material.dart';

import '../features/count/screens/count_screen.dart';
import '../features/counts/screens/counts_screen.dart';
import '../features/export/screens/export_screen.dart';
import '../features/settings/screens/settings_screen.dart';
import '../services/local_store.dart';
import '../theme/tokens.dart';

class AppShell extends StatefulWidget {
  const AppShell({
    super.key,
    required this.storage,
    this.cameraEnabled = true,
  });

  final LocalStore storage;
  final bool cameraEnabled;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final screens = <Widget>[
      CountScreen(
        storage: widget.storage,
        cameraEnabled: widget.cameraEnabled,
      ),
      const CountsScreen(),
      const ExportScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      body: SafeArea(child: screens[_tab]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (index) => setState(() => _tab = index),
        backgroundColor: Tokens.paper2,
        indicatorColor: Tokens.greenSoft,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.qr_code_scanner_outlined),
            selectedIcon: Icon(Icons.qr_code_scanner, color: Tokens.greenDeep),
            label: 'Count',
          ),
          NavigationDestination(
            icon: Icon(Icons.list_alt_outlined),
            selectedIcon: Icon(Icons.list_alt, color: Tokens.greenDeep),
            label: 'Saved Counts',
          ),
          NavigationDestination(
            icon: Icon(Icons.ios_share_outlined),
            selectedIcon: Icon(Icons.ios_share, color: Tokens.greenDeep),
            label: 'Export',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings, color: Tokens.greenDeep),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
