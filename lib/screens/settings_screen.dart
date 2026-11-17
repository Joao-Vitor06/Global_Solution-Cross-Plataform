import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/routes.dart';
import '../core/theme/app_spacing.dart';
import '../providers/occurrences_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/territory_provider.dart';
import '../widgets/app_card.dart';
import '../widgets/section_title.dart';

/// Ajustes: aparência, acessibilidade, limiares, privacidade e sobre.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<bool> _confirm(BuildContext context, String title, String message) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Confirmar')),
        ],
      ),
    );
    return ok == true;
  }

  Future<void> _eraseData(BuildContext context) async {
    final occurrences = context.read<OccurrencesProvider>();
    final territory = context.read<TerritoryProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final ok = await _confirm(
      context,
      'Apagar dados locais?',
      'Ocorrências registradas e decisões sobre alertas serão removidas deste aparelho.',
    );
    if (!ok) return;
    await occurrences.clear();
    await territory.clearDecisions();
    messenger.showSnackBar(const SnackBar(content: Text('Dados locais apagados.')));
  }

  Future<void> _revoke(BuildContext context) async {
    final settings = context.read<SettingsProvider>();
    final occurrences = context.read<OccurrencesProvider>();
    final territory = context.read<TerritoryProvider>();
    final navigator = Navigator.of(context);
    final ok = await _confirm(
      context,
      'Revogar consentimento?',
      'Seus dados locais serão apagados e você voltará à tela de consentimento.',
    );
    if (!ok) return;
    await occurrences.clear();
    await territory.clearDecisions();
    await settings.revokeConsent();
    navigator.pushNamedAndRemoveUntil(Routes.consent, (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Ajustes')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          const SectionTitle('Aparência e acessibilidade'),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tema', style: theme.textTheme.titleSmall),
                const SizedBox(height: AppSpacing.sm),
                SegmentedButton<ThemeMode>(
                  segments: const [
                    ButtonSegment(value: ThemeMode.system, label: Text('Sistema')),
                    ButtonSegment(value: ThemeMode.light, label: Text('Claro')),
                    ButtonSegment(value: ThemeMode.dark, label: Text('Escuro')),
                  ],
                  selected: {settings.themeMode},
                  onSelectionChanged: (s) => settings.setThemeMode(s.first),
                ),
                const SizedBox(height: AppSpacing.sm),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Alto contraste'),
                  subtitle: const Text('Cores com contraste máximo para melhor leitura.'),
                  value: settings.highContrast,
                  onChanged: settings.setHighContrast,
                ),
                Text('Tamanho do texto: ${(settings.fontScale * 100).round()}%', style: theme.textTheme.titleSmall),
                Slider(
                  value: settings.fontScale,
                  min: 0.85,
                  max: 1.5,
                  divisions: 13,
                  label: '${(settings.fontScale * 100).round()}%',
                  semanticFormatterCallback: (v) => 'Tamanho do texto ${(v * 100).round()} por cento',
                  onChanged: settings.setFontScale,
                ),
              ],
            ),
          ),
          const SectionTitle('Alertas'),
          AppCard(
            onTap: () => Navigator.of(context).pushNamed(Routes.thresholds),
            semanticLabel: 'Configurar limiares de alerta. Toque para abrir.',
            child: const Row(
              children: [
                Icon(Icons.tune),
                SizedBox(width: AppSpacing.md),
                Expanded(child: Text('Configurar limiares de alerta')),
                Icon(Icons.chevron_right),
              ],
            ),
          ),
          const SectionTitle('Privacidade'),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.privacy_tip_outlined),
                  title: const Text('Política de privacidade'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).pushNamed(Routes.privacy),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.delete_sweep_outlined),
                  title: const Text('Apagar ocorrências e decisões'),
                  onTap: () => _eraseData(context),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.gpp_bad_outlined),
                  title: const Text('Revogar consentimento'),
                  onTap: () => _revoke(context),
                ),
              ],
            ),
          ),
          const SectionTitle('Sobre'),
          AppCard(
            child: Text(
              'TerraSense v1.0.0\nProjeto acadêmico FIAP, Global Solution 2026.2 (tema CitizenTech, desafio Territory Predictive Insights).\n\nÁgua (Sabesp), clima e ar (Open-Meteo) usam APIs públicas reais; energia e resíduos são sintéticos. Mapa: © colaboradores do OpenStreetMap. Os alertas apoiam, mas não substituem, a decisão humana.',
              style: theme.textTheme.bodyMedium,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}
