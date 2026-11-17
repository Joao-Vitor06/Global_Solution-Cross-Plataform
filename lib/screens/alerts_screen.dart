import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/routes.dart';
import '../core/theme/app_spacing.dart';
import '../models/alert_model.dart';
import '../providers/territory_provider.dart';
import '../widgets/alert_tile.dart';
import '../widgets/human_decision_banner.dart';
import '../widgets/state_views.dart';

/// Lista de alertas preditivos, com filtro local de pendentes.
class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  bool _onlyPending = false; // estado local da tela

  @override
  Widget build(BuildContext context) {
    final territory = context.watch<TerritoryProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Alertas preditivos')),
      body: switch (territory.status) {
        LoadStatus.loading => const LoadingView(),
        LoadStatus.error => ErrorView(
            message: territory.errorMessage ?? 'Erro inesperado.',
            onRetry: () => territory.load(),
          ),
        LoadStatus.ready => _buildList(territory),
      },
    );
  }

  Widget _buildList(TerritoryProvider territory) {
    final all = territory.alerts;
    final shown = _onlyPending
        ? all.where((a) => territory.decisionOf(a.id) == AlertDecision.pending).toList()
        : all;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        const HumanDecisionBanner(),
        const SizedBox(height: AppSpacing.md),
        Align(
          alignment: Alignment.centerLeft,
          child: FilterChip(
            label: const Text('Somente pendentes'),
            selected: _onlyPending,
            onSelected: (v) => setState(() => _onlyPending = v),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (shown.isEmpty)
          SizedBox(
            height: 300,
            child: EmptyView(
              icon: Icons.verified_outlined,
              title: all.isEmpty ? 'Nenhum alerta ativo' : 'Nada pendente',
              message: all.isEmpty
                  ? 'Os indicadores estão dentro dos limiares configurados.'
                  : 'Todos os alertas já foram analisados por uma pessoa.',
            ),
          )
        else
          for (final alert in shown) ...[
            AlertTile(
              alert: alert,
              decision: territory.decisionOf(alert.id),
              onTap: () => Navigator.of(context).pushNamed(Routes.alert, arguments: alert.id),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
      ],
    );
  }
}
