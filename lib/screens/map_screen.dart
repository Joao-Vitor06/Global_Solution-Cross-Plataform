import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../core/utils/format.dart';
import '../models/zone.dart';
import '../providers/occurrences_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/territory_provider.dart';
import '../models/indicator.dart';
import '../widgets/app_card.dart';
import '../widgets/human_decision_banner.dart';
import '../widgets/section_title.dart';
import '../widgets/state_views.dart';

Color zoneColor(BuildContext context, ZoneStatus status) {
  final b = Theme.of(context).brightness;
  return switch (status) {
    ZoneStatus.unknown => Theme.of(context).colorScheme.outline,
    ZoneStatus.ok => AppColors.okOf(b),
    ZoneStatus.attention => AppColors.warningOf(b),
    ZoneStatus.alert => AppColors.criticalOf(b),
  };
}

IconData zoneIcon(ZoneStatus status) => switch (status) {
      ZoneStatus.unknown => Icons.help_outline,
      ZoneStatus.ok => Icons.check_circle,
      ZoneStatus.attention => Icons.warning_amber_rounded,
      ZoneStatus.alert => Icons.error,
    };

/// Mapa de São Paulo com a situação de cada região (clima e ar reais, Open-Meteo)
/// e uma lista equivalente abaixo, acessível para leitores de tela.
class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final territory = context.watch<TerritoryProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Mapa do território')),
      body: switch (territory.status) {
        LoadStatus.loading => const LoadingView(),
        LoadStatus.error => ErrorView(
            message: territory.errorMessage ?? 'Erro inesperado.',
            onRetry: () => territory.load(),
          ),
        LoadStatus.ready => _MapContent(zones: territory.zones),
      },
    );
  }
}

class _MapContent extends StatelessWidget {
  const _MapContent({required this.zones});

  final List<ZoneReading> zones;

  void _showDetails(BuildContext context, ZoneReading reading) {
    final thresholds = context.read<SettingsProvider>().thresholds;
    final occurrences = context.read<OccurrencesProvider>().countInZone(reading.zone.id);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => _ZoneSheet(
        reading: reading,
        occurrences: occurrences,
        tempThreshold: thresholds.of(IndicatorType.climate),
        airThreshold: thresholds.of(IndicatorType.air),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final occurrences = context.watch<OccurrencesProvider>();

    final markers = [
      for (final r in zones)
        Marker(
          point: r.zone.point,
          width: 56,
          height: 56,
          child: Semantics(
            button: true,
            label: '${r.zone.name}: ${r.status.label}. Toque para ver detalhes.',
            child: GestureDetector(
              onTap: () => _showDetails(context, r),
              child: Container(
                decoration: BoxDecoration(
                  color: zoneColor(context, r.status),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: const [BoxShadow(blurRadius: 6, color: Colors.black38)],
                ),
                child: Icon(zoneIcon(r.status), color: Colors.white),
              ),
            ),
          ),
        ),
    ];

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        const HumanDecisionBanner(compact: true),
        const SizedBox(height: AppSpacing.md),
        Semantics(
          label:
              'Mapa de São Paulo com ${zones.length} regiões monitoradas. A lista abaixo traz as mesmas informações em texto.',
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radius),
            child: SizedBox(
              height: 340,
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: const LatLng(-23.60, -46.60),
                  initialZoom: 10.5,
                  minZoom: 8,
                  maxZoom: 16,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.drag | InteractiveFlag.pinchZoom | InteractiveFlag.doubleTapZoom,
                  ),
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'br.com.fiap.territory_insights',
                  ),
                  MarkerLayer(markers: markers),
                  const RichAttributionWidget(
                    attributions: [TextSourceAttribution('© colaboradores do OpenStreetMap')],
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.xs,
          children: [
            for (final s in ZoneStatus.values) _Legend(status: s),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Sem internet o mapa-base pode não carregar, mas as regiões continuam listadas abaixo.',
          style: theme.textTheme.bodySmall,
        ),
        const SectionTitle('Regiões monitoradas'),
        for (final r in zones) ...[
          AppCard(
            onTap: () => _showDetails(context, r),
            accent: zoneColor(context, r.status),
            semanticLabel:
                '${r.zone.name}. ${r.status.label}. Temperatura máxima ${r.tempMax == null ? 'sem dado' : '${formatNumber(r.tempMax!)} graus'}. PM2,5 ${r.pm25 == null ? 'sem dado' : '${formatNumber(r.pm25!)} microgramas por metro cúbico'}. ${occurrences.countInZone(r.zone.id)} ocorrências. Toque para detalhes.',
            child: Row(
              children: [
                Icon(zoneIcon(r.status), color: zoneColor(context, r.status)),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(r.zone.name, style: theme.textTheme.titleMedium),
                      Text(
                        '${r.status.label} • ${r.tempMax == null ? '--' : '${formatNumber(r.tempMax!)} °C'} • PM2,5 ${r.pm25 == null ? '--' : formatNumber(r.pm25!)}',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.status});

  final ZoneStatus status;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(zoneIcon(status), size: 16, color: zoneColor(context, status)),
        const SizedBox(width: 4),
        Text(status.label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _ZoneSheet extends StatelessWidget {
  const _ZoneSheet({
    required this.reading,
    required this.occurrences,
    required this.tempThreshold,
    required this.airThreshold,
  });

  final ZoneReading reading;
  final int occurrences;
  final double tempThreshold;
  final double airThreshold;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = zoneColor(context, reading.status);
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(zoneIcon(reading.status), color: color),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: Text(reading.zone.name, style: theme.textTheme.titleLarge)),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text('Situação: ${reading.status.label}', style: theme.textTheme.titleSmall?.copyWith(color: color)),
            const SizedBox(height: AppSpacing.md),
            _Line(
              icon: Icons.thermostat_outlined,
              text: reading.tempMax == null
                  ? 'Temperatura máxima: sem dado'
                  : 'Temperatura máxima: ${formatNumber(reading.tempMax!)} °C (limiar ${formatNumber(tempThreshold, decimals: 0)} °C)',
            ),
            _Line(
              icon: Icons.air,
              text: reading.pm25 == null
                  ? 'PM2,5: sem dado'
                  : 'PM2,5 (média do dia): ${formatNumber(reading.pm25!)} µg/m³ (referência ${formatNumber(airThreshold, decimals: 0)})',
            ),
            _Line(icon: Icons.campaign_outlined, text: 'Ocorrências da comunidade nesta região: $occurrences'),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Fonte: Open-Meteo (dados reais de modelo, resolução limitada). Não substitui estações oficiais. A decisão final é sempre humana.',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
