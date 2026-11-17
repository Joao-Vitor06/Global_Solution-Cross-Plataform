import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/routes.dart';
import '../core/theme/app_spacing.dart';
import '../core/utils/format.dart';
import '../models/occurrence.dart';
import '../models/zone.dart';
import '../providers/occurrences_provider.dart';
import '../widgets/app_card.dart';
import '../widgets/state_views.dart';

/// Ocorrências anônimas registradas pela comunidade (persistidas localmente).
class OccurrencesScreen extends StatelessWidget {
  const OccurrencesScreen({super.key});

  Future<void> _confirmDelete(BuildContext context, Occurrence item) async {
    final provider = context.read<OccurrencesProvider>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir ocorrência?'),
        content: const Text('Esta ação remove a ocorrência apenas deste aparelho.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Excluir')),
        ],
      ),
    );
    if (ok == true) await provider.remove(item.id);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OccurrencesProvider>();
    final items = provider.items;
    return Scaffold(
      appBar: AppBar(title: const Text('Ocorrências da comunidade')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).pushNamed(Routes.occurrenceNew),
        icon: const Icon(Icons.add),
        label: const Text('Registrar'),
      ),
      body: items.isEmpty
          ? const EmptyView(
              icon: Icons.campaign_outlined,
              title: 'Nenhuma ocorrência registrada',
              message: 'Toque em "Registrar" para relatar um problema do seu bairro de forma anônima.',
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, 96),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, index) {
                final item = items[index];
                final theme = Theme.of(context);
                return AppCard(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(item.category.icon, color: theme.colorScheme.primary),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.category.label, style: theme.textTheme.titleMedium),
                            const SizedBox(height: 2),
                            Text(item.description),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              '${Zones.byId(item.zoneId).name} • Gravidade ${item.severityLabel} • ${formatDateTime(item.createdAt)}',
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Excluir ocorrência: ${item.category.label}',
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _confirmDelete(context, item),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
