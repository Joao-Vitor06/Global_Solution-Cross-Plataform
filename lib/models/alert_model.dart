import 'indicator.dart';

enum AlertSeverity { info, warning, critical }

/// Decisão HUMANA registrada sobre um alerta (o app nunca decide sozinho).
enum AlertDecision { pending, acknowledged, forwarded, dismissed }

extension AlertSeverityX on AlertSeverity {
  String get label => switch (this) {
        AlertSeverity.info => 'Informativo',
        AlertSeverity.warning => 'Atenção',
        AlertSeverity.critical => 'Crítico',
      };
}

extension AlertDecisionX on AlertDecision {
  String get label => switch (this) {
        AlertDecision.pending => 'Aguardando análise humana',
        AlertDecision.acknowledged => 'Reconhecido por gestor',
        AlertDecision.forwarded => 'Encaminhado à equipe',
        AlertDecision.dismissed => 'Descartado por gestor',
      };
}

class TerritoryAlert {
  const TerritoryAlert({
    required this.id,
    required this.indicatorType,
    required this.severity,
    required this.title,
    required this.summary,
    required this.plainLanguage,
    required this.evidence,
    required this.limitations,
    required this.confidence,
    required this.createdAt,
  });

  final String id;
  final IndicatorType indicatorType;
  final AlertSeverity severity;
  final String title;
  final String summary;

  /// Explicação em linguagem simples para o cidadão.
  final String plainLanguage;
  final List<String> evidence;
  final List<String> limitations;

  /// De 0 a 1.
  final double confidence;
  final DateTime createdAt;

  String get confidenceLabel {
    if (confidence >= 0.7) return 'Alta';
    if (confidence >= 0.45) return 'Média';
    return 'Baixa';
  }
}
