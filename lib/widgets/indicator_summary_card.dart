import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../core/utils/format.dart';
import '../models/indicator.dart';
import 'app_card.dart';
import 'sparkline.dart';

/// Cartão-resumo de um indicador (valor atual, variação semanal e mini gráfico).
class IndicatorSummaryCard extends StatelessWidget {
  const IndicatorSummaryCard({
    super.key,
    required this.indicator,
    required this.alertCount,
    required this.onTap,
  });

  final Indicator indicator;
  final int alertCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final type = indicator.type;
    final change = indicator.weeklyChangePct;
    final rising = change > 0.5;
    final falling = change < -0.5;
    final trendIcon = rising ? Icons.trending_up : (falling ? Icons.trending_down : Icons.trending_flat);
    final trendWord = rising ? 'em alta' : (falling ? 'em queda' : 'estável');
    final unfavorable = type.lowerIsWorse ? falling : rising;
    final trendColor =
        unfavorable ? AppColors.warningOf(theme.brightness) : AppColors.okOf(theme.brightness);

    return AppCard(
      onTap: onTap,
      semanticLabel:
          '${type.title}: ${formatNumber(indicator.latest)} ${type.unit}, $trendWord, ${formatNumber(change.abs())} por cento na semana. '
          '$alertCount alertas ativos. Toque para abrir o painel.',
      child: Row(
        children: [
          Icon(type.icon, size: 32, color: theme.colorScheme.primary),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(type.label, style: theme.textTheme.titleMedium),
                const SizedBox(height: 2),
                Text(
                  '${formatNumber(indicator.latest)} ${type.unit}',
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(trendIcon, size: 18, color: trendColor),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        '${change >= 0 ? '+' : ''}${formatNumber(change)}% na semana',
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
                if (alertCount > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '$alertCount alerta${alertCount > 1 ? 's' : ''} ativo${alertCount > 1 ? 's' : ''}',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: AppColors.warningOf(theme.brightness),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Sparkline(points: indicator.points, color: theme.colorScheme.primary),
        ],
      ),
    );
  }
}
