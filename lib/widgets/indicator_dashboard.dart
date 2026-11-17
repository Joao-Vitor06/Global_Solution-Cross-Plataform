import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/routes.dart';
import '../core/theme/app_spacing.dart';
import '../core/utils/format.dart';
import '../domain/alert_engine.dart';
import '../models/indicator.dart';
import '../providers/settings_provider.dart';
import '../providers/territory_provider.dart';
import 'alert_tile.dart';
import 'app_card.dart';
import 'kpi_tile.dart';
import 'section_title.dart';
import 'state_views.dart';
import 'trend_chart.dart';
import 'weekly_bars.dart';

/// Painel completo de um indicador: KPIs, histórico + projeção, barras e alertas.
/// Reutilizado nas abas de "Painéis" e na tela de detalhe do indicador.
class IndicatorDashboard extends StatelessWidget {
  const IndicatorDashboard({super.key, required this.type});

  final IndicatorType type;

  @override
  Widget build(BuildContext context) {
    final territory = context.watch<TerritoryProvider>();
    final thresholds = context.watch<SettingsProvider>().thresholds;

    if (territory.status == LoadStatus.loading) return const LoadingView();
    if (territory.status == LoadStatus.error) {
      return ErrorView(
        message: territory.errorMessage ?? 'Erro inesperado.',
        onRetry: () => territory.load(),
      );
    }
    final indicator = territory.indicatorOf(type);
    if (indicator == null) {
      return const EmptyView(
        icon: Icons.insights_outlined,
        title: 'Sem dados',
        message: 'Nenhum dado disponível para este indicador.',
      );
    }

    final theme = Theme.of(context);
    final threshold = thresholds.of(type);
    final forecast = AlertEngine.forecast(indicator);
    final alerts = territory.alertsFor(type);
    final change = indicator.weeklyChangePct;
    final values = indicator.values;
    final last7 = values.length > 7 ? values.sublist(values.length - 7) : values;

    final (String, String, String) extra = switch (type) {
      IndicatorType.water => (
          'Menor valor (7 dias)',
          '${formatNumber(last7.reduce(math.min))} ${type.unit}',
          'limiar de ${formatNumber(threshold, decimals: 0)} ${type.unit}',
        ),
      IndicatorType.energy => (
          'Maior pico (7 dias)',
          '${formatNumber(last7.reduce(math.max))} ${type.unit}',
          'demanda máxima recente',
        ),
      IndicatorType.climate => (
          'Dias acima do limiar',
          '${last7.where((v) => v >= threshold).length} de ${last7.length}',
          'limiar de ${formatNumber(threshold, decimals: 0)} ${type.unit}',
        ),
      IndicatorType.air => (
          'Dias acima da referência',
          '${last7.where((v) => v >= threshold).length} de ${last7.length}',
          'referência de ${formatNumber(threshold, decimals: 0)} ${type.unit}',
        ),
      IndicatorType.waste => (
          'Total em 7 dias',
          '${formatNumber(last7.reduce((a, b) => a + b))} t',
          'volume coletado na semana',
        ),
    };

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        Text(type.title, style: theme.textTheme.titleLarge),
        const SizedBox(height: AppSpacing.sm),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: KpiTile(
                label: 'Valor atual',
                value: '${formatNumber(indicator.latest)} ${type.unit}',
                caption: 'em ${formatDayMonth(indicator.points.last.date)}',
                icon: type.icon,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: KpiTile(
                label: 'Tendência semanal',
                value: '${change >= 0 ? '+' : ''}${formatNumber(change)}%',
                caption: 'vs. 7 dias anteriores',
                icon: change > 0.5
                    ? Icons.trending_up
                    : (change < -0.5 ? Icons.trending_down : Icons.trending_flat),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: KpiTile(
                label: 'Média 7 dias',
                value: '${formatNumber(indicator.avgLast7)} ${type.unit}',
                icon: Icons.calculate_outlined,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: KpiTile(label: extra.$1, value: extra.$2, caption: extra.$3, icon: Icons.flag_outlined),
            ),
          ],
        ),
        const SectionTitle('Histórico e projeção'),
        AppCard(
          child: TrendChart(
            points: indicator.points,
            forecast: forecast,
            threshold: threshold,
            unit: type.unit,
          ),
        ),
        const SectionTitle('Últimos 7 dias'),
        AppCard(
          child: WeeklyBars(
            points: indicator.points,
            threshold: threshold,
            unit: type.unit,
            lowerIsWorse: type.lowerIsWorse,
          ),
        ),
        SectionTitle('Alertas deste indicador (${alerts.length})'),
        if (alerts.isEmpty)
          const AppCard(
            child: Row(
              children: [
                Icon(Icons.check_circle_outline),
                SizedBox(width: AppSpacing.sm),
                Expanded(child: Text('Nenhum alerta ativo para este indicador.')),
              ],
            ),
          )
        else
          for (final alert in alerts) ...[
            AlertTile(
              alert: alert,
              decision: territory.decisionOf(alert.id),
              onTap: () => Navigator.of(context).pushNamed(Routes.alert, arguments: alert.id),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        const SectionTitle('Fonte dos dados'),
        AppCard(child: Text(_sourceNote(indicator), style: theme.textTheme.bodyMedium)),
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }

  static String _sourceNote(Indicator ind) {
    final when = formatDateTime(ind.fetchedAt);
    return switch (ind.source) {
      DataSource.synthetic =>
        'Dados SINTÉTICOS gerados para fins acadêmicos (API simulada). Não representam medições reais.',
      DataSource.sabesp =>
        'Dados REAIS do Portal dos Mananciais da Sabesp (sistema Alto Tietê, zona leste), consultados em $when.',
      DataSource.openMeteo => ind.type == IndicatorType.air
          ? 'Dados REAIS da Open-Meteo Air Quality (modelo CAMS; média diária de PM2,5), consultados em $when. Baixa resolução espacial.'
          : 'Dados REAIS da API Open-Meteo, consultados em $when. O dia atual pode ser previsão do modelo.',
      DataSource.cache =>
        'Sem conexão ou fonte indisponível: exibindo o último cache de dados reais salvo em $when.',
    };
  }
}
