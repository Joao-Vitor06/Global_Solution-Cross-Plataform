import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../models/alert_model.dart';

Color severityColor(BuildContext context, AlertSeverity severity) {
  final b = Theme.of(context).brightness;
  return switch (severity) {
    AlertSeverity.critical => AppColors.criticalOf(b),
    AlertSeverity.warning => AppColors.warningOf(b),
    AlertSeverity.info => AppColors.infoOf(b),
  };
}

IconData severityIcon(AlertSeverity severity) => switch (severity) {
      AlertSeverity.critical => Icons.error,
      AlertSeverity.warning => Icons.warning_amber_rounded,
      AlertSeverity.info => Icons.info_outline,
    };

/// Selo de severidade: cor + ícone + texto (não depende só da cor).
class SeverityChip extends StatelessWidget {
  const SeverityChip(this.severity, {super.key});

  final AlertSeverity severity;

  @override
  Widget build(BuildContext context) {
    final color = severityColor(context, severity);
    return Semantics(
      label: 'Severidade: ${severity.label}',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.soft(0.14),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(severityIcon(severity), size: 16, color: color),
            const SizedBox(width: 4),
            Text(
              severity.label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
