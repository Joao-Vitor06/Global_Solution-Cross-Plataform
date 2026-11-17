import 'package:flutter/material.dart';

import '../models/indicator.dart';
import '../widgets/indicator_dashboard.dart';

/// Cinco dashboards territoriais (água, energia, clima, ar, resíduos) em abas.
class PanelsScreen extends StatelessWidget {
  const PanelsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: IndicatorType.values.length,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Painéis territoriais'),
          bottom: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              for (final t in IndicatorType.values) Tab(icon: Icon(t.icon), text: t.label),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            for (final t in IndicatorType.values) IndicatorDashboard(type: t),
          ],
        ),
      ),
    );
  }
}
