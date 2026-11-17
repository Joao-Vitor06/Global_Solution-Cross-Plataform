import 'package:flutter/material.dart';

import '../core/theme/app_spacing.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  static const _sections = <(String, String)>[
    (
      'Quais dados usamos',
      'O volume dos mananciais vem da API pública da Sabesp; clima e qualidade do ar vêm da API pública Open-Meteo. Essas consultas usam apenas coordenadas aproximadas das regiões, nunca dados do usuário. Energia e resíduos são séries sintéticas geradas para fins acadêmicos.'
    ),
    (
      'O que fica no aparelho',
      'Ocorrências registradas, limiares de alerta, decisões sobre alertas, preferências visuais e cache do clima ficam salvos somente no seu aparelho. Nada é enviado a servidores do app.'
    ),
    (
      'Anonimização',
      'O formulário de ocorrência não pede nome nem contato. Textos com e-mail, telefone ou CPF são bloqueados pela validação. A localização é informada apenas escolhendo uma região ampla da lista (ex.: Zona Leste), nunca como endereço exato.'
    ),
    (
      'Seus direitos',
      'Em Ajustes > Privacidade você pode apagar ocorrências e decisões salvas e revogar o consentimento. Ao revogar, o app volta à tela de consentimento.'
    ),
    (
      'Decisão humana',
      'Os alertas apoiam, mas não substituem, a análise do gestor. Nenhuma ação de alto impacto é executada automaticamente.'
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Política de privacidade')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          for (final s in _sections) ...[
            Semantics(header: true, child: Text(s.$1, style: theme.textTheme.titleMedium)),
            const SizedBox(height: AppSpacing.xs),
            Text(s.$2, style: theme.textTheme.bodyLarge),
            const SizedBox(height: AppSpacing.md),
          ],
        ],
      ),
    );
  }
}
