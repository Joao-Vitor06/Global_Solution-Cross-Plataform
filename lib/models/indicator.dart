import 'dart:math' as math;

import 'package:flutter/material.dart';

enum IndicatorType { water, energy, climate, air, waste }

/// Origem dos dados de um indicador.
enum DataSource { synthetic, openMeteo, sabesp, cache }

extension IndicatorTypeX on IndicatorType {
  String get label => switch (this) {
        IndicatorType.water => 'Água',
        IndicatorType.energy => 'Energia',
        IndicatorType.climate => 'Clima',
        IndicatorType.air => 'Ar',
        IndicatorType.waste => 'Resíduos',
      };

  String get title => switch (this) {
        IndicatorType.water => 'Volume dos mananciais (Alto Tietê)',
        IndicatorType.energy => 'Consumo de energia',
        IndicatorType.climate => 'Temperatura máxima diária',
        IndicatorType.air => 'Qualidade do ar (PM2,5)',
        IndicatorType.waste => 'Coleta de resíduos',
      };

  String get unit => switch (this) {
        IndicatorType.water => '%',
        IndicatorType.energy => 'MWh/dia',
        IndicatorType.climate => '°C',
        IndicatorType.air => 'µg/m³',
        IndicatorType.waste => 't/dia',
      };

  IconData get icon => switch (this) {
        IndicatorType.water => Icons.water_drop_outlined,
        IndicatorType.energy => Icons.bolt_outlined,
        IndicatorType.climate => Icons.thermostat_outlined,
        IndicatorType.air => Icons.air,
        IndicatorType.waste => Icons.recycling_outlined,
      };

  /// Para o volume dos mananciais, valores MENORES são piores.
  bool get lowerIsWorse => this == IndicatorType.water;

  double get defaultThreshold => switch (this) {
        IndicatorType.water => 40,
        IndicatorType.energy => 400,
        IndicatorType.climate => 33,
        IndicatorType.air => 25,
        IndicatorType.waste => 55,
      };

  String get thresholdHint => lowerIsWorse
      ? 'Alerta quando o valor ficar igual ou abaixo deste limiar.'
      : 'Alerta quando o valor ficar igual ou acima deste limiar.';

  String get recommendation => switch (this) {
        IndicatorType.water =>
          'Acompanhar a evolução do volume com a operadora, planejar comunicação de uso consciente e avaliar medidas de gestão da demanda antes de qualquer restrição.',
        IndicatorType.energy =>
          'Avaliar picos de demanda da região e comunicar horários de menor consumo à população.',
        IndicatorType.climate =>
          'Preparar comunicação de calor extremo e reforçar pontos de hidratação e atendimento a grupos vulneráveis.',
        IndicatorType.air =>
          'Divulgar orientações de saúde (evitar exercício intenso ao ar livre, atenção a crianças, idosos e pessoas com doenças respiratórias) e confirmar com as estações da CETESB.',
        IndicatorType.waste =>
          'Revisar rotas e frequência de coleta e avaliar pontos de descarte irregular.',
      };
}

class DataPoint {
  const DataPoint(this.date, this.value);

  final DateTime date;
  final double value;

  Map<String, dynamic> toJson() => {'d': date.toIso8601String(), 'v': value};

  factory DataPoint.fromJson(Map<String, dynamic> json) =>
      DataPoint(DateTime.parse(json['d'] as String), (json['v'] as num).toDouble());
}

/// Série histórica de um indicador do território.
class Indicator {
  Indicator({
    required this.type,
    required this.points,
    required this.source,
    required this.fetchedAt,
  }) : assert(points.isNotEmpty, 'A série precisa ter ao menos um ponto');

  final IndicatorType type;
  final List<DataPoint> points;
  final DataSource source;
  final DateTime fetchedAt;

  List<double> get values => points.map((p) => p.value).toList();

  double get latest => points.last.value;

  bool get isStale => source == DataSource.cache;

  bool get isReal => source != DataSource.synthetic;

  double get avgLast7 => _average(values.sublist(math.max(0, points.length - 7)));

  /// Variação percentual da média dos últimos 7 dias contra os 7 anteriores.
  double get weeklyChangePct {
    final v = values;
    if (v.length < 8) return 0;
    final cur = _average(v.sublist(v.length - 7));
    final prev = _average(v.sublist(math.max(0, v.length - 14), v.length - 7));
    if (prev == 0) return 0;
    return (cur - prev) / prev * 100;
  }

  static double _average(List<double> v) =>
      v.isEmpty ? 0 : v.reduce((a, b) => a + b) / v.length;
}
