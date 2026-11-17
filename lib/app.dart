import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/routes.dart';
import 'core/theme/app_theme.dart';
import 'providers/occurrences_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/territory_provider.dart';
import 'services/storage_service.dart';

/// Raiz do app: injeta os providers globais e configura tema e rotas.
class TerraSenseApp extends StatelessWidget {
  const TerraSenseApp({super.key, required this.storage});

  final StorageService storage;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<SettingsProvider>(create: (_) => SettingsProvider(storage)),
        ChangeNotifierProvider<OccurrencesProvider>(create: (_) => OccurrencesProvider(storage)),
        ChangeNotifierProvider<TerritoryProvider>(
          lazy: false,
          create: (ctx) => TerritoryProvider(
            settings: ctx.read<SettingsProvider>(),
            storage: storage,
          )..load(),
        ),
      ],
      child: _AppView(initialRoute: storage.consent ? Routes.home : Routes.consent),
    );
  }
}

class _AppView extends StatelessWidget {
  const _AppView({required this.initialRoute});

  final String initialRoute;

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    return MaterialApp(
      title: 'TerraSense',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(highContrast: settings.highContrast),
      darkTheme: AppTheme.dark(highContrast: settings.highContrast),
      themeMode: settings.themeMode,
      locale: const Locale('pt', 'BR'),
      supportedLocales: const [Locale('pt', 'BR')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        // Combina o tamanho de fonte do sistema com o ajuste do app.
        final mq = MediaQuery.of(context);
        final scale = (mq.textScaler.scale(1.0) * settings.fontScale).clamp(0.8, 2.2).toDouble();
        return MediaQuery(
          data: mq.copyWith(textScaler: TextScaler.linear(scale)),
          child: child ?? const SizedBox.shrink(),
        );
      },
      initialRoute: initialRoute,
      onGenerateRoute: AppRouter.generate,
    );
  }
}
