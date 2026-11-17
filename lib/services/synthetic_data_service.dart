import 'dart:math' as math;

import '../models/indicator.dart';

/// "API simulada": gera séries sintéticas determinísticas (sem dados pessoais).
/// Energia e resíduos NÃO têm fonte aberta integrada e são sempre sintéticos;
/// água, clima e ar usam dados reais e só recorrem a estas séries se a rede falhar.
class SyntheticDataService {
  const SyntheticDataService({this.latency = const Duration(milliseconds: 500)});

  /// Latência artificial para simular uma chamada de rede.
  final Duration latency;

  Future<List<Indicator>> fetchEnergyAndWaste() async {
    await Future<void>.delayed(latency);
    final now = DateTime.now();
    return [
      _build(IndicatorType.energy, 30, now),
      _build(IndicatorType.waste, 30, now),
    ];
  }

  Indicator fallbackWater() => _build(IndicatorType.water, 30, DateTime.now());

  Indicator fallbackClimate() => _build(IndicatorType.climate, 15, DateTime.now());

  Indicator fallbackAir() => _build(IndicatorType.air, 15, DateTime.now());

  static Indicator _build(IndicatorType type, int days, DateTime now) => Indicator(
        type: type,
        points: generateSeries(type, days, now),
        source: DataSource.synthetic,
        fetchedAt: now,
      );

  /// Ruído pseudoaleatório determinístico em [-1, 1].
  static double _noise(int i, int seed) {
    final x = math.sin(i * 12.9898 + seed * 78.233) * 43758.5453;
    return (x - x.floorToDouble()) * 2 - 1;
  }

  /// Gera [days] pontos diários terminando em [today].
  static List<DataPoint> generateSeries(IndicatorType type, int days, DateTime today) {
    final end = DateTime(today.year, today.month, today.day);
    return List<DataPoint>.generate(days, (i) {
      final date = end.subtract(Duration(days: days - 1 - i));
      final weekend = i % 7 == 5 || i % 7 == 6;
      final double value;
      switch (type) {
        case IndicatorType.water:
          value = 56 - 0.25 * i + _noise(i, 1) * 0.3;
        case IndicatorType.energy:
          value = 310 +
              0.3 * i +
              12 * math.sin(2 * math.pi * i / 7) +
              _noise(i, 2) * 8 +
              (i == days - 1 ? 55 : 0); // pico anômalo no último dia
        case IndicatorType.waste:
          value = 40 + 0.3 * i + (i % 7 == 6 ? -4 : 0) + _noise(i, 3) * 1.5;
        case IndicatorType.climate:
          value = 28 + 0.1 * i + _noise(i, 4) * 1.5;
        case IndicatorType.air:
          value = 13 + 0.45 * i + (weekend ? -2 : 0) + _noise(i, 5) * 2;
      }
      return DataPoint(date, value);
    });
  }
}
