import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/indicator.dart';

class SabespException implements Exception {
  SabespException(this.message);

  final String message;

  @override
  String toString() => 'SabespException: $message';
}

/// Dados REAIS do Portal dos Mananciais da Sabesp (API pública v4, sem chave).
/// Sistema padrão: 65 = Alto Tietê, que abastece a zona leste de São Paulo.
///
/// ATENÇÃO: o esquema do JSON não é documentado oficialmente. O parser abaixo é
/// tolerante (procura um campo de data e o campo de "volume útil %"), e o app
/// cai para cache/dados sintéticos sinalizados se o formato mudar.
class SabespService {
  SabespService({http.Client? client, this.systemId = 65}) : _client = client ?? http.Client();

  final http.Client _client;
  final int systemId;

  static const String _host = 'mananciais.sabesp.com.br';

  Future<List<DataPoint>> fetchVolumeSeries({int days = 30}) async {
    final lastDate = extractDate(await _get('/api/v4/dados/ultima-data'));
    if (lastDate == null) throw SabespException('data do último dado não encontrada');
    final start = lastDate.subtract(Duration(days: days - 1));
    final body = await _get(
      '/api/v4/sistemas/$systemId/dados/diario/${_iso(start)}/${_iso(lastDate)}',
    );
    return parseDaily(body);
  }

  Future<String> _get(String path) async {
    final response = await _client
        .get(Uri.https(_host, path), headers: {'Accept': 'application/json'})
        .timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) {
      throw SabespException('HTTP ${response.statusCode}');
    }
    return utf8.decode(response.bodyBytes);
  }

  static String _iso(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static final RegExp _isoDate = RegExp(r'(\d{4})-(\d{2})-(\d{2})');
  static final RegExp _brDate = RegExp(r'(\d{2})/(\d{2})/(\d{4})');

  /// Extrai a primeira data (AAAA-MM-DD ou DD/MM/AAAA) de um texto.
  static DateTime? extractDate(String text) {
    final iso = _isoDate.firstMatch(text);
    if (iso != null) {
      return DateTime(int.parse(iso.group(1)!), int.parse(iso.group(2)!), int.parse(iso.group(3)!));
    }
    final br = _brDate.firstMatch(text);
    if (br != null) {
      return DateTime(int.parse(br.group(3)!), int.parse(br.group(2)!), int.parse(br.group(1)!));
    }
    return null;
  }

  static double? _toDouble(dynamic v) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v.trim().replaceAll('%', '').replaceAll(',', '.'));
    return null;
  }

  static int _score(String key) {
    final k = key.toLowerCase();
    var s = 0;
    if (k.contains('volume')) s += 2;
    if (k.contains('util') || k.contains('útil')) s += 2;
    if (k.contains('perc') || k.contains('porcent') || k.contains('pct') || k.contains('%')) s += 2;
    if (k.contains('varia') || k.contains('hm') || k.contains('vaz') || k.contains('chuva')) s -= 5;
    if (k.contains('nivel') || k.contains('nível')) s -= 5;
    return s;
  }

  static void _collectMaps(dynamic node, List<Map<String, dynamic>> out) {
    if (node is Map<String, dynamic>) {
      out.add(node);
      for (final v in node.values) {
        _collectMaps(v, out);
      }
    } else if (node is List) {
      for (final v in node) {
        _collectMaps(v, out);
      }
    }
  }

  /// Converte a série diária da Sabesp em pontos (data, volume útil em %).
  static List<DataPoint> parseDaily(String body) {
    final dynamic json;
    try {
      json = jsonDecode(body);
    } catch (_) {
      throw SabespException('resposta não é JSON');
    }

    final maps = <Map<String, dynamic>>[];
    _collectMaps(json, maps);

    // Registros = mapas que possuem algum campo com data.
    final records = <(DateTime, Map<String, dynamic>)>[];
    for (final m in maps) {
      for (final v in m.values) {
        if (v is String && v.length <= 32) {
          final d = extractDate(v);
          if (d != null) {
            records.add((d, m));
            break;
          }
        }
      }
    }
    if (records.length < 8) throw SabespException('formato inesperado (poucos registros)');

    // Escolhe o campo com maior pontuação para "volume útil %".
    String? bestKey;
    var bestScore = 0;
    for (final entry in records.first.$2.entries) {
      if (_toDouble(entry.value) == null) continue;
      final s = _score(entry.key);
      if (s > bestScore) {
        bestScore = s;
        bestKey = entry.key;
      }
    }
    if (bestKey == null || bestScore < 4) {
      throw SabespException('campo de volume útil não identificado');
    }

    final byDate = <DateTime, double>{};
    for (final r in records) {
      final v = _toDouble(r.$2[bestKey]);
      if (v != null && v >= 0 && v <= 100) byDate[r.$1] = v;
    }
    final dates = byDate.keys.toList()..sort();
    if (dates.length < 8) throw SabespException('série de volume incompleta');
    return [for (final d in dates) DataPoint(d, byDate[d]!)];
  }
}
