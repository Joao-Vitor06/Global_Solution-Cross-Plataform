import 'package:flutter/material.dart';

import '../core/theme/app_spacing.dart';
import 'app_card.dart';

/// Indicador numérico com rótulo (KPI).
class KpiTile extends StatelessWidget {
  const KpiTile({super.key, required this.label, required this.value, this.caption, this.icon});

  final String label;
  final String value;
  final String? caption;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      semanticLabel: '$label: $value${caption == null ? '' : ', $caption'}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: theme.colorScheme.primary),
                const SizedBox(width: AppSpacing.xs),
              ],
              Expanded(child: Text(label, style: theme.textTheme.labelMedium)),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(value, style: theme.textTheme.titleLarge),
          if (caption != null) Text(caption!, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}
