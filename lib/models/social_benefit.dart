import 'alert_model.dart';
import 'zone.dart';

/// Indicadores de benefício social exibidos no app.
class SocialBenefit {
  const SocialBenefit({
    required this.leadTimeDays,
    required this.reviewedPct,
    required this.occurrences,
    required this.zonesMonitored,
    required this.zonesInAttention,
  });

  factory SocialBenefit.compute({
    required List<TerritoryAlert> alerts,
    required Map<String, AlertDecision> decisions,
    required int occurrenceCount,
    required List<ZoneReading> zones,
    required int horizonDays,
  }) {
    final reviewed = alerts.where((a) {
      final d = decisions[a.id] ?? AlertDecision.pending;
      return d != AlertDecision.pending;
    }).length;
    final hasPredictive = alerts.any((a) => a.severity != AlertSeverity.critical);
    return SocialBenefit(
      leadTimeDays: hasPredictive ? horizonDays : 0,
      reviewedPct: alerts.isEmpty ? 100 : reviewed / alerts.length * 100,
      occurrences: occurrenceCount,
      zonesMonitored: zones.where((z) => z.status != ZoneStatus.unknown).length,
      zonesInAttention:
          zones.where((z) => z.status == ZoneStatus.attention || z.status == ZoneStatus.alert).length,
    );
  }

  /// Antecedência máxima dos alertas preditivos ativos.
  final int leadTimeDays;

  /// Percentual de alertas já analisados por uma pessoa.
  final double reviewedPct;

  /// Ocorrências registradas pela comunidade.
  final int occurrences;

  /// Regiões com dados reais monitoradas.
  final int zonesMonitored;

  /// Regiões que exigem atenção (calor e/ou ar acima dos limiares).
  final int zonesInAttention;
}
