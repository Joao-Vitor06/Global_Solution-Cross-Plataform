import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';

/// Aviso permanente: alertas apoiam, mas não substituem, a decisão humana.
class HumanDecisionBanner extends StatelessWidget {
  const HumanDecisionBanner({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = AppColors.infoOf(theme.brightness);
    const text =
        'Apoio à decisão: os alertas são estimativas estatísticas e não substituem a análise humana. A decisão final é sempre do gestor.';
    return Semantics(
      container: true,
      label: text,
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: color.soft(0.12),
          borderRadius: BorderRadius.circular(AppSpacing.radius),
          border: Border.all(color: color),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.verified_user_outlined, color: color),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                compact ? 'A decisão final é sempre humana. Alertas são apenas apoio.' : text,
                style: theme.textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
