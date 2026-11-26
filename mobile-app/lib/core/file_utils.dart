import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';

/// Utilitário para manipulação, validação e compressão de documentos
/// Atende ao RNF04 (JPG, PNG, PDF até 5 MB com compressão automática de fotos de smartphone)
class FileUtils {
  static const int maxFileSizeBytes = 5 * 1024 * 1024; // 5 MB

  /// Formata bytes para exibição amigável (ex.: 1,4 MB, 850 KB)
  static String formatarTamanhoBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      final kb = (bytes / 1024).toStringAsFixed(0);
      return '$kb KB';
    }
    final mb = (bytes / (1024 * 1024)).toStringAsFixed(1).replaceAll('.', ',');
    return '$mb MB';
  }

  /// Verifica se a extensão é suportada
  static bool isExtensaoSuportada(String caminho) {
    final lower = caminho.toLowerCase();
    return lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.pdf');
  }

  /// Verifica se o arquivo é um PDF
  static bool isPdf(String caminho) {
    return caminho.toLowerCase().endsWith('.pdf');
  }

  /// Processa e comprime imagens automaticamente se excederem o limite de 5 MB
  /// Retorna o File pronto para upload ou lança exceção com mensagem clara em PT-BR
  static Future<File> prepararArquivoParaUpload(File arquivoOriginal) async {
    final caminho = arquivoOriginal.path;
    final tamanhoInicial = await arquivoOriginal.length();

    if (!isExtensaoSuportada(caminho)) {
      throw 'Formato não suportado. Envie apenas fotos (JPG, PNG) ou documentos PDF.';
    }

    // Validação estrita para PDF (não é imagem; se passar de 5 MB é rejeitado)
    if (isPdf(caminho)) {
      if (tamanhoInicial > maxFileSizeBytes) {
        throw 'O arquivo PDF excede o limite máximo permitido de 5 MB (${formatarTamanhoBytes(tamanhoInicial)}). '
            'Por favor, gere uma versão com menor resolução.';
      }
      return arquivoOriginal;
    }

    // Para imagens (JPG/PNG): Se já for <= 5 MB, pode enviar diretamente ou apenas otimizar
    if (tamanhoInicial <= maxFileSizeBytes) {
      return arquivoOriginal;
    }

    // Se for uma foto pesada (> 5 MB, ex: 8 MB do CT-06), realiza compressão progressiva
    final tempDir = Directory.systemTemp;
    final targetPath =
        '${tempDir.path}/triasus_compressed_${DateTime.now().millisecondsSinceEpoch}.jpg';

    int qualidade = 85;
    File? arquivoComprimido;

    while (qualidade >= 40) {
      final xfile = await FlutterImageCompress.compressAndGetFile(
        arquivoOriginal.absolute.path,
        targetPath,
        quality: qualidade,
        minWidth: 1920,
        minHeight: 1080,
      );

      if (xfile != null) {
        final comprimido = File(xfile.path);
        final tamanhoComprimido = await comprimido.length();
        if (tamanhoComprimido <= maxFileSizeBytes) {
          arquivoComprimido = comprimido;
          break;
        }
      }
      qualidade -= 15;
    }

    if (arquivoComprimido != null &&
        await arquivoComprimido.length() <= maxFileSizeBytes) {
      return arquivoComprimido;
    }

    // Se ainda assim persistir além de 5 MB
    throw 'A imagem é muito grande mesmo após compressão. Fotografe novamente com menor resolução.';
  }
}
