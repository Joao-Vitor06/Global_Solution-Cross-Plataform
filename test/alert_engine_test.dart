import 'package:flutter_test/flutter_test.dart';
import 'package:territory_insights/domain/alert_engine.dart';
import 'package:territory_insights/models/alert_model.dart';
import 'package:territory_insights/models/indicator.dart';
import 'package:territory_insights/models/thresholds.dart';
import 'package:territory_insights/services/synthetic_data_service.dart';

Indicator _indicator(IndicatorType type, {int days = 30, DataSource source = DataSource.synthetic}) {
  final now = DateTime(2026, 11, 11);
  return Indicator(
    type: type,
    points: SyntheticDataService.generateSeries(type, days, now),
    source: source,
    fetchedAt: now,
  );
}

void main() {
  final now = DateTime(2026, 11, 11);

  group('Regression', () {
    test('ajusta uma reta perfeita com r2 = 1', () {
      final reg = Regression.fit([2, 4, 6, 8, 10]);
      expect(reg.slope, closeTo(2, 1e-9));
      expect(reg.r2, closeTo(1, 1e-9));
      expect(reg.predict(5), closeTo(12, 1e-9));
    });

    test('série constante tem r2 = 0', () {
      expect(Regression.fit([5, 5, 5, 5]).r2, 0);
    });
  });

  group('AlertEngine', () {
    test('volume de manancial em queda: sem alerta com limiar padrão', () {
      final alerts = AlertEngine.generate([_indicator(IndicatorType.water)], Thresholds.defaults(), now: now);
      expect(alerts, isEmpty);
    });

    test('água: limiar alto (menor é pior) gera alerta crítico', () {
      final high = Thresholds.defaults().copyWith(
        values: {for (final t in IndicatorType.values) t: t.defaultThreshold}..[IndicatorType.water] = 60,
      );
      final alerts = AlertEngine.generate([_indicator(IndicatorType.water)], high, now: now);
      expect(alerts.first.severity, AlertSeverity.critical);
      expect(alerts.first.summary, contains('abaixo'));
    });

    test('água: projeção da série em queda é decrescente', () {
      final f = AlertEngine.forecast(_indicator(IndicatorType.water));
      expect(f.last, lessThan(f.first));
    });

    test('qualidade do ar sintética gera alerta com limiar padrão', () {
      final alerts = AlertEngine.generate([_indicator(IndicatorType.air)], Thresholds.defaults(), now: now);
      expect(alerts, isNotEmpty);
      expect(alerts.first.indicatorType, IndicatorType.air);
    });

    test('detecta pico anômalo de energia', () {
      final alerts = AlertEngine.generate([_indicator(IndicatorType.energy)], Thresholds.defaults(), now: now);
      expect(alerts.any((a) => a.id.startsWith('energy_anomaly')), isTrue);
    });

    test('resíduos dentro do padrão não geram alertas', () {
      final alerts = AlertEngine.generate([_indicator(IndicatorType.waste)], Thresholds.defaults(), now: now);
      expect(alerts, isEmpty);
    });

    test('limiar baixo gera alerta crítico', () {
      final low = Thresholds.defaults().copyWith(
        values: {for (final t in IndicatorType.values) t: 1.0},
      );
      final alerts = AlertEngine.generate([_indicator(IndicatorType.waste)], low, now: now);
      expect(alerts.first.severity, AlertSeverity.critical);
    });

    test('todo alerta tem evidência, limitações e confiança válida', () {
      final all = [for (final t in IndicatorType.values) _indicator(t, days: t == IndicatorType.climate || t == IndicatorType.air ? 15 : 30)];
      final low = Thresholds.defaults().copyWith(
        values: {for (final t in IndicatorType.values) t: 1.0},
      );
      final alerts = AlertEngine.generate(all, low, now: now);
      expect(alerts, isNotEmpty);
      for (final a in alerts) {
        expect(a.evidence, isNotEmpty);
        expect(a.limitations, isNotEmpty);
        expect(a.confidence, inInclusiveRange(0.1, 0.95));
      }
    });

    test('dados em cache reduzem a confiança', () {
      final fresh = AlertEngine.generate([_indicator(IndicatorType.air)], Thresholds.defaults(), now: now);
      final cached = AlertEngine.generate(
        [_indicator(IndicatorType.air, source: DataSource.cache)],
        Thresholds.defaults(),
        now: now,
      );
      expect(cached.first.confidence, lessThan(fresh.first.confidence));
    });

    test('previsão tem 7 pontos', () {
      expect(AlertEngine.forecast(_indicator(IndicatorType.energy)).length, AlertEngine.horizonDays);
    });
  });
}
