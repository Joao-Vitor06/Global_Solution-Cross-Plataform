import 'package:flutter/material.dart';

import '../models/thresholds.dart';
import '../services/storage_service.dart';

/// Estado global de preferências, consentimento e limiares de alerta.
class SettingsProvider extends ChangeNotifier {
  SettingsProvider(this._storage)
      : _themeMode = ThemeMode.values[_storage.themeModeIndex.clamp(0, ThemeMode.values.length - 1).toInt()],
        _highContrast = _storage.highContrast,
        _fontScale = _storage.fontScale,
        _consent = _storage.consent,
        _thresholds = _storage.loadThresholds();

  final StorageService _storage;

  ThemeMode _themeMode;
  bool _highContrast;
  double _fontScale;
  bool _consent;
  Thresholds _thresholds;

  ThemeMode get themeMode => _themeMode;
  bool get highContrast => _highContrast;
  double get fontScale => _fontScale;
  bool get consent => _consent;
  Thresholds get thresholds => _thresholds;

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    await _storage.saveThemeModeIndex(mode.index);
  }

  Future<void> setHighContrast(bool value) async {
    _highContrast = value;
    notifyListeners();
    await _storage.saveHighContrast(value);
  }

  Future<void> setFontScale(double value) async {
    _fontScale = value;
    notifyListeners();
    await _storage.saveFontScale(value);
  }

  Future<void> giveConsent() async {
    _consent = true;
    notifyListeners();
    await _storage.saveConsent(true);
  }

  Future<void> revokeConsent() async {
    _consent = false;
    notifyListeners();
    await _storage.saveConsent(false);
  }

  Future<void> saveThresholds(Thresholds value) async {
    _thresholds = value;
    notifyListeners();
    await _storage.saveThresholds(value);
  }

  Future<void> resetThresholds() => saveThresholds(Thresholds.defaults());
}
