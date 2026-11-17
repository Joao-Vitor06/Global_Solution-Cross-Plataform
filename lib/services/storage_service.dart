import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/alert_model.dart';
import '../models/environment_data.dart';
import '../models/indicator.dart';
import '../models/occurrence.dart';
import '../models/thresholds.dart';

/// Persistência local (SharedPreferences): consentimento, preferências, limiares,
/// ocorrências, decisões humanas e cache do clima para uso offline.
class StorageService {
  StorageService(this._prefs);

  final SharedPreferences _prefs;

  static Future<StorageService> create() async => StorageService(await SharedPreferences.getInstance());

  static const _kConsent = 'consent_v1';
  static const _kTheme = 'theme_mode';
  static const _kContrast = 'high_contrast';
  static const _kFont = 'font_scale';
  static const _kThresholds = 'thresholds_v1';
  static const _kOccurrences = 'occurrences_v1';
  static const _kDecisions = 'alert_decisions_v1';
  static const _kEnvironment = 'environment_cache_v1';
  static const _kWater = 'water_cache_v1';

  // Consentimento
  bool get consent => _prefs.getBool(_kConsent) ?? false;
  Future<void> saveConsent(bool value) => _prefs.setBool(_kConsent, value);

  // Preferências
  int get themeModeIndex => _prefs.getInt(_kTheme) ?? 0;
  Future<void> saveThemeModeIndex(int value) => _prefs.setInt(_kTheme, value);

  bool get highContrast => _prefs.getBool(_kContrast) ?? false;
  Future<void> saveHighContrast(bool value) => _prefs.setBool(_kContrast, value);

  double get fontScale => _prefs.getDouble(_kFont) ?? 1.0;
  Future<void> saveFontScale(double value) => _prefs.setDouble(_kFont, value);

  // Limiares
  Thresholds loadThresholds() {
    final raw = _prefs.getString(_kThresholds);
    if (raw == null) return Thresholds.defaults();
    try {
      return Thresholds.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return Thresholds.defaults();
    }
  }

  Future<void> saveThresholds(Thresholds value) =>
      _prefs.setString(_kThresholds, jsonEncode(value.toJson()));

  // Ocorrências
  List<Occurrence> loadOccurrences() {
    final raw = _prefs.getString(_kOccurrences);
    if (raw == null) return [];
    try {
      return (jsonDecode(raw) as List)
          .map((e) => Occurrence.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveOccurrences(List<Occurrence> items) =>
      _prefs.setString(_kOccurrences, jsonEncode(items.map((e) => e.toJson()).toList()));

  // Decisões humanas sobre alertas
  Map<String, AlertDecision> loadDecisions() {
    final raw = _prefs.getString(_kDecisions);
    if (raw == null) return {};
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return {
        for (final e in map.entries)
          e.key: AlertDecision.values.firstWhere(
            (d) => d.name == e.value,
            orElse: () => AlertDecision.pending,
          ),
      };
    } catch (_) {
      return {};
    }
  }

  Future<void> saveDecisions(Map<String, AlertDecision> decisions) => _prefs.setString(
        _kDecisions,
        jsonEncode({for (final e in decisions.entries) e.key: e.value.name}),
      );

  // Cache de dados reais (uso offline)
  Future<void> saveEnvironmentCache(EnvironmentData data) =>
      _prefs.setString(_kEnvironment, jsonEncode(data.toJson()));

  EnvironmentData? loadEnvironmentCache() {
    final raw = _prefs.getString(_kEnvironment);
    if (raw == null) return null;
    try {
      return EnvironmentData.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveWaterCache(List<DataPoint> points, DateTime fetchedAt) => _prefs.setString(
        _kWater,
        jsonEncode({
          'fetchedAt': fetchedAt.toIso8601String(),
          'points': points.map((p) => p.toJson()).toList(),
        }),
      );

  ({List<DataPoint> points, DateTime fetchedAt})? loadWaterCache() {
    final raw = _prefs.getString(_kWater);
    if (raw == null) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final points = (map['points'] as List)
          .map((e) => DataPoint.fromJson(e as Map<String, dynamic>))
          .toList();
      if (points.isEmpty) return null;
      return (points: points, fetchedAt: DateTime.parse(map['fetchedAt'] as String));
    } catch (_) {
      return null;
    }
  }

  /// Apaga ocorrências e decisões humanas (dados gerados pelo usuário).
  Future<void> clearUserData() async {
    await _prefs.remove(_kOccurrences);
    await _prefs.remove(_kDecisions);
  }
}
