import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/environment_data.dart';
import '../models/indicator.dart';
import '../models/zone.dart';

class OpenMeteoException implements Exception {
  OpenMeteoException(this.message);

  final String message;

  @override
  String toString() => 'OpenMeteoException: $message';
}

/// Dados REAIS via Open-Meteo (API pública, sem chave; licença CC BY 4.0):
/// temperatura máxima diária (Forecast API) e PM2,5 (Air Quality API) para todas
/// as zonas, em uma única chamada por API (múltiplas coordenadas).
class OpenMeteoService {
  OpenMeteoService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const String _timezone = 'America/Sao_Paulo';

  Future<EnvironmentData> fetchZones() async {
    final lat = Zones.all.map((z) => z.lat.toString()).join(',');
    final lon = Zones.all.map((z) => z.lon.toString()).join(',');

    final weatherUri = Uri.https('api.open-meteo.com', '/v1/forecast', {
      'latitude': lat,
      'longitude': lon,
      'daily': 'temperature_2m_max',
      'timezone': _timezone,
      'past_days': '14',
      'forecast_days': '1',
    });
    final airUri = Uri.https('air-quality-api.open-meteo.com', '/v1/air-quality', {
      'latitude': lat,
      'longitude': lon,
      'hourly': 'pm2_5',
      'timezone': _timezone,
      'past_days': '14',
      'forecast_days': '1',
    });

    final weather = asLocations(await _getJson(weatherUri));
    if (weather.length < Zones.all.length) {
      throw OpenMeteoException('Resposta de clima incompleta');
    }

    // A qualidade do ar é opcional: se falhar, o clima continua válido.
    List<Map<String, dynamic>> air = [];
    try {
      air = asLocations(await _getJson(airUri));
    } catch (_) {
      air = [];
    }

    final zones = <String, ZoneSeries>{};
    for (var i = 0; i < Zones.all.length; i++) {
      final temps = parseDailyMax(weather[i]);
      if (temps.length < 5) throw OpenMeteoException('Dados de clima insuficientes');
      final pm25 = i < air.length ? parseAirDailyMean(air[i]) : <DataPoint>[];
      zones[Zones.all[i].id] = ZoneSeries(temps: temps, pm25: pm25);
    }
    return EnvironmentData(zones: zones, fetchedAt: DateTime.now());
  }

  Future<dynamic> _getJson(Uri uri) async {
    final response = await _client.get(uri).timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) {
      throw OpenMeteoException('HTTP ${response.statusCode}');
    }
    return jsonDecode(response.body);
  }

  /// Com várias coordenadas a API devolve uma lista; com uma, um objeto.
  static List<Map<String, dynamic>> asLocations(dynamic json) {
    if (json is List) return json.cast<Map<String, dynamic>>();
    if (json is Map<String, dynamic>) return [json];
    throw OpenMeteoException('Formato de resposta inesperado');
  }

  /// Temperatura máxima diária de uma localização.
  static List<DataPoint> parseDailyMax(Map<String, dynamic> location) {
    final daily = location['daily'] as Map<String, dynamic>?;
    if (daily == null) throw OpenMeteoException('Resposta sem dados diários');
    final times = (daily['time'] as List).cast<String>();
    final temps = daily['temperature_2m_max'] as List;
    final points = <DataPoint>[];
    for (var i = 0; i < times.length && i < temps.length; i++) {
      final t = temps[i];
      if (t is num) points.add(DataPoint(DateTime.parse(times[i]), t.toDouble()));
    }
    return points;
  }

  /// Média diária do PM2,5 a partir da série horária.
  static List<DataPoint> parseAirDailyMean(Map<String, dynamic> location) {
    final hourly = location['hourly'] as Map<String, dynamic>?;
    if (hourly == null) return [];
    final times = (hourly['time'] as List).cast<String>();
    final values = hourly['pm2_5'] as List;
    final sums = <String, double>{};
    final counts = <String, int>{};
    for (var i = 0; i < times.length && i < values.length; i++) {
      final v = values[i];
      if (v is! num) continue;
      final day = times[i].substring(0, 10);
      sums[day] = (sums[day] ?? 0) + v.toDouble();
      counts[day] = (counts[day] ?? 0) + 1;
    }
    final days = sums.keys.toList()..sort();
    return [for (final d in days) DataPoint(DateTime.parse(d), sums[d]! / counts[d]!)];
  }
}
