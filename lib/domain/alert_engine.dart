import 'dart:math' as math;

import '../core/utils/format.dart';
import '../models/alert_model.dart';
import '../models/indicator.dart';
import '../models/thresholds.dart';

/// Regressão linear simples (mínimos quadrados) usada nas projeções.
class Regression {
  const Regression({
    required this.slope,
    required this.intercept,
    required this.r2,
    required this.residualStd,
  });

  factory Regression.fit(List<double> y) {
    final n = y.length;
    if (n < 3) {
      return Regression(slope: 0, intercept: y.isEmpty ? 0 : y.last, r2: 0, residualStd: 0);
    }
    final meanX = (n - 1) / 2;
    final meanY = y.reduce((a, b) => a + b) / n;
    var sxx = 0.0;
    var sxy = 0.0;
    for (var i = 0; i < n; i++) {
      sxx += (i - meanX) * (i - meanX);
      sxy += (i - meanX) * (y[i] - meanY);
    }
    final slope = sxy / sxx;
    final intercept = meanY - slope * meanX;
    var ssRes = 0.0;
    var ssTot = 0.0;
    for (var i = 0; i < n; i++) {
      final pred = intercept + slope * i;
      ssRes += (y[i] - pred) * (y[i] - pred);
      ssTot += (y[i] - meanY) * (y[i] - meanY);
    }
    final r2 = ssTot == 0 ? 0.0 : (1 - ssRes / ssTot).clamp(0.0, 1.0).toDouble();
    return Regression(
      slope: slope,
      intercept: intercept,
      r2: r2,
      residualStd: math.sqrt(ssRes / (n - 2)),
    );
  }

  final double slope;
  final double intercept;
  final double r2;
  final double residualStd;

  double predict(double x) => intercept + slope * x;
}

/// Motor de alertas: regras transparentes + projeção estatística.
/// Gera apenas SUGESTÕES para análise humana; nunca executa ações.
///
/// Internamente trabalha com um "risco" = valor × sinal, em que sinal = +1 quando
/// valores maiores são piores e -1 quando valores menores são piores (ex.: volume
/// dos mananciais). Assim as mesmas regras servem para os dois sentidos.
class AlertEngine {
  AlertEngine._();

  static const int horizonDays = 7;
  static const int _window = 21;

  static List<TerritoryAlert> generate(
    List<Indicator> indicators,
    Thresholds thresholds, {
    DateTime? now,
  }) {
    final ref = now ?? DateTime.now();
    final alerts = <TerritoryAlert>[];
    for (final indicator in indicators) {
      alerts.addAll(_forIndicator(indicator, thresholds, ref));
    }
    alerts.sort((a, b) {
      final bySeverity = b.severity.index.compareTo(a.severity.index);
      return bySeverity != 0 ? bySeverity : b.confidence.compareTo(a.confidence);
    });
    return alerts;
  }

  static double _sign(Indicator ind) => ind.type.lowerIsWorse ? -1.0 : 1.0;

  static List<double> _riskWindow(Indicator ind) {
    final sign = _sign(ind);
    final risk = ind.values.map((v) => v * sign).toList();
    return risk.length > _window ? risk.sublist(risk.length - _window) : risk;
  }

  /// Projeção (na escala original) para os próximos [days] dias.
  static List<double> forecast(Indicator ind, {int days = horizonDays}) {
    final sign = _sign(ind);
    final w = _riskWindow(ind);
    final reg = Regression.fit(w);
    return List<double>.generate(days, (i) => reg.predict((w.length + i).toDouble()) * sign);
  }

  static List<TerritoryAlert> _forIndicator(Indicator ind, Thresholds t, DateTime now) {
    final out = <TerritoryAlert>[];
    final lower = ind.type.lowerIsWorse;
    final sign = _sign(ind);
    final values = ind.values;
    final n = values.length;
    final risk = values.map((v) => v * sign).toList();
    final window = _riskWindow(ind);
    final w = window.length;
    final reg = Regression.fit(window);
    final projected = reg.predict((w - 1 + horizonDays).toDouble()) * sign;
    final margin = 1.96 * reg.residualStd;
    final threshold = t.of(ind.type);
    final latest = ind.latest;
    final unit = ind.type.unit;
    final penalty = _penalty(ind, w);
    final limitations = _limitations(ind, reg, w);
    final day = '${now.year}${now.month}${now.day}';
    final name = ind.type.title.toLowerCase();
    final label = ind.type.label.toLowerCase();
    final beyond = lower ? 'abaixo' : 'acima';
    final cmp = lower ? '≤' : '≥';

    var ruleOneFired = false;

    // Regra 1a: limiar já atingido (medição observada).
    if (latest * sign >= threshold * sign) {
      ruleOneFired = true;
      out.add(TerritoryAlert(
        id: '${ind.type.name}_threshold_$day',
        indicatorType: ind.type,
        severity: AlertSeverity.critical,
        title: 'Limiar atingido: ${ind.type.label}',
        summary: 'O valor mais recente de $name está $beyond do limiar configurado.',
        plainLanguage:
            'A medição de $label na região está $beyond do limite definido pela gestão. Vale acompanhar de perto.',
        evidence: [
          'Última medição: ${formatNumber(latest)} $unit (limiar: ${formatNumber(threshold)} $unit; regra: valor $cmp limiar).',
          'Média dos últimos 7 dias: ${formatNumber(ind.avgLast7)} $unit.',
        ],
        limitations: limitations,
        confidence: (0.85 - penalty).clamp(0.1, 0.95).toDouble(),
        createdAt: now,
      ));
    } else if (reg.slope > 0 && projected * sign >= threshold * sign) {
      // Regra 1b: a projeção indica que o limiar será atingido.
      ruleOneFired = true;
      final slopeShown = reg.slope * sign;
      out.add(TerritoryAlert(
        id: '${ind.type.name}_forecast_$day',
        indicatorType: ind.type,
        severity: AlertSeverity.warning,
        title: 'Projeção de atingir o limiar: ${ind.type.label}',
        summary:
            'A tendência dos últimos $w dias indica que $name pode ficar $beyond do limiar em até $horizonDays dias.',
        plainLanguage:
            'Se o ritmo atual continuar, $label deve ficar $beyond do limite em cerca de uma semana. É um aviso antecipado, não uma certeza.',
        evidence: [
          'Tendência: ${slopeShown >= 0 ? '+' : ''}${formatNumber(slopeShown, decimals: 2)} $unit por dia (r² = ${formatNumber(reg.r2, decimals: 2)}).',
          'Projeção em $horizonDays dias: ${formatNumber(projected)} $unit (faixa de ±${formatNumber(margin)}).',
          'Último valor: ${formatNumber(latest)} $unit; limiar: ${formatNumber(threshold)} $unit.',
        ],
        limitations: limitations,
        confidence: (0.2 + 0.7 * reg.r2 - penalty).clamp(0.1, 0.95).toDouble(),
        createdAt: now,
      ));
    }

    // Regra 2: anomalia estatística (z-score do risco do último valor).
    if (n >= 8) {
      final base = risk.sublist(0, n - 1);
      final mean = base.reduce((a, b) => a + b) / base.length;
      final variance =
          base.map((v) => (v - mean) * (v - mean)).reduce((a, b) => a + b) / base.length;
      final std = math.sqrt(variance);
      if (std > 0) {
        final z = (risk.last - mean) / std;
        if (z >= 2.0) {
          out.add(TerritoryAlert(
            id: '${ind.type.name}_anomaly_$day',
            indicatorType: ind.type,
            severity: AlertSeverity.warning,
            title: '${lower ? 'Queda' : 'Pico'} incomum: ${ind.type.label}',
            summary: 'O último valor de $name está muito fora do padrão recente.',
            plainLanguage:
                'Houve uma variação fora do comum em $label hoje. Pode ser um evento pontual ou um erro de medição; precisa de checagem.',
            evidence: [
              'Último valor: ${formatNumber(latest)} $unit contra média anterior de ${formatNumber(mean * sign)} $unit.',
              'Desvio de ${formatNumber(z)} desvios-padrão (z-score; regra: z ≥ 2,0).',
            ],
            limitations: [
              ...limitations,
              'Um único ponto pode ser erro de sensor ou evento isolado; confirme em campo antes de agir.',
            ],
            confidence: (0.5 + 0.08 * (z - 2).clamp(0, 5) - penalty).clamp(0.1, 0.85).toDouble(),
            createdAt: now,
          ));
        }
      }
    }

    // Regra 3: tendência semanal desfavorável (se a regra 1 não disparou).
    final change = ind.weeklyChangePct * sign;
    if (!ruleOneFired && change >= t.trendPct) {
      out.add(TerritoryAlert(
        id: '${ind.type.name}_trend_$day',
        indicatorType: ind.type,
        severity: AlertSeverity.info,
        title: 'Tendência de ${lower ? 'queda' : 'alta'}: ${ind.type.label}',
        summary:
            'A média semanal de $name ${lower ? 'caiu' : 'subiu'} ${formatNumber(change)}% em relação à semana anterior.',
        plainLanguage:
            'O valor de $label vem ${lower ? 'caindo' : 'subindo'} de uma semana para outra. Ainda não é um problema, mas merece atenção.',
        evidence: [
          'Variação semanal desfavorável: ${formatNumber(change)}% (regra: ≥ ${formatNumber(t.trendPct)}%).',
          'Média dos últimos 7 dias: ${formatNumber(ind.avgLast7)} $unit.',
        ],
        limitations: limitations,
        confidence: (0.25 + 0.6 * reg.r2 - penalty).clamp(0.1, 0.9).toDouble(),
        createdAt: now,
      ));
    }

    return out;
  }

  static double _penalty(Indicator ind, int windowSize) {
    var penalty = 0.0;
    if (windowSize < 14) penalty += 0.2;
    if (ind.source == DataSource.cache) penalty += 0.15;
    if (ind.source == DataSource.synthetic) penalty += 0.05;
    return penalty;
  }

  static List<String> _limitations(Indicator ind, Regression reg, int windowSize) {
    final list = <String>[
      'Modelo de regressão linear simples (janela de $windowSize dias): não captura sazonalidade, feriados nem eventos extraordinários.',
    ];
    if (windowSize < 14) {
      list.add('Poucos dados históricos ($windowSize dias): a previsão é mais incerta.');
    }
    if (reg.r2 < 0.3) {
      list.add(
        'Ajuste fraco (r² = ${formatNumber(reg.r2, decimals: 2)}): os dados variam muito e a projeção é pouco confiável.',
      );
    }
    switch (ind.source) {
      case DataSource.synthetic:
        list.add('Dados sintéticos gerados para fins acadêmicos: não representam medições reais.');
      case DataSource.openMeteo:
        list.add('O valor do dia atual pode ser previsão/estimativa do modelo, não medição de estação.');
      case DataSource.sabesp:
        list.add('Dados operacionais da Sabesp (sistema Alto Tietê): variações diárias pequenas limitam a projeção.');
      case DataSource.cache:
        list.add('Dados em cache de ${formatDateTime(ind.fetchedAt)}; podem estar desatualizados.');
    }
    switch (ind.type) {
      case IndicatorType.water:
        list.add('O volume do manancial mede a oferta de água do sistema, não o consumo nem a falta de água em cada bairro.');
      case IndicatorType.air:
        list.add('PM2,5 vem de modelo de baixa resolução espacial: não substitui as estações da CETESB.');
      case IndicatorType.climate:
      case IndicatorType.energy:
      case IndicatorType.waste:
        break;
    }
    list.add('Médias do território podem esconder desigualdades entre bairros e domicílios.');
    return list;
  }
}
