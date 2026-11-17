import 'package:flutter_test/flutter_test.dart';
import 'package:territory_insights/services/open_meteo_service.dart';
import 'package:territory_insights/services/sabesp_service.dart';

void main() {
  group('OpenMeteoService (formato documentado da API)', () {
    test('parseDailyMax lê temperatura e ignora valores nulos', () {
      final points = OpenMeteoService.parseDailyMax({
        'daily': {
          'time': ['2026-11-09', '2026-11-10', '2026-11-11'],
          'temperature_2m_max': [29.5, null, 31.2],
        },
      });
      expect(points.length, 2);
      expect(points.last.value, 31.2);
    });

    test('parseAirDailyMean calcula a média diária do PM2,5', () {
      final points = OpenMeteoService.parseAirDailyMean({
        'hourly': {
          'time': ['2026-11-10T00:00', '2026-11-10T01:00', '2026-11-11T00:00'],
          'pm2_5': [10.0, 20.0, null],
        },
      });
      expect(points.length, 1);
      expect(points.first.value, 15.0);
    });

    test('asLocations aceita objeto único ou lista', () {
      expect(OpenMeteoService.asLocations({'a': 1}).length, 1);
      expect(OpenMeteoService.asLocations([{'a': 1}, {'b': 2}]).length, 2);
    });
  });

  group('SabespService (parser tolerante)', () {
    test('extractDate reconhece ISO e formato brasileiro', () {
      expect(SabespService.extractDate('{"data":"2026-11-10"}'), DateTime(2026, 11, 10));
      expect(SabespService.extractDate('06/11/2026'), DateTime(2026, 11, 6));
      expect(SabespService.extractDate('sem data'), isNull);
    });

    test('parseDaily escolhe o campo de volume útil em %', () {
      final rows = [
        for (var i = 0; i < 10; i++)
          '{"data":"2026-11-${(i + 1).toString().padLeft(2, '0')}","volumeUtilPercentual":${60 - i},"chuva":${i * 2},"nivel":700}',
      ];
      final points = SabespService.parseDaily('{"dados":[${rows.join(',')}]}');
      expect(points.length, 10);
      expect(points.first.value, 60);
      expect(points.last.value, 51);
    });

    test('parseDaily lê o formato real da API v4 da Sabesp', () {
      final rows = [
        for (var i = 0; i < 10; i++)
          '{"idSistema":65,"date":"2026-11-${(i + 1).toString().padLeft(2, '0')}T00:00:00","chuva":0.0,"nivel":null,"volume":null,'
              '"volumeUtilArmazenadoPorcentagem":${60.3 + i * 0.1},"volumeUtilArmazenadoHm3":338.1,"volumeTotalArmazenado":417.7,'
              '"variacaoVolumeUtil":0.13,"chuvaMediaHistorica":116.6}',
      ];
      final points = SabespService.parseDaily(
        '{"data":[${rows.join(',')}],"succeeded":true,"errors":[],"message":""}',
      );
      expect(points.length, 10);
      expect(points.first.value, closeTo(60.3, 1e-9));
      expect(points.first.date, DateTime(2026, 11, 1));
    });

    test('parseDaily falha com erro claro quando o formato é desconhecido', () {
      expect(() => SabespService.parseDaily('{"x":1}'), throwsA(isA<SabespException>()));
      expect(() => SabespService.parseDaily('não é json'), throwsA(isA<SabespException>()));
    });
  });
}
