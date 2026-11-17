import 'package:latlong2/latlong.dart';

/// Região de São Paulo monitorada no mapa (localização aproximada, nunca exata).
class Zone {
  const Zone({required this.id, required this.name, required this.lat, required this.lon});

  final String id;
  final String name;
  final double lat;
  final double lon;

  LatLng get point => LatLng(lat, lon);
}

class Zones {
  Zones._();

  /// A primeira zona é o território principal do app (Itaquera).
  static const List<Zone> all = [
    Zone(id: 'leste', name: 'Zona Leste (Itaquera)', lat: -23.54, lon: -46.45),
    Zone(id: 'centro', name: 'Centro', lat: -23.55, lon: -46.63),
    Zone(id: 'norte', name: 'Zona Norte (Santana)', lat: -23.50, lon: -46.62),
    Zone(id: 'sul', name: 'Zona Sul (Interlagos)', lat: -23.68, lon: -46.70),
    Zone(id: 'oeste', name: 'Zona Oeste (Butantã)', lat: -23.57, lon: -46.72),
  ];

  static Zone get main => all.first;

  static Zone byId(String id) => all.firstWhere((z) => z.id == id, orElse: () => main);
}

enum ZoneStatus { unknown, ok, attention, alert }

extension ZoneStatusX on ZoneStatus {
  String get label => switch (this) {
        ZoneStatus.unknown => 'Sem dados',
        ZoneStatus.ok => 'Dentro dos limiares',
        ZoneStatus.attention => 'Atenção',
        ZoneStatus.alert => 'Alerta',
      };
}

/// Leitura mais recente de uma zona (dados reais Open-Meteo).
class ZoneReading {
  const ZoneReading({required this.zone, required this.status, this.tempMax, this.pm25, this.date});

  final Zone zone;
  final ZoneStatus status;
  final double? tempMax;
  final double? pm25;
  final DateTime? date;

  static ZoneStatus statusFor({
    required double? temp,
    required double? pm25,
    required double tempThreshold,
    required double airThreshold,
  }) {
    if (temp == null && pm25 == null) return ZoneStatus.unknown;
    var breaches = 0;
    if (temp != null && temp >= tempThreshold) breaches++;
    if (pm25 != null && pm25 >= airThreshold) breaches++;
    return switch (breaches) {
      0 => ZoneStatus.ok,
      1 => ZoneStatus.attention,
      _ => ZoneStatus.alert,
    };
  }
}
