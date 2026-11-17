import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_spacing.dart';
import '../core/utils/format.dart';
import '../models/alert_model.dart';
import '../models/indicator.dart';
import '../providers/territory_provider.dart';
import '../widgets/app_card.dart';
import '../widgets/confidence_bar.dart';
import '../widgets/human_decision_banner.dart';
import '../widgets/section_title.dart';
import '../widgets/severity_chip.dart';
import '../widgets/state_views.dart';

/// Detalhe do alerta: evidência, confiança, limitações e decisão humana.
class AlertDetailScreen extends StatelessWidget {
  const AlertDetailScreen({super.key, required this.alertId});

  final String alertId;

  @override
  Widget build(BuildContext context) {
    final territory = context.watch<TerritoryProvider>();
    final alert = territory.alertById(alertId);

    return Scaffold(
      appBar: AppBar(title: const Text('Detalhe do alerta')),
      body: alert == null
          ? const EmptyView(
              icon: Icons.search_off,
              title: 'Alerta não encontrado',
              message: 'Este alerta não está mais ativo, pois os dados ou os limiares mudaram.',
            )
          : _AlertBody(alert: alert, decision: territory.decisionOf(alert.id)),
    );
  }
}

class _AlertBody extends StatelessWidget {
  const _AlertBody({required this.alert, required this.decision});

  final TerritoryAlert alert;
  final AlertDecision decision;

  Future<void> _decide(BuildContext context, AlertDecision value) async {
    final messenger = ScaffoldMessenger.of(context);
    await context.read<TerritoryProvider>().setDecision(alert.id, value);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('Decisão registrada: ${value.label}.')));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        Align(alignment: Alignment.centerLeft, child: SeverityChip(alert.severity)),
        const SizedBox(height: AppSpacing.sm),
        Semantics(header: true, child: Text(alert.title, style: theme.textTheme.titleLarge)),
        const SizedBox(height: AppSpacing.xs),
        Text(alert.summary, style: theme.textTheme.bodyLarge),
        Text('Gerado em ${formatDateTime(alert.createdAt)}', style: theme.textTheme.bodySmall),
        const SizedBox(height: AppSpacing.md),
        const HumanDecisionBanner(),
        const SectionTitle('Em linguagem simples'),
        AppCard(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.record_voice_over_outlined, color: theme.colorScheme.primary),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: Text(alert.plainLanguage, style: theme.textTheme.bodyLarge)),
            ],
          ),
        ),
        const SectionTitle('Justificativa (evidências)'),
        AppCard(child: _BulletList(items: alert.evidence, icon: Icons.analytics_outlined)),
        const SectionTitle('Nível de confiança'),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ConfidenceBar(confidence: alert.confidence, label: alert.confidenceLabel),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'A confiança combina o ajuste do modelo (r²), a quantidade de dados e a origem da fonte. Valores baixos indicam que a previsão não deve ser usada sozinha.',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
        const SectionTitle('Limitações e vieses'),
        AppCard(child: _BulletList(items: alert.limitations, icon: Icons.warning_amber_rounded)),
        const SectionTitle('Sugestão para análise humana'),
        AppCard(
          child: Text(alert.indicatorType.recommendation, style: theme.textTheme.bodyLarge),
        ),
        const SectionTitle('Decisão do gestor'),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Situação: ${decision.label}', style: theme.textTheme.titleMedium),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  FilledButton.icon(
                    onPressed: () => _decide(context, AlertDecision.acknowledged),
                    icon: const Icon(Icons.visibility_outlined),
                    label: const Text('Reconhecer'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _decide(context, AlertDecision.forwarded),
                    icon: const Icon(Icons.forward_to_inbox_outlined),
                    label: const Text('Encaminhar'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _decide(context, AlertDecision.dismissed),
                    icon: const Icon(Icons.close),
                    label: const Text('Descartar'),
                  ),
                  if (decision != AlertDecision.pending)
                    TextButton.icon(
                      onPressed: () => _decide(context, AlertDecision.pending),
                      icon: const Icon(Icons.undo),
                      label: const Text('Desfazer'),
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }
}

class _BulletList extends StatelessWidget {
  const _BulletList({required this.items, required this.icon});

  final List<String> items;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final item in items)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: Text(item)),
              ],
            ),
          ),
      ],
    );
  }
}
