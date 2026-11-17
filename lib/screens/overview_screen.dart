import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/routes.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../core/utils/format.dart';
import '../domain/alert_engine.dart';
import '../models/alert_model.dart';
import '../models/social_benefit.dart';
import '../providers/occurrences_provider.dart';
import '../providers/territory_provider.dart';
import '../widgets/app_card.dart';
import '../widgets/human_decision_banner.dart';
import '../widgets/indicator_summary_card.dart';
import '../widgets/kpi_tile.dart';
import '../widgets/section_title.dart';
import '../widgets/state_views.dart';

/// Visão geral do território: resumo de alertas, indicadores e benefício social.
class OverviewScreen extends StatelessWidget {
  const OverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final territory = context.watch<TerritoryProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('TerraSense'),
        actions: [
          IconButton(
            tooltip: 'Ajustes e privacidade',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.of(context).pushNamed(Routes.settings),
          ),
          IconButton(
            tooltip: 'Atualizar dados',
            icon: const Icon(Icons.refresh),
            onPressed: territory.status == LoadStatus.loading ? null : () => territory.load(),
          ),
        ],
      ),
      body: switch (territory.status) {
        LoadStatus.loading => const LoadingView(),
        LoadStatus.error => ErrorView(
            message: territory.errorMessage ?? 'Erro inesperado.',
            onRetry: () => territory.load(),
          ),
        LoadStatus.ready => _OverviewContent(territory: territory),
      },
    );
  }
}

class _OverviewContent extends StatelessWidget {
  const _OverviewContent({required this.territory});

  final TerritoryProvider territory;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final alerts = territory.alerts;
    int count(AlertSeverity s) => alerts.where((a) => a.severity == s).length;
    final occurrences = context.watch<OccurrencesProvider>().count;
    final benefit = SocialBenefit.compute(
      alerts: alerts,
      decisions: territory.decisions,
      occurrenceCount: occurrences,
      zones: territory.zones,
      horizonDays: AlertEngine.horizonDays,
    );

    return RefreshIndicator(
      onRefresh: territory.load,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Text('Itaquera, São Paulo (SP)', style: theme.textTheme.headlineSmall),
          if (territory.lastUpdated != null)
            Text(
              'Atualizado em ${formatDateTime(territory.lastUpdated!)}',
              style: theme.textTheme.bodySmall,
            ),
          const SizedBox(height: AppSpacing.md),
          const HumanDecisionBanner(compact: true),
          for (final notice in territory.notices) ...[
            const SizedBox(height: AppSpacing.sm),
            _NoticeBanner(message: notice),
          ],
          const SectionTitle('Alertas ativos'),
          Row(
            children: [
              Expanded(
                child: KpiTile(
                  label: 'Críticos',
                  value: '${count(AlertSeverity.critical)}',
                  icon: Icons.error_outline,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: KpiTile(
                  label: 'Atenção',
                  value: '${count(AlertSeverity.warning)}',
                  icon: Icons.warning_amber_rounded,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: KpiTile(
                  label: 'Informativos',
                  value: '${count(AlertSeverity.info)}',
                  icon: Icons.info_outline,
                ),
              ),
            ],
          ),
          const SectionTitle('Indicadores do território'),
          Text(
            '${territory.realIndicatorCount} de ${territory.indicators.length} indicadores com dados reais (Sabesp e Open-Meteo); os demais são sintéticos.',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final indicator in territory.indicators) ...[
            IndicatorSummaryCard(
              indicator: indicator,
              alertCount: territory.alertsFor(indicator.type).length,
              onTap: () => Navigator.of(context).pushNamed(Routes.indicator, arguments: indicator.type),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          const SectionTitle('Benefício social'),
          _SocialBenefitCard(benefit: benefit),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}

class _NoticeBanner extends StatelessWidget {
  const _NoticeBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final color = AppColors.warningOf(Theme.of(context).brightness);
    return Semantics(
      liveRegion: true,
      container: true,
      label: message,
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: color.soft(0.12),
          borderRadius: BorderRadius.circular(AppSpacing.radius),
          border: Border.all(color: color),
        ),
        child: Row(
          children: [
            Icon(Icons.cloud_off_outlined, color: color),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }
}

class _SocialBenefitCard extends StatelessWidget {
  const _SocialBenefitCard({required this.benefit});

  final SocialBenefit benefit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Como a análise preditiva se traduz em impacto para a comunidade:',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          _BenefitRow(
            icon: Icons.timer_outlined,
            value: benefit.leadTimeDays > 0 ? 'até ${benefit.leadTimeDays} dias' : 'sem alerta preditivo',
            label: 'de antecedência para agir antes do problema',
          ),
          _BenefitRow(
            icon: Icons.map_outlined,
            value: '${benefit.zonesInAttention} de ${benefit.zonesMonitored}',
            label: 'regiões monitoradas em atenção (calor ou ar acima dos limiares)',
          ),
          _BenefitRow(
            icon: Icons.fact_check_outlined,
            value: '${formatNumber(benefit.reviewedPct, decimals: 0)}%',
            label: 'dos alertas já analisados por uma pessoa',
          ),
          _BenefitRow(
            icon: Icons.groups_outlined,
            value: '${benefit.occurrences}',
            label: 'ocorrências registradas pela comunidade',
          ),
        ],
      ),
    );
  }
}

class _BenefitRow extends StatelessWidget {
  const _BenefitRow({required this.icon, required this.value, required this.label});

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Semantics(
        container: true,
        label: '$value $label',
        excludeSemantics: true,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: theme.colorScheme.primary),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: '$value ', style: theme.textTheme.titleMedium),
                    TextSpan(text: label, style: theme.textTheme.bodyMedium),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
