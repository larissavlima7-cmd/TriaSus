import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:triasus_app/core/file_utils.dart';
import 'package:triasus_app/core/validators.dart';

void main() {
  group('Validações de Documentos e Campos (DocumentValidators)', () {
    test('Deve validar CPFs reais válidos', () {
      // CPF da cidadã de teste do seed
      expect(DocumentValidators.validarCPF('39053344705'), isTrue);
      expect(DocumentValidators.validarCPF('390.533.447-05'), isTrue);
    });

    test('Deve rejeitar CPFs com dígitos verificadores inválidos ou repetidos', () {
      expect(DocumentValidators.validarCPF('11111111111'), isFalse);
      expect(DocumentValidators.validarCPF('00000000000'), isFalse);
      expect(DocumentValidators.validarCPF('12345678900'), isFalse);
      expect(DocumentValidators.validarCPF('39053344799'), isFalse);
      expect(DocumentValidators.validarCPF('123'), isFalse);
    });

    test('Deve validar CNS (Cartão Nacional de Saúde) com exatamente 15 dígitos', () {
      expect(DocumentValidators.validarCNS('700000000000001'), isTrue);
      expect(DocumentValidators.validarCNS('70000000000000'), isFalse); // 14 dígitos
      expect(DocumentValidators.validarCNS('7000000000000012'), isFalse); // 16 dígitos
      expect(DocumentValidators.validarCNS('abc123456789012'), isFalse);
    });

    test('Deve validar datas de nascimento e converter para ISO', () {
      expect(DocumentValidators.validarDataNascimento('14/03/1958'), isTrue);
      expect(DocumentValidators.validarDataNascimento('31/02/1990'), isFalse); // dia inválido
      expect(DocumentValidators.validarDataNascimento('15/13/1980'), isFalse); // mês inválido
      expect(DocumentValidators.validarDataNascimento('01/01/2999'), isFalse); // data futura

      expect(DocumentValidators.converterParaIso('14/03/1958'), equals('1958-03-14'));
    });
  });

  group('Utilitários de Arquivo e Limite de 5 MB (FileUtils - RNF04 / CT-06)', () {
    test('Deve formatar tamanho em bytes corretamente', () {
      expect(FileUtils.formatarTamanhoBytes(500), equals('500 B'));
      expect(FileUtils.formatarTamanhoBytes(1024), equals('1 KB'));
      expect(FileUtils.formatarTamanhoBytes(1468006), equals('1,4 MB'));
      expect(FileUtils.formatarTamanhoBytes(5242880), equals('5,0 MB'));
    });

    test('Deve validar extensões suportadas', () {
      expect(FileUtils.isExtensaoSuportada('exame.pdf'), isTrue);
      expect(FileUtils.isExtensaoSuportada('foto.jpg'), isTrue);
      expect(FileUtils.isExtensaoSuportada('imagem.png'), isTrue);
      expect(FileUtils.isExtensaoSuportada('documento.docx'), isFalse);
      expect(FileUtils.isExtensaoSuportada('arquivo.exe'), isFalse);
    });

    test('Deve rejeitar PDF que ultrapasse 5 MB', () async {
      // Simula arquivo temporário maior que 5 MB
      final tempDir = Directory.systemTemp;
      final tempPdf = File('${tempDir.path}/teste_grande.pdf');
      
      // Cria arquivo com 5.5 MB (5.5 * 1024 * 1024 bytes)
      final bytes = List<int>.filled(5767168, 0);
      await tempPdf.writeAsBytes(bytes);

      try {
        expect(
          () => FileUtils.prepararArquivoParaUpload(tempPdf),
          throwsA(contains('5 MB')),
        );
      } finally {
        if (tempPdf.existsSync()) {
          tempPdf.deleteSync();
        }
      }
    });
  });
}
