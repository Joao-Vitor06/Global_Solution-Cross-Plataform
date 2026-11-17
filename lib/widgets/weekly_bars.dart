import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../core/utils/format.dart';
import '../models/indicator.dart';

/// Barras dos últimos 7 dias; barras acima do limiar ficam destacadas.
class WeeklyBars extends StatelessWidget {
  const WeeklyBars({
    super.key,
    required this.points,
    required this.threshold,
    required this.unit,
    this.lowerIsWorse = false,
  });

  final List<DataPoint> points;
  final double threshold;
  final String unit;
  final bool lowerIsWorse;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final last = points.length > 7 ? points.sublist(points.length - 7) : points;
    final maxV = last.map((p) => p.value).reduce(math.max);

    final label = 'Gráfico de barras dos últimos ${last.length} dias. '
        'Maior valor: ${formatNumber(maxV)} $unit.';

    return Semantics(
      label: label,
      image: true,
      child: ExcludeSemantics(
        child: SizedBox(
          height: 160,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxV * 1.15,
              minY: 0,
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    getTitlesWidget: (value, meta) {
                      final i = value.toInt();
                      if (i < 0 || i >= last.length) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(formatDayMonth(last[i].date), style: theme.textTheme.bodySmall),
                      );
                    },
                  ),
                ),
              ),
              barGroups: [
                for (var i = 0; i < last.length; i++)
                  BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: last[i].value,
                        width: 16,
                        color: (lowerIsWorse ? last[i].value <= threshold : last[i].value >= threshold)
                            ? scheme.error
                            : scheme.primary,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
