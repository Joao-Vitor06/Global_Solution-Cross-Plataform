import 'package:flutter/material.dart';

import '../core/theme/app_spacing.dart';
import '../models/alert_model.dart';
import 'app_card.dart';
import 'severity_chip.dart';

/// Linha de alerta reutilizada na lista de alertas e nos painéis.
class AlertTile extends StatelessWidget {
  const AlertTile({super.key, required this.alert, required this.decision, required this.onTap});

  final TerritoryAlert alert;
  final AlertDecision decision;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = severityColor(context, alert.severity);
    return AppCard(
      onTap: onTap,
      accent: color,
      semanticLabel:
          '${alert.severity.label}: ${alert.title}. Confiança ${alert.confidenceLabel}. ${decision.label}. Toque para ver detalhes.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SeverityChip(alert.severity),
              const Spacer(),
              Text('Confiança ${alert.confidenceLabel}', style: theme.textTheme.labelMedium),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(alert.title, style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(alert.summary, style: theme.textTheme.bodyMedium),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Icon(
                decision == AlertDecision.pending ? Icons.hourglass_empty : Icons.check_circle_outline,
                size: 16,
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(child: Text(decision.label, style: theme.textTheme.bodySmall)),
              const Icon(Icons.chevron_right),
            ],
          ),
        ],
      ),
    );
  }
}
