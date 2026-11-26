import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../core/file_utils.dart';
import '../../core/font_scale.dart';
import '../../models/models.dart';
import '../../services/solicitacao_service.dart';

class AcompanhamentoScreen extends StatefulWidget {
  final int solicitacaoId;

  const AcompanhamentoScreen({super.key, required this.solicitacaoId});

  @override
  State<AcompanhamentoScreen> createState() => _AcompanhamentoScreenState();
}

class _AcompanhamentoScreenState extends State<AcompanhamentoScreen> {
  late Future<SolicitacaoModel> _solicitacaoFuture;
  bool _isReenviando = false;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _recarregar();
  }

  void _recarregar() {
    setState(() {
      _solicitacaoFuture = context
          .read<ISolicitacaoService>()
          .getSolicitacaoById(widget.solicitacaoId);
    });
  }

  Widget _buildStatusBadge(String status, String descricao) {
    Color bgColor;
    Color textColor;
    IconData iconData;

    switch (status) {
      case 'RASCUNHO':
        bgColor = const Color(0xFFF1F5F9);
        textColor = const Color(0xFF475569);
        iconData = Icons.edit_note_rounded;
        break;
      case 'EM_CONFERENCIA_UBS':
        bgColor = const Color(0xFFFFEDD5);
        textColor = const Color(0xFFC2410C);
        iconData = Icons.hourglass_top_rounded;
        break;
      case 'PENDENCIA_DOCUMENTAL':
        bgColor = const Color(0xFFFFDAD6);
        textColor = const Color(0xFFBA1A1A);
        iconData = Icons.error_outline_rounded;
        break;
      case 'APTO_REGULACAO':
        bgColor = const Color(0xFFDCFCE7);
        textColor = const Color(0xFF15803D);
        iconData = Icons.check_circle_outline_rounded;
        break;
      default:
        bgColor = const Color(0xFFF1F5F9);
        textColor = const Color(0xFF334155);
        iconData = Icons.info_outline_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(iconData, size: 14, color: textColor),
          const SizedBox(width: 4),
          Text(
            descricao,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  void _abrirModalReenvio(
    SolicitacaoModel solicitacao,
    DocumentoAnexoModel docRejeitado,
  ) {
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
                  'Reenviar: ${docRejeitado.nomeArquivoOriginal}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Fotografe com boa iluminação ou escolha outro arquivo PDF para substituir o anexo com pendência:',
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
                    child: const Icon(
                      Icons.camera_alt_outlined,
                      color: Color(0xFF007A48),
                    ),
                  ),
                  title: const Text(
                    'Tirar nova foto com a câmera',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _capturarFotoReenvio(
                      solicitacao,
                      docRejeitado,
                      ImageSource.camera,
                    );
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.photo_library_outlined,
                      color: Color(0xFF007A48),
                    ),
                  ),
                  title: const Text(
                    'Escolher foto da galeria',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _capturarFotoReenvio(
                      solicitacao,
                      docRejeitado,
                      ImageSource.gallery,
                    );
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.picture_as_pdf_outlined,
                      color: Color(0xFF007A48),
                    ),
                  ),
                  title: const Text(
                    'Selecionar novo PDF',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _selecionarPdfReenvio(solicitacao, docRejeitado);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _capturarFotoReenvio(
    SolicitacaoModel solicitacao,
    DocumentoAnexoModel docRejeitado,
    ImageSource source,
  ) async {
    try {
      final picked = await _imagePicker.pickImage(
        source: source,
        maxWidth: 2560,
        maxHeight: 1440,
        imageQuality: 90,
      );
      if (picked == null) return;
      await _executarReenvio(solicitacao, docRejeitado, File(picked.path));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro: $e')));
    }
  }

  Future<void> _selecionarPdfReenvio(
    SolicitacaoModel solicitacao,
    DocumentoAnexoModel docRejeitado,
  ) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
      if (result == null || result.files.isEmpty) return;
      final path = result.files.single.path;
      if (path == null) return;
      await _executarReenvio(solicitacao, docRejeitado, File(path));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro: $e')));
    }
  }

  Future<void> _executarReenvio(
    SolicitacaoModel solicitacao,
    DocumentoAnexoModel docRejeitado,
    File arquivoOriginal,
  ) async {
    setState(() => _isReenviando = true);
    try {
      final arquivoPronto = await FileUtils.prepararArquivoParaUpload(
        arquivoOriginal,
      );

      if (!mounted) return;
      await context.read<ISolicitacaoService>().reenviarDocumentoPendencia(
        solicitacaoId: solicitacao.id,
        itemChecklistId: docRejeitado.itemChecklistId,
        filePath: arquivoPronto.path,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Documento corrigido e reenviado com sucesso! Solicitação em conferência.',
            ),
            backgroundColor: Color(0xFF007A48),
          ),
        );
        _recarregar();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao reenviar: $e'),
            backgroundColor: const Color(0xFFBA1A1A),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isReenviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
              'Solicitações',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
          ],
        ),
        actions: const [FontScaleActionButton(), SizedBox(width: 8)],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => _recarregar(),
          child: FutureBuilder<SolicitacaoModel>(
            future: _solicitacaoFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting ||
                  _isReenviando) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.cloud_off_rounded,
                          size: 48,
                          color: Color(0xFFBA1A1A),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Erro ao carregar detalhes: ${snapshot.error}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Color(0xFFBA1A1A)),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _recarregar,
                          child: const Text('Tentar de novo'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final s = snapshot.data!;
              final docRejeitado = s.documentos
                  .cast<DocumentoAnexoModel?>()
                  .firstWhere(
                    (d) => d?.statusValidacao == 'REJEITADO',
                    orElse: () => null,
                  );

              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Cabeçalho da página com chip da UBS conforme protótipo
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Acompanhar\nsolicitação',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F172A),
                                  height: 1.2,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Comunicação direta com sua UBS de referência',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE2E8F0),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.location_on_rounded,
                                size: 13,
                                color: Color(0xFF475569),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                s.unidadeNome ?? 'UBS de Referência',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF334155),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Card de Resumo da Solicitação
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(5),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFD1F2DF),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.medical_services_rounded,
                              color: Color(0xFF007A48),
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  s.especialidadeNome ?? 'Especialidade',
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Protocolo\n${s.protocolo}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          _buildStatusBadge(s.status, s.statusDescricao),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ALERTA DE PENDÊNCIA DOCUMENTAL (RF06) conforme protótipo
                    if (s.status == 'PENDENCIA_DOCUMENTAL') ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF1ED),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFFFCCBE)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFBE0D8),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.photo_camera_back_outlined,
                                    color: Color(0xFFC2410C),
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text.rich(
                                    TextSpan(
                                      children: [
                                        const TextSpan(
                                          text: 'Atenção: ',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF9A3412),
                                            fontSize: 14,
                                          ),
                                        ),
                                        TextSpan(
                                          text:
                                              s.observacaoProfissional ??
                                              'A foto do Documento Pessoal está ilegível. Toque aqui para reenviar sem perder seu lugar.',
                                          style: const TextStyle(
                                            color: Color(0xFF9A3412),
                                            fontSize: 14,
                                            height: 1.3,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            InkWell(
                              onTap: () {
                                if (docRejeitado != null) {
                                  _abrirModalReenvio(s, docRejeitado);
                                } else {
                                  // Abre a tela de checklist se não identificar o documento específico
                                  context.push('/checklist/${s.id}');
                                }
                              },
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Reenviar documento agora',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: Color(0xFFC2410C),
                                    ),
                                  ),
                                  SizedBox(width: 6),
                                  Icon(
                                    Icons.arrow_forward_rounded,
                                    size: 16,
                                    color: Color(0xFFC2410C),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Histórico de Atualizações (Linha do Tempo)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Histórico de atualizações',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          '${s.linhaDoTempo.isNotEmpty ? s.linhaDoTempo.length : 4} etapas',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Lista dos passos da linha do tempo
                    if (s.linhaDoTempo.isNotEmpty)
                      ...s.linhaDoTempo.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final evento = entry.value;
                        final isLast = idx == s.linhaDoTempo.length - 1;
                        return _buildTimelineItem(
                          evento: evento,
                          isLast: isLast,
                        );
                      })
                    else ...[
                      // Linha do tempo fallback padrão do protótipo
                      _buildTimelineItemFallback(
                        titulo: 'Solicitação e pré-triagem enviadas',
                        dataHora: '08 nov • 09:42',
                        isConcluido: true,
                        isLast: false,
                      ),
                      _buildTimelineItemFallback(
                        titulo: 'Sinais vitais registrados no acolhimento UBS',
                        dataHora: '08 nov • 14:10',
                        isConcluido: s.status != 'RASCUNHO',
                        isLast: false,
                      ),
                      _buildTimelineItemFallback(
                        titulo: 'Devolvida por pendência documental',
                        subtitulo: 'Reenviar RG legível',
                        dataHora: '09 nov • 10:15',
                        isAlerta: true,
                        isConcluido: s.status == 'PENDENCIA_DOCUMENTAL',
                        isLast: false,
                      ),
                      _buildTimelineItemFallback(
                        titulo: 'Apta para Central de Regulação',
                        subtitulo: 'Aguardando correção',
                        dataHora: s.status == 'APTO_REGULACAO'
                            ? 'Concluído'
                            : 'Pendente',
                        isConcluido: s.status == 'APTO_REGULACAO',
                        isLast: true,
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Card de Apoio e Dúvidas com a UBS de Referência
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F5E9),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.support_agent_rounded,
                              color: Color(0xFF007A48),
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Dúvidas sobre o envio?',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Fale com a recepção da UBS...',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          OutlinedButton(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: Text(
                                    s.unidadeNome ?? 'UBS de Referência',
                                  ),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Telefone: ${s.telefoneUbs ?? "(19) 3462-8000"}',
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'Endereço: ${s.enderecoUbs ?? "Americana - SP"}',
                                      ),
                                      const SizedBox(height: 12),
                                      const Text(
                                        'Horário de atendimento: Segunda a sexta das 07h às 16h.',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF64748B),
                                        ),
                                      ),
                                    ],
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(ctx).pop(),
                                      child: const Text('OK'),
                                    ),
                                  ],
                                ),
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              backgroundColor: const Color(0xFFE8F5E9),
                              side: BorderSide.none,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              minimumSize: const Size(64, 36),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              'Ajuda',
                              style: TextStyle(
                                color: Color(0xFF007A48),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTimelineItem({
    required LinhaTempoEventoModel evento,
    required bool isLast,
  }) {
    final bool isAlerta = evento.status == 'PENDENCIA_DOCUMENTAL';
    final bool isConcluido =
        evento.status != 'APTO_REGULACAO' || evento.dataHora != 'Pendente';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: isAlerta
                    ? const Color(0xFFC2410C)
                    : isConcluido
                    ? const Color(0xFF007A48)
                    : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isAlerta
                      ? const Color(0xFFC2410C)
                      : isConcluido
                      ? const Color(0xFF007A48)
                      : const Color(0xFFCBD5E1),
                  width: 2,
                ),
              ),
              child: isConcluido || isAlerta
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
            if (!isLast)
              Container(width: 2, height: 48, color: const Color(0xFFCBD5E1)),
          ],
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                evento.titulo,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isAlerta
                      ? const Color(0xFF9A3412)
                      : const Color(0xFF1E293B),
                ),
              ),
              if (evento.descricao != null) ...[
                const SizedBox(height: 2),
                Text(
                  evento.descricao!,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isAlerta
                        ? const Color(0xFFC2410C)
                        : const Color(0xFF64748B),
                  ),
                ),
              ],
              const SizedBox(height: 2),
              Text(
                evento.dataHora,
                style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
              ),
              const SizedBox(height: 18),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineItemFallback({
    required String titulo,
    String? subtitulo,
    required String dataHora,
    bool isConcluido = false,
    bool isAlerta = false,
    required bool isLast,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: isAlerta
                    ? const Color(0xFFC2410C)
                    : isConcluido
                    ? const Color(0xFF007A48)
                    : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isAlerta
                      ? const Color(0xFFC2410C)
                      : isConcluido
                      ? const Color(0xFF007A48)
                      : const Color(0xFFCBD5E1),
                  width: 2,
                ),
              ),
              child: isConcluido || isAlerta
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
            if (!isLast)
              Container(width: 2, height: 48, color: const Color(0xFFCBD5E1)),
          ],
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titulo,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isAlerta
                      ? const Color(0xFF9A3412)
                      : const Color(0xFF1E293B),
                ),
              ),
              if (subtitulo != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitulo,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isAlerta
                        ? const Color(0xFFC2410C)
                        : const Color(0xFF64748B),
                  ),
                ),
              ],
              const SizedBox(height: 2),
              Text(
                dataHora,
                style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
              ),
              const SizedBox(height: 18),
            ],
          ),
        ),
      ],
    );
  }
}
