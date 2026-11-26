/// Validadores de documentos brasileiros e campos do cidadão
class DocumentValidators {
  /// Remove caracteres não numéricos
  static String apenasDigitos(String? valor) {
    if (valor == null) return '';
    return valor.replaceAll(RegExp(r'\D'), '');
  }

  /// Valida CPF com cálculo dos dois dígitos verificadores
  static bool validarCPF(String? cpf) {
    final digitos = apenasDigitos(cpf);
    if (digitos.length != 11) return false;

    // Rejeita sequências de dígitos iguais (ex: 111.111.111-11)
    if (RegExp(r'^(\d)\1{10}$').hasMatch(digitos)) return false;

    // Cálculo do primeiro dígito verificador
    int soma1 = 0;
    for (int i = 0; i < 9; i++) {
      soma1 += int.parse(digitos[i]) * (10 - i);
    }
    int resto1 = (soma1 * 10) % 11;
    if (resto1 == 10 || resto1 == 11) resto1 = 0;
    if (resto1 != int.parse(digitos[9])) return false;

    // Cálculo do segundo dígito verificador
    int soma2 = 0;
    for (int i = 0; i < 10; i++) {
      soma2 += int.parse(digitos[i]) * (11 - i);
    }
    int resto2 = (soma2 * 10) % 11;
    if (resto2 == 10 || resto2 == 11) resto2 = 0;
    if (resto2 != int.parse(digitos[10])) return false;

    return true;
  }

  /// Valida Cartão Nacional de Saúde (CNS - 15 dígitos)
  static bool validarCNS(String? cns) {
    final digitos = apenasDigitos(cns);
    if (digitos.length != 15) return false;
    // O CNS deve conter 15 dígitos numéricos
    return RegExp(r'^[0-9]{15}$').hasMatch(digitos);
  }

  /// Valida data no formato DD/MM/AAAA
  static bool validarDataNascimento(String? data) {
    if (data == null || data.length != 10) return false;
    final partes = data.split('/');
    if (partes.length != 3) return false;

    final dia = int.tryParse(partes[0]);
    final mes = int.tryParse(partes[1]);
    final ano = int.tryParse(partes[2]);

    if (dia == null || mes == null || ano == null) return false;
    if (ano < 1900 || ano > DateTime.now().year) return false;
    if (mes < 1 || mes > 12) return false;

    try {
      final parsed = DateTime(ano, mes, dia);
      if (parsed.year != ano || parsed.month != mes || parsed.day != dia) {
        return false;
      }
      if (parsed.isAfter(DateTime.now())) return false;
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Converte data DD/MM/AAAA para formato ISO AAAA-MM-DD para o Spring Boot
  static String? converterParaIso(String dataFormatada) {
    final partes = dataFormatada.split('/');
    if (partes.length == 3) {
      return '${partes[2]}-${partes[1].padLeft(2, '0')}-${partes[0].padLeft(2, '0')}';
    }
    return null;
  }
}
