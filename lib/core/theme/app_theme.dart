import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_spacing.dart';

/// Temas claro, escuro e de alto contraste.
class AppTheme {
  AppTheme._();

  static ThemeData light({bool highContrast = false}) => _build(Brightness.light, highContrast);

  static ThemeData dark({bool highContrast = false}) => _build(Brightness.dark, highContrast);

  static ThemeData _build(Brightness brightness, bool highContrast) {
    final isDark = brightness == Brightness.dark;

    final ColorScheme scheme;
    if (highContrast) {
      scheme = isDark
          ? const ColorScheme.dark(
              primary: Color(0xFFFFEB3B),
              onPrimary: Colors.black,
              secondary: Color(0xFF80F0FF),
              onSecondary: Colors.black,
              surface: Colors.black,
              onSurface: Colors.white,
              error: Color(0xFFFF8A80),
              onError: Colors.black,
              outline: Colors.white,
              outlineVariant: Colors.white70,
            )
          : const ColorScheme.light(
              primary: Color(0xFF003C38),
              onPrimary: Colors.white,
              secondary: Colors.black,
              onSecondary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
              error: Color(0xFF8C0009),
              onError: Colors.white,
              outline: Colors.black,
              outlineVariant: Colors.black87,
            );
    } else {
      scheme = ColorScheme.fromSeed(seedColor: AppColors.primary, brightness: brightness).copyWith(
        primary: isDark ? AppColors.primaryOnDark : AppColors.primary,
        onPrimary: isDark ? const Color(0xFF00201E) : Colors.white,
        surface: isDark ? const Color(0xFF1B2222) : Colors.white,
        error: AppColors.criticalOf(brightness),
      );
    }

    final scaffold = highContrast
        ? scheme.surface
        : (isDark ? const Color(0xFF0E1212) : const Color(0xFFF1F5F5));

    final base = ThemeData(useMaterial3: true, colorScheme: scheme, scaffoldBackgroundColor: scaffold);

    return base.copyWith(
      textTheme: base.textTheme.copyWith(
        headlineSmall: base.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
        titleLarge: base.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        titleMedium: base.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: scaffold,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radius)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radius)),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surface,
        indicatorColor: scheme.primary.soft(0.18),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
    );
  }
}
