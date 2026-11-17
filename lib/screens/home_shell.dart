import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/territory_provider.dart';
import 'alerts_screen.dart';
import 'map_screen.dart';
import 'occurrences_screen.dart';
import 'overview_screen.dart';
import 'panels_screen.dart';

/// Estrutura principal com navegação inferior (5 seções).
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  static const _pages = <Widget>[
    OverviewScreen(),
    PanelsScreen(),
    MapScreen(),
    AlertsScreen(),
    OccurrencesScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final pending = context.select<TerritoryProvider, int>((p) => p.pendingCount);
    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Visão geral',
          ),
          const NavigationDestination(
            icon: Icon(Icons.insights_outlined),
            selectedIcon: Icon(Icons.insights),
            label: 'Painéis',
          ),
          const NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: 'Mapa',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: pending > 0,
              label: Text('$pending'),
              child: const Icon(Icons.notifications_outlined),
            ),
            selectedIcon: Badge(
              isLabelVisible: pending > 0,
              label: Text('$pending'),
              child: const Icon(Icons.notifications),
            ),
            label: 'Alertas',
          ),
          const NavigationDestination(
            icon: Icon(Icons.campaign_outlined),
            selectedIcon: Icon(Icons.campaign),
            label: 'Ocorrências',
          ),
        ],
      ),
    );
  }
}
