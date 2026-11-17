import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../core/utils/format.dart';
import '../models/indicator.dart';

/// Gráfico de linha: histórico, projeção tracejada e limiar de alerta.
class TrendChart extends StatelessWidget {
  const TrendChart({
    super.key,
    required this.points,
    required this.forecast,
    required this.threshold,
    required this.unit,
    this.height = 230,
  });

  final List<DataPoint> points;
  final List<double> forecast;
  final double threshold;
  final String unit;
  final double height;

  DateTime _dateAt(int index) =>
      points.last.date.add(Duration(days: index - (points.length - 1)));

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final forecastColor = AppColors.warningOf(theme.brightness);

    final history = [
      for (var i = 0; i < points.length; i++) FlSpot(i.toDouble(), points[i].value),
    ];
    final projection = <FlSpot>[
      if (forecast.isNotEmpty) history.last,
      for (var i = 0; i < forecast.length; i++)
        FlSpot((points.length + i).toDouble(), forecast[i]),
    ];

    final all = [...points.map((p) => p.value), ...forecast, threshold];
    final minV = all.reduce(math.min);
    final maxV = all.reduce(math.max);
    final pad = (maxV - minV) == 0 ? 1.0 : (maxV - minV) * 0.15;
    final lastX = (points.length + forecast.length - 1).toDouble();
    final labelStyle = theme.textTheme.bodySmall;

    final summary =
        'Gráfico de linha com ${points.length} dias de histórico e projeção de ${forecast.length} dias. '
        'Último valor ${formatNumber(points.last.value)} $unit. Limiar de alerta ${formatNumber(threshold)} $unit.';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          label: summary,
          image: true,
          child: ExcludeSemantics(
            child: SizedBox(
              height: height,
              child: LineChart(
                LineChartData(
                  minX: 0,
                  maxX: lastX,
                  minY: minV - pad,
                  maxY: maxV + pad,
                  borderData: FlBorderData(show: false),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (_) =>
                        FlLine(color: scheme.outlineVariant.withAlpha(120), strokeWidth: 1),
                  ),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          if (value == meta.min || value == meta.max) return const SizedBox.shrink();
                          return Text(value.toStringAsFixed(0), style: labelStyle);
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        interval: 7,
                        getTitlesWidget: (value, meta) {
                          final i = value.toInt();
                          if (i < 0 || i > lastX) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(formatDayMonth(_dateAt(i)), style: labelStyle),
                          );
                        },
                      ),
                    ),
                  ),
                  extraLinesData: ExtraLinesData(
                    horizontalLines: [
                      HorizontalLine(
                        y: threshold,
                        color: scheme.error,
                        strokeWidth: 2,
                        dashArray: [8, 4],
                      ),
                    ],
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: history,
                      color: scheme.primary,
                      barWidth: 3,
                      isCurved: false,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(show: true, color: scheme.primary.withAlpha(28)),
                    ),
                    if (projection.length > 1)
                      LineChartBarData(
                        spots: projection,
                        color: forecastColor,
                        barWidth: 3,
                        isCurved: false,
                        dashArray: [6, 4],
                        dotData: const FlDotData(show: false),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.xs,
          children: [
            _LegendItem(color: scheme.primary, label: 'Histórico'),
            _LegendItem(color: forecastColor, label: 'Projeção (${forecast.length} dias)'),
            _LegendItem(color: scheme.error, label: 'Limiar'),
          ],
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 14, height: 4, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
