import 'package:flutter_test/flutter_test.dart';
import 'package:territory_insights/core/utils/validators.dart';

void main() {
  group('Validators.description', () {
    test('rejeita vazio e texto curto', () {
      expect(Validators.description(''), isNotNull);
      expect(Validators.description('curto'), isNotNull);
    });

    test('aceita descrição válida', () {
      expect(Validators.description('Vazamento na rua principal há dois dias'), isNull);
    });

    test('bloqueia e-mail, telefone e CPF', () {
      expect(Validators.description('Fale comigo em maria@email.com por favor'), isNotNull);
      expect(Validators.description('Meu telefone é (11) 91234-5678 para contato'), isNotNull);
      expect(Validators.description('Meu CPF é 123.456.789-09 para registro'), isNotNull);
    });

    test('rejeita mais de 280 caracteres', () {
      expect(Validators.description('a' * 281), isNotNull);
    });
  });

  group('Validators.number', () {
    test('aceita vírgula decimal e respeita limites', () {
      expect(Validators.parseNumber('12,5'), 12.5);
      expect(Validators.number('180,5', min: 50, max: 500), isNull);
      expect(Validators.number('abc', min: 50, max: 500), isNotNull);
      expect(Validators.number('10', min: 50, max: 500), isNotNull);
      expect(Validators.number('900', min: 50, max: 500), isNotNull);
    });
  });
}
