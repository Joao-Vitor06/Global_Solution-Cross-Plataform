import 'package:flutter/material.dart';

import '../core/theme/app_spacing.dart';

/// Cartão base do app (superfície, borda e raio padronizados).
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.semanticLabel,
    this.accent,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final String? semanticLabel;

  /// Cor de destaque opcional na borda (ex.: severidade).
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppSpacing.radius),
      side: BorderSide(color: accent ?? scheme.outlineVariant, width: accent == null ? 1 : 1.5),
    );

    Widget card = Material(
      color: scheme.surface,
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: onTap == null
          ? Padding(padding: padding, child: child)
          : InkWell(onTap: onTap, child: Padding(padding: padding, child: child)),
    );

    if (semanticLabel != null) {
      card = Semantics(
        container: true,
        button: onTap != null,
        onTap: onTap,
        label: semanticLabel,
        excludeSemantics: true,
        child: card,
      );
    }
    return card;
  }
}
