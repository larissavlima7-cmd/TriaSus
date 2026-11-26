import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../core/file_utils.dart';
import '../../core/font_scale.dart';
import '../../models/models.dart';
import '../../services/especialidade_service.dart';
import '../../services/solicitacao_service.dart';

class ChecklistScreen extends StatefulWidget {
  final int solicitacaoId;

  const ChecklistScreen({super.key, required this.solicitacaoId});

  @override
  State<ChecklistScreen> createState() => _ChecklistScreenState();
}

class _ChecklistScreenState extends State<ChecklistScreen> {
  SolicitacaoModel? _solicitacao;
  List<ChecklistItemModel> _checklist = [];
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _erroGeral;

  // Mapa de uploads em andamento por itemChecklistId (porcentagem 0.0 a 1.0)
  final Map<int, double> _progressoUpload = {};

  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    setState(() {
      _isLoading = true;
      _erroGeral = null;
    });

    try {
      final solicitacaoService = context.read<ISolicitacaoService>();
      final especialidadeService = context.read<IEspecialidadeService>();

      final s =
          await solicitacaoService.getSolicitacaoById(widget.solicitacaoId);
      final c = await especialidadeService
          .getChecklistByEspecialidade(s.especialidadeId);

      if (mounted) {
        setState(() {
          _solicitacao = s;
          _checklist = c;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _erroGeral = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  DocumentoAnexoModel? _getDocumentoAnexado(int itemChecklistId) {
    if (_solicitacao == null) return null;
    try {
      return _solicitacao!.documentos.firstWhere(
        (d) => d.itemChecklistId == itemChecklistId,
      );
    } catch (_) {
      return null;
    }
  }

  // Verifica se faltam itens obrigatórios
  bool get _podeEnviar {
    if (_solicitacao == null || _checklist.isEmpty) return false;
    for (final item in _checklist) {
      if (item.obrigatorio && _getDocumentoAnexado(item.id) == null) {
        return false;
      }
    }
    return true;
  }

  int get _totalObrigatorios => _checklist.where((c) => c.obrigatorio).length;

  int get _obrigatoriosAnexados {
    int total = 0;
    for (final item in _checklist) {
      if (item.obrigatorio && _getDocumentoAnexado(item.id) != null) {
        total++;
      }
    }
    return total;
  }

  int get _totalAnexados {
    int total = 0;
    for (final item in _checklist) {
      if (_getDocumentoAnexado(item.id) != null) {
        total++;
      }
    }
    return total;
  }

  void _abrirOpcoesAnexo(ChecklistItemModel item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Anexar: ${item.nomeDocumento}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Selecione uma foto da câmera/galeria ou um arquivo PDF de até 5 MB:',
                  style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 18),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.camera_alt_outlined,
                        color: Color(0xFF007A48)),
                  ),
                  title: const Text('Tirar foto com a câmera',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Com compressão automática até 5 MB'),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _capturarFoto(item, ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.photo_library_outlined,
                        color: Color(0xFF007A48)),
                  ),
                  title: const Text('Escolher foto da galeria',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _capturarFoto(item, ImageSource.gallery);
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.picture_as_pdf_outlined,
                        color: Color(0xFF007A48)),
                  ),
                  title: const Text('Selecionar arquivo PDF',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Limite máximo de 5 MB'),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _selecionarPdf(item);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _capturarFoto(
      ChecklistItemModel item, ImageSource source) async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 2560,
        maxHeight: 1440,
        imageQuality: 90,
      );

      if (pickedFile == null) return;

      final arquivoOriginal = File(pickedFile.path);
      await _processarEUploadArquivo(item, arquivoOriginal);
    } catch (e) {
      if (!mounted) return;
      _tratarErroPermissaoOuCaptura(e.toString());
    }
  }

  Future<void> _selecionarPdf(ChecklistItemModel item) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result == null || result.files.isEmpty) return;

      final path = result.files.single.path;
      if (path == null) return;

      final arquivoOriginal = File(path);
      await _processarEUploadArquivo(item, arquivoOriginal);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao selecionar PDF: $e'),
          backgroundColor: const Color(0xFFBA1A1A),
        ),
      );
    }
  }

  void _tratarErroPermissaoOuCaptura(String erro) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Permissão Necessária'),
        content: Text(
          'Para fotografar ou anexar documentos para a UBS, o app necessita de acesso à câmera e galeria de mídia.\n\nDetalhes: $erro',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _processarEUploadArquivo(
      ChecklistItemModel item, File arquivoOriginal) async {
    setState(() {
      _erroGeral = null;
      _progressoUpload[item.id] = 0.05;
    });

    try {
      // Compressão / Otimização conforme RNF04 e CT-06
      final arquivoPronto =
          await FileUtils.prepararArquivoParaUpload(arquivoOriginal);

      if (!mounted) return;
      final service = context.read<ISolicitacaoService>();
      final docCriado = await service.uploadDocumento(
        solicitacaoId: widget.solicitacaoId,
        itemChecklistId: item.id,
        filePath: arquivoPronto.path,
        onProgress: (sent, total) {
          if (mounted && total > 0) {
            setState(() {
              _progressoUpload[item.id] = sent / total;
            });
          }
        },
      );

      if (mounted) {
        // Atualiza a solicitação localmente com o novo documento
        final docsAtualizados =
            List<DocumentoAnexoModel>.from(_solicitacao!.documentos)
              ..removeWhere((d) => d.itemChecklistId == item.id)
              ..add(docCriado);

        setState(() {
          _progressoUpload.remove(item.id);
          _solicitacao = SolicitacaoModel(
            id: _solicitacao!.id,
            protocolo: _solicitacao!.protocolo,
            pacienteId: _solicitacao!.pacienteId,
            especialidadeId: _solicitacao!.especialidadeId,
            especialidadeNome: _solicitacao!.especialidadeNome,
            unidadeId: _solicitacao!.unidadeId,
            unidadeNome: _solicitacao!.unidadeNome,
            dataSolicitacao: _solicitacao!.dataSolicitacao,
            status: _solicitacao!.status,
            prioridadeOficial: _solicitacao!.prioridadeOficial,
            queixaRelatada: _solicitacao!.queixaRelatada,
            tempoEvolucao: _solicitacao!.tempoEvolucao,
            observacaoProfissional: _solicitacao!.observacaoProfissional,
            documentos: docsAtualizados,
          );
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${item.nomeDocumento} anexado com sucesso!'),
            backgroundColor: const Color(0xFF007A48),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _progressoUpload.remove(item.id);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: const Color(0xFFBA1A1A),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Future<void> _removerDocumento(DocumentoAnexoModel doc) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remover Anexo?'),
        content: Text(
            'Deseja remover o documento "${doc.nomeArquivoOriginal}"? Você precisará anexá-lo novamente se for obrigatório.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFBA1A1A)),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Remover'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;
    if (!mounted) return;

    try {
      await context.read<ISolicitacaoService>().removerDocumento(
            solicitacaoId: widget.solicitacaoId,
            documentoId: doc.id,
          );

      if (mounted) {
        final docsAtualizados =
            List<DocumentoAnexoModel>.from(_solicitacao!.documentos)
              ..removeWhere((d) => d.id == doc.id);

        setState(() {
          _solicitacao = SolicitacaoModel(
            id: _solicitacao!.id,
            protocolo: _solicitacao!.protocolo,
            pacienteId: _solicitacao!.pacienteId,
            especialidadeId: _solicitacao!.especialidadeId,
            especialidadeNome: _solicitacao!.especialidadeNome,
            unidadeId: _solicitacao!.unidadeId,
            unidadeNome: _solicitacao!.unidadeNome,
            dataSolicitacao: _solicitacao!.dataSolicitacao,
            status: _solicitacao!.status,
            prioridadeOficial: _solicitacao!.prioridadeOficial,
            queixaRelatada: _solicitacao!.queixaRelatada,
            tempoEvolucao: _solicitacao!.tempoEvolucao,
            observacaoProfissional: _solicitacao!.observacaoProfissional,
            documentos: docsAtualizados,
          );
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao remover: $e'),
            backgroundColor: const Color(0xFFBA1A1A),
          ),
        );
      }
    }
  }

  Future<void> _submeterParaUbs() async {
    setState(() {
      _isSubmitting = true;
      _erroGeral = null;
    });

    try {
      await context
          .read<ISolicitacaoService>()
          .submeterSolicitacao(widget.solicitacaoId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Solicitação enviada com sucesso para conferência na UBS!'),
            backgroundColor: Color(0xFF007A48),
          ),
        );
        context.pushReplacement('/acompanhamento/${widget.solicitacaoId}');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _erroGeral = e.toString();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: const Color(0xFFBA1A1A),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final double progressoObrigatorios = _totalObrigatorios > 0
        ? _obrigatoriosAnexados / _totalObrigatorios
        : 1.0;

    final int faltam = _totalObrigatorios - _obrigatoriosAnexados;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Voltar',
          onPressed: () => context.pop(),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(
                Icons.local_hospital_rounded,
                color: Color(0xFF007A48),
                size: 20,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Pré Triagem',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
          ],
        ),
        actions: const [
          FontScaleActionButton(),
          SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Contador superior: "X de Y anexados"
              Text(
                '$_totalAnexados de ${_checklist.length} anexados',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 4),

              // Título "Checklist de documentos"
              const Text(
                'Checklist de documentos',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 10),

              // Barra de progresso linear
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progressoObrigatorios,
                  minHeight: 6,
                  backgroundColor: const Color(0xFFE2E8F0),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Color(0xFF007A48),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Texto instrucional
              const Text(
                'Para evitar devoluções na regulação, anexe fotos legíveis ou PDFs dos itens abaixo:',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF475569),
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 20),

              // Mensagem de erro geral
              if (_erroGeral != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFDAD6),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFBA1A1A)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline,
                          color: Color(0xFFBA1A1A), size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _erroGeral!,
                          style: const TextStyle(
                            color: Color(0xFFBA1A1A),
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Lista de itens do checklist
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _checklist.length,
                itemBuilder: (context, index) {
                  final item = _checklist[index];
                  final anexo = _getDocumentoAnexado(item.id);
                  final double? uploadProgresso = _progressoUpload[item.id];
                  final bool isUploading = uploadProgresso != null;

                  return _buildChecklistItemCard(
                    index: index + 1,
                    item: item,
                    anexo: anexo,
                    isUploading: isUploading,
                    uploadProgresso: uploadProgresso ?? 0.0,
                  );
                },
              ),

              const SizedBox(height: 16),

              // Card: Dica Rápida de Legibilidade conforme protótipo
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F8F5),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFD1E7DD)),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.lightbulb_outline_rounded,
                      color: Color(0xFF007A48),
                      size: 22,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: 'Dica rápida: ',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF004D2D),
                                fontSize: 13,
                              ),
                            ),
                            TextSpan(
                              text:
                                  'Fotografe o documento em local iluminado, sem cortes nas bordas e com o texto bem nítido.',
                              style: TextStyle(
                                color: Color(0xFF1E4D36),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Botão Principal: Revisar e enviar para UBS (RF02/RF03)
              ElevatedButton(
                onPressed: (_podeEnviar && !_isSubmitting)
                    ? _submeterParaUbs
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF005A32),
                  disabledBackgroundColor: const Color(0xFFE2E8F0),
                  foregroundColor: Colors.white,
                  disabledForegroundColor: const Color(0xFF94A3B8),
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Revisar e enviar para UBS',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward_rounded, size: 18),
                        ],
                      ),
              ),
              const SizedBox(height: 8),

              // Legenda explicativa sob o botão
              Center(
                child: Text(
                  _podeEnviar
                      ? 'Todos os itens obrigatórios foram anexados. Pronto para envio!'
                      : '$_obrigatoriosAnexados de $_totalObrigatorios itens obrigatórios anexados • Falta $faltam documento para continuar',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _podeEnviar
                        ? const Color(0xFF007A48)
                        : const Color(0xFF64748B),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChecklistItemCard({
    required int index,
    required ChecklistItemModel item,
    required DocumentoAnexoModel? anexo,
    required bool isUploading,
    required double uploadProgresso,
  }) {
    final bool anexado = anexo != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: anexado ? const Color(0xFFA7E5C3) : const Color(0xFFE2E8F0),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Linha do cabeçalho do item: Ícone, Nome e Badge
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: anexado
                        ? const Color(0xFFD1F2DF)
                        : const Color(0xFFF1F5F9),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    anexado ? Icons.check_rounded : Icons.description_outlined,
                    color: anexado
                        ? const Color(0xFF007A48)
                        : const Color(0xFF64748B),
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$index. ${item.nomeDocumento}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Text(
                            item.obrigatorio ? 'Obrigatório' : 'Opcional',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: item.obrigatorio
                                  ? const Color(0xFF007A48)
                                  : const Color(0xFF64748B),
                            ),
                          ),
                          const Text(' • ',
                              style: TextStyle(color: Color(0xFF94A3B8))),
                          Text(
                            anexado ? 'Anexado' : 'Pendente',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: anexado
                                  ? const Color(0xFF007A48)
                                  : const Color(0xFFD97706),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Orientação do item
            Text(
              item.descricaoOrientacao,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF475569),
              ),
            ),
            const SizedBox(height: 14),

            // Barra de progresso durante o upload
            if (isUploading) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: uploadProgresso,
                  minHeight: 6,
                  backgroundColor: const Color(0xFFE2E8F0),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Color(0xFF007A48),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Enviando documento... ${(uploadProgresso * 100).toInt()}%',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF007A48),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ] else if (anexado) ...[
              // Card verde do arquivo já anexado com botão Trocar e Remover
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFD1F2DF),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFA7E5C3)),
                ),
                child: Row(
                  children: [
                    Icon(
                      FileUtils.isPdf(anexo.nomeArquivoOriginal)
                          ? Icons.picture_as_pdf_rounded
                          : Icons.image_rounded,
                      color: const Color(0xFF005A32),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${anexo.nomeArquivoOriginal} (${FileUtils.formatarTamanhoBytes(anexo.tamanhoBytes ?? 1468006)})',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0A331E),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    TextButton(
                      onPressed: () => _abrirOpcoesAnexo(item),
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      child: const Text(
                        'Trocar',
                        style: TextStyle(
                          color: Color(0xFF005A32),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded,
                          size: 18, color: Color(0xFFBA1A1A)),
                      tooltip: 'Remover',
                      visualDensity: VisualDensity.compact,
                      onPressed: () => _removerDocumento(anexo),
                    ),
                  ],
                ),
              ),
            ] else ...[
              // Botão Pontilhado: + Tirar foto ou anexar PDF
              InkWell(
                onTap: () => _abrirOpcoesAnexo(item),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F8F5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF007A48),
                      width: 1.5,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: const Column(
                    children: [
                      Icon(
                        Icons.add_a_photo_outlined,
                        color: Color(0xFF007A48),
                        size: 28,
                      ),
                      SizedBox(height: 6),
                      Text(
                        '+ Tirar foto ou anexar PDF',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF007A48),
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'JPG, PNG ou PDF até 5 MB',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
