import 'package:flutter/foundation.dart';

import '../domain/alert_engine.dart';
import '../models/alert_model.dart';
import '../models/environment_data.dart';
import '../models/indicator.dart';
import '../models/thresholds.dart';
import '../models/zone.dart';
import '../services/open_meteo_service.dart';
import '../services/sabesp_service.dart';
import '../services/storage_service.dart';
import '../services/synthetic_data_service.dart';
import 'settings_provider.dart';

enum LoadStatus { loading, ready, error }

/// Estado global do território: indicadores, alertas, zonas do mapa e decisões humanas.
class TerritoryProvider extends ChangeNotifier {
  TerritoryProvider({
    required SettingsProvider settings,
    required StorageService storage,
    SyntheticDataService? synthetic,
    OpenMeteoService? openMeteo,
    SabespService? sabesp,
  })  : _settings = settings,
        _storage = storage,
        _synthetic = synthetic ?? const SyntheticDataService(),
        _openMeteo = openMeteo ?? OpenMeteoService(),
        _sabesp = sabesp ?? SabespService(),
        _decisions = storage.loadDecisions() {
    _lastThresholds = settings.thresholds;
    _settings.addListener(_onSettingsChanged);
  }

  final SettingsProvider _settings;
  final StorageService _storage;
  final SyntheticDataService _synthetic;
  final OpenMeteoService _openMeteo;
  final SabespService _sabesp;
  final Map<String, AlertDecision> _decisions;
  late Thresholds _lastThresholds;

  LoadStatus _status = LoadStatus.loading;
  String? _errorMessage;
  List<String> _notices = [];
  List<Indicator> _indicators = [];
  List<TerritoryAlert> _alerts = [];
  List<ZoneReading> _zones = [];
  EnvironmentData? _environment;
  DateTime? _lastUpdated;

  LoadStatus get status => _status;
  String? get errorMessage => _errorMessage;

  /// Avisos não bloqueantes (ex.: modo offline, fonte indisponível).
  List<String> get notices => List.unmodifiable(_notices);
  List<Indicator> get indicators => List.unmodifiable(_indicators);
  List<TerritoryAlert> get alerts => List.unmodifiable(_alerts);
  List<ZoneReading> get zones => List.unmodifiable(_zones);
  DateTime? get lastUpdated => _lastUpdated;
  Map<String, AlertDecision> get decisions => Map.unmodifiable(_decisions);

  int get pendingCount => _alerts.where((a) => decisionOf(a.id) == AlertDecision.pending).length;

  int get realIndicatorCount => _indicators.where((i) => i.isReal).length;

  Indicator? indicatorOf(IndicatorType type) {
    for (final i in _indicators) {
      if (i.type == type) return i;
    }
    return null;
  }

  TerritoryAlert? alertById(String id) {
    for (final a in _alerts) {
      if (a.id == id) return a;
    }
    return null;
  }

  List<TerritoryAlert> alertsFor(IndicatorType type) =>
      _alerts.where((a) => a.indicatorType == type).toList();

  AlertDecision decisionOf(String alertId) => _decisions[alertId] ?? AlertDecision.pending;

  Future<void> load() async {
    _status = LoadStatus.loading;
    _errorMessage = null;
    notifyListeners();
    try {
      final notices = <String>[];
      final simulated = await _synthetic.fetchEnergyAndWaste();
      final water = await _loadWater(notices);
      final env = await _loadEnvironment(notices);
      final all = [water, ...simulated, ...env];
      _indicators = [
        for (final type in IndicatorType.values) all.firstWhere((i) => i.type == type),
      ];
      _notices = notices;
      _recompute();
      _lastUpdated = DateTime.now();
      _status = LoadStatus.ready;
    } catch (_) {
      _status = LoadStatus.error;
      _errorMessage = 'Não foi possível carregar os dados do território. Tente novamente.';
    }
    notifyListeners();
  }

  /// Volume dos mananciais: API da Sabesp -> cache -> sintético sinalizado.
  Future<Indicator> _loadWater(List<String> notices) async {
    final now = DateTime.now();
    try {
      final points = await _sabesp.fetchVolumeSeries();
      await _storage.saveWaterCache(points, now);
      return Indicator(
        type: IndicatorType.water,
        points: points,
        source: DataSource.sabesp,
        fetchedAt: now,
      );
    } catch (e) {
      final reason = e is SabespException ? e.message : 'sem conexão';
      final cached = _storage.loadWaterCache();
      if (cached != null) {
        notices.add('Sabesp indisponível ($reason): volume dos mananciais exibido a partir do cache local.');
        return Indicator(
          type: IndicatorType.water,
          points: cached.points,
          source: DataSource.cache,
          fetchedAt: cached.fetchedAt,
        );
      }
      notices.add('Sabesp indisponível ($reason): volume dos mananciais exibido com dados sintéticos de demonstração.');
      return _synthetic.fallbackWater();
    }
  }

  /// Clima e qualidade do ar (Open-Meteo): API -> cache -> sintético sinalizado.
  Future<List<Indicator>> _loadEnvironment(List<String> notices) async {
    final now = DateTime.now();
    EnvironmentData? data;
    var source = DataSource.openMeteo;
    try {
      data = await _openMeteo.fetchZones();
      await _storage.saveEnvironmentCache(data);
    } catch (_) {
      data = _storage.loadEnvironmentCache();
      source = DataSource.cache;
      notices.add(data != null
          ? 'Sem conexão: clima, ar e mapa exibidos a partir do cache local.'
          : 'Sem conexão e sem cache: clima e ar usam dados sintéticos e o mapa fica sem leituras.');
    }
    _environment = data;

    final main = data?.zones[Zones.main.id];
    final fetchedAt = data?.fetchedAt ?? now;

    final climate = main != null && main.temps.isNotEmpty
        ? Indicator(type: IndicatorType.climate, points: main.temps, source: source, fetchedAt: fetchedAt)
        : _synthetic.fallbackClimate();

    final Indicator air;
    if (main != null && main.pm25.length >= 5) {
      air = Indicator(type: IndicatorType.air, points: main.pm25, source: source, fetchedAt: fetchedAt);
    } else {
      if (data != null) notices.add('Qualidade do ar indisponível na API: exibindo dados sintéticos.');
      air = _synthetic.fallbackAir();
    }
    return [climate, air];
  }

  Future<void> setDecision(String alertId, AlertDecision decision) async {
    _decisions[alertId] = decision;
    notifyListeners();
    await _storage.saveDecisions(_decisions);
  }

  Future<void> clearDecisions() async {
    _decisions.clear();
    notifyListeners();
    await _storage.saveDecisions(_decisions);
  }

  void _recompute() {
    final thresholds = _settings.thresholds;
    _alerts = AlertEngine.generate(_indicators, thresholds);
    _zones = [
      for (final zone in Zones.all) _readingFor(zone, thresholds),
    ];
  }

  ZoneReading _readingFor(Zone zone, Thresholds thresholds) {
    final series = _environment?.zones[zone.id];
    final temp = (series != null && series.temps.isNotEmpty) ? series.temps.last : null;
    final pm = (series != null && series.pm25.isNotEmpty) ? series.pm25.last : null;
    return ZoneReading(
      zone: zone,
      tempMax: temp?.value,
      pm25: pm?.value,
      date: temp?.date,
      status: ZoneReading.statusFor(
        temp: temp?.value,
        pm25: pm?.value,
        tempThreshold: thresholds.of(IndicatorType.climate),
        airThreshold: thresholds.of(IndicatorType.air),
      ),
    );
  }

  void _onSettingsChanged() {
    if (identical(_lastThresholds, _settings.thresholds)) return;
    _lastThresholds = _settings.thresholds;
    if (_status == LoadStatus.ready) {
      _recompute();
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _settings.removeListener(_onSettingsChanged);
    super.dispose();
  }
}
