import 'indicator.dart';

/// Séries diárias de uma zona: temperatura máxima e PM2,5 médio.
class ZoneSeries {
  const ZoneSeries({required this.temps, required this.pm25});

  factory ZoneSeries.fromJson(Map<String, dynamic> json) => ZoneSeries(
        temps: (json['temps'] as List)
            .map((e) => DataPoint.fromJson(e as Map<String, dynamic>))
            .toList(),
        pm25: (json['pm25'] as List)
            .map((e) => DataPoint.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  final List<DataPoint> temps;
  final List<DataPoint> pm25;

  Map<String, dynamic> toJson() => {
        'temps': temps.map((p) => p.toJson()).toList(),
        'pm25': pm25.map((p) => p.toJson()).toList(),
      };
}

/// Dados ambientais reais (Open-Meteo) de todas as zonas.
class EnvironmentData {
  const EnvironmentData({required this.zones, required this.fetchedAt});

  factory EnvironmentData.fromJson(Map<String, dynamic> json) => EnvironmentData(
        fetchedAt: DateTime.parse(json['fetchedAt'] as String),
        zones: {
          for (final e in (json['zones'] as Map<String, dynamic>).entries)
            e.key: ZoneSeries.fromJson(e.value as Map<String, dynamic>),
        },
      );

  final Map<String, ZoneSeries> zones;
  final DateTime fetchedAt;

  Map<String, dynamic> toJson() => {
        'fetchedAt': fetchedAt.toIso8601String(),
        'zones': {for (final e in zones.entries) e.key: e.value.toJson()},
      };
}
