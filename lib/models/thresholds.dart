import 'indicator.dart';

/// Limiares configuráveis pelo gestor para disparo de alertas.
class Thresholds {
  const Thresholds({required this.values, required this.trendPct});

  factory Thresholds.defaults() => Thresholds(
        values: {for (final t in IndicatorType.values) t: t.defaultThreshold},
        trendPct: 8,
      );

  factory Thresholds.fromJson(Map<String, dynamic> json) {
    final defaults = Thresholds.defaults();
    final raw = (json['values'] as Map<String, dynamic>?) ?? {};
    return Thresholds(
      values: {
        for (final t in IndicatorType.values)
          t: (raw[t.name] as num?)?.toDouble() ?? defaults.values[t]!,
      },
      trendPct: (json['trendPct'] as num?)?.toDouble() ?? defaults.trendPct,
    );
  }

  final Map<IndicatorType, double> values;

  /// Variação semanal (%) a partir da qual um alerta de tendência é gerado.
  final double trendPct;

  double of(IndicatorType type) => values[type] ?? type.defaultThreshold;

  Thresholds copyWith({Map<IndicatorType, double>? values, double? trendPct}) =>
      Thresholds(values: values ?? this.values, trendPct: trendPct ?? this.trendPct);

  Map<String, dynamic> toJson() => {
        'values': {for (final e in values.entries) e.key.name: e.value},
        'trendPct': trendPct,
      };
}
