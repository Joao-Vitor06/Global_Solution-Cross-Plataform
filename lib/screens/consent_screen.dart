import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/routes.dart';
import '../core/theme/app_spacing.dart';
import '../providers/settings_provider.dart';
import '../widgets/app_card.dart';

/// Primeira tela: consentimento explícito para uso de dados locais.
class ConsentScreen extends StatefulWidget {
  const ConsentScreen({super.key});

  @override
  State<ConsentScreen> createState() => _ConsentScreenState();
}

class _ConsentScreenState extends State<ConsentScreen> {
  bool _accepted = false;

  Future<void> _continue() async {
    await context.read<SettingsProvider>().giveConsent();
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed(Routes.home);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Icon(Icons.travel_explore, size: 64, color: theme.colorScheme.primary),
            const SizedBox(height: AppSpacing.md),
            Semantics(
              header: true,
              child: Text('Bem-vindo ao TerraSense', style: theme.textTheme.headlineSmall),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Painel de inteligência territorial que antecipa problemas de água, energia, clima e resíduos para apoiar a decisão de gestores públicos e cidadãos.',
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: AppSpacing.lg),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Antes de começar', style: theme.textTheme.titleMedium),
                  const SizedBox(height: AppSpacing.sm),
                  const _Bullet('Não pedimos nome, e-mail, telefone nem localização exata.'),
                  const _Bullet('Ocorrências, limiares e preferências ficam salvos apenas neste aparelho.'),
                  const _Bullet('Os alertas são estimativas e nunca tomam decisões sozinhos: a decisão final é sempre humana.'),
                  const _Bullet('Você pode apagar seus dados e revogar o consentimento a qualquer momento em Ajustes.'),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextButton(
              onPressed: () => Navigator.of(context).pushNamed(Routes.privacy),
              child: const Text('Ler política de privacidade'),
            ),
            CheckboxListTile(
              value: _accepted,
              onChanged: (v) => setState(() => _accepted = v ?? false),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Li e concordo com o uso de dados anonimizados e armazenados localmente, conforme descrito acima.',
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            FilledButton(
              onPressed: _accepted ? _continue : null,
              child: const Text('Aceitar e continuar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(padding: EdgeInsets.only(top: 2), child: Icon(Icons.check_circle_outline, size: 18)),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
