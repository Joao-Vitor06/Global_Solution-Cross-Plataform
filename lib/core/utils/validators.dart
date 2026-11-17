/// Validações dos formulários e detecção de dados pessoais (privacidade).
class Validators {
  Validators._();

  static final RegExp _email = RegExp(r'[\w.+-]+@[\w-]+\.[\w.]+');
  static final RegExp _phone = RegExp(r'\+?\d[\d\s().-]{8,}\d');
  static final RegExp _cpf = RegExp(r'\d{3}\.?\d{3}\.?\d{3}-?\d{2}');

  static bool containsPersonalData(String text) =>
      _email.hasMatch(text) || _phone.hasMatch(text) || _cpf.hasMatch(text);

  static String? description(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return 'Descreva a ocorrência.';
    if (text.length < 10) return 'Use ao menos 10 caracteres para descrever.';
    if (text.length > 280) return 'Máximo de 280 caracteres.';
    if (containsPersonalData(text)) {
      return 'Remova dados pessoais (e-mail, telefone ou CPF).';
    }
    return null;
  }

  /// Aceita "12,5" ou "12.5".
  static double? parseNumber(String? value) {
    if (value == null) return null;
    return double.tryParse(value.trim().replaceAll(',', '.'));
  }

  static String? number(String? value, {required double min, required double max}) {
    final parsed = parseNumber(value);
    if (parsed == null) return 'Informe um número válido.';
    if (parsed < min || parsed > max) {
      return 'Use um valor entre ${min.toStringAsFixed(0)} e ${max.toStringAsFixed(0)}.';
    }
    return null;
  }
}
