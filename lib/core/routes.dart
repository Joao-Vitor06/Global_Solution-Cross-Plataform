import 'package:flutter/material.dart';

import '../models/indicator.dart';
import '../screens/alert_detail_screen.dart';
import '../screens/consent_screen.dart';
import '../screens/home_shell.dart';
import '../screens/indicator_detail_screen.dart';
import '../screens/occurrence_form_screen.dart';
import '../screens/privacy_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/thresholds_screen.dart';

/// Nomes das rotas do app.
class Routes {
  Routes._();

  static const String consent = '/consent';
  static const String home = '/home';
  static const String indicator = '/indicator';
  static const String alert = '/alert';
  static const String occurrenceNew = '/occurrence/new';
  static const String thresholds = '/thresholds';
  static const String privacy = '/privacy';
  static const String settings = '/settings';
}

/// Resolve rotas nomeadas e valida os parâmetros recebidos.
class AppRouter {
  AppRouter._();

  static Route<dynamic> generate(RouteSettings settings) {
    final args = settings.arguments;
    switch (settings.name) {
      case Routes.consent:
        return _page(const ConsentScreen(), settings);
      case Routes.indicator:
        if (args is IndicatorType) {
          return _page(IndicatorDetailScreen(type: args), settings);
        }
        return _page(const HomeShell(), settings);
      case Routes.alert:
        if (args is String) {
          return _page(AlertDetailScreen(alertId: args), settings);
        }
        return _page(const HomeShell(), settings);
      case Routes.occurrenceNew:
        return _page(const OccurrenceFormScreen(), settings);
      case Routes.thresholds:
        return _page(const ThresholdsScreen(), settings);
      case Routes.privacy:
        return _page(const PrivacyScreen(), settings);
      case Routes.settings:
        return _page(const SettingsScreen(), settings);
      case Routes.home:
      default:
        return _page(const HomeShell(), settings);
    }
  }

  static MaterialPageRoute<dynamic> _page(Widget child, RouteSettings settings) {
    return MaterialPageRoute<dynamic>(builder: (_) => child, settings: settings);
  }
}
