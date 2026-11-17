import 'package:flutter/material.dart';

import '../core/theme/app_spacing.dart';

/// Barra animada de nível de confiança.
class ConfidenceBar extends StatelessWidget {
  const ConfidenceBar({super.key, required this.confidence, required this.label});

  /// De 0 a 1.
  final double confidence;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pct = (confidence * 100).round();
    return Semantics(
      label: 'Nível de confiança: $label, $pct por cento',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Confiança: $label', style: theme.textTheme.labelLarge),
              const Spacer(),
              Text('$pct%', style: theme.textTheme.labelLarge),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: confidence),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) => ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: value,
                minHeight: 10,
                backgroundColor: theme.colorScheme.outlineVariant.withAlpha(90),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
