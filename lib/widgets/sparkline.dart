import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../models/indicator.dart';

/// Mini gráfico de tendência para os cartões da visão geral.
class Sparkline extends StatelessWidget {
  const Sparkline({super.key, required this.points, required this.color});

  final List<DataPoint> points;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final spots = [
      for (var i = 0; i < points.length; i++) FlSpot(i.toDouble(), points[i].value),
    ];
    return ExcludeSemantics(
      child: SizedBox(
        width: 96,
        height: 44,
        child: LineChart(
          LineChartData(
            gridData: const FlGridData(show: false),
            borderData: FlBorderData(show: false),
            titlesData: const FlTitlesData(show: false),
            lineTouchData: const LineTouchData(enabled: false),
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                color: color,
                barWidth: 2.5,
                isCurved: true,
                dotData: const FlDotData(show: false),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
