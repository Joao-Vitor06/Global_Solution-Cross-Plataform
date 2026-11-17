import 'package:flutter/material.dart';

/// Paleta da marca TerraSense (verde-água + âmbar de atenção).
class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF0B6E69);
  static const Color primaryOnDark = Color(0xFF7FD6CF);

  static const Color critical = Color(0xFFB3261E);
  static const Color warning = Color(0xFF8A5100);
  static const Color info = Color(0xFF1B5FA6);
  static const Color ok = Color(0xFF2E6B2F);

  static const Color criticalOnDark = Color(0xFFFFB4AB);
  static const Color warningOnDark = Color(0xFFFFB866);
  static const Color infoOnDark = Color(0xFF9CC9FF);
  static const Color okOnDark = Color(0xFF9BD79C);

  static Color criticalOf(Brightness b) => b == Brightness.dark ? criticalOnDark : critical;
  static Color warningOf(Brightness b) => b == Brightness.dark ? warningOnDark : warning;
  static Color infoOf(Brightness b) => b == Brightness.dark ? infoOnDark : info;
  static Color okOf(Brightness b) => b == Brightness.dark ? okOnDark : ok;
}

extension ColorSoft on Color {
  /// Versão translúcida da cor (compatível com qualquer versão do Flutter).
  Color soft(double opacity) => withAlpha((opacity * 255).round().clamp(0, 255));
}
