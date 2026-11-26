import 'dart:io';
import 'package:dio/dio.dart';
import '../core/http_client.dart';
import '../models/models.dart';
import 'solicitacao_service.dart';

class RealSolicitacaoService implements ISolicitacaoService {
  final Dio _dio = AppHttpClient.dio;

  @override
  Future<List<SolicitacaoModel>> getMinhasSolicitacoes() async {
    try {
      final response = await _dio.get('/solicitacoes/minhas');
      return (response.data as List)
          .map((e) => SolicitacaoModel.fromJson(e))
          .toList();
    } catch (e) {
      throw AppHttpClient.parseErrorMessage(e);
    }
  }

  @override
  Future<SolicitacaoModel> getSolicitacaoById(int id) async {
    try {
      final response = await _dio.get('/solicitacoes/$id');
      return SolicitacaoModel.fromJson(response.data);
    } catch (e) {
      throw AppHttpClient.parseErrorMessage(e);
    }
  }

  @override
  Future<SolicitacaoModel> criarSolicitacao({
    required int especialidadeId,
    required String queixaRelatada,
    required String tempoEvolucao,
    String? telefoneContato,
    SinaisVitaisDomiciliares? sinaisDomiciliares,
  }) async {
    try {
      final response = await _dio.post(
        '/solicitacoes',
        data: {
          'especialidadeId': especialidadeId,
          'queixaRelatada': queixaRelatada,
          'tempoEvolucao': tempoEvolucao,
        },
      );
      final solicitacao = SolicitacaoModel.fromJson(response.data);

      if (sinaisDomiciliares != null && sinaisDomiciliares.temAlgumaMedicao) {
        try {
          await _dio.post(
            '/solicitacoes/${solicitacao.id}/sinais-vitais',
            data: sinaisDomiciliares.toJson(),
          );
        } catch (_) {
          // Permite continuar para documentos mesmo que o sinal vital opcional falhe
        }
      }

      return solicitacao;
    } catch (e) {
      throw AppHttpClient.parseErrorMessage(e);
    }
  }

  @override
  Future<DocumentoAnexoModel> uploadDocumento({
    required int solicitacaoId,
    required int itemChecklistId,
    required String filePath,
    void Function(int sent, int total)? onProgress,
  }) async {
    try {
      final file = File(filePath);
      final nome = file.path.split(RegExp(r'[/\\]')).last;
      final formData = FormData.fromMap({
        'itemChecklistId': itemChecklistId,
        'arquivo': await MultipartFile.fromFile(filePath, filename: nome),
      });

      final response = await _dio.post(
        '/solicitacoes/$solicitacaoId/documentos',
        data: formData,
        onSendProgress: onProgress,
      );
      return DocumentoAnexoModel.fromJson(response.data);
    } catch (e) {
      throw AppHttpClient.parseErrorMessage(e);
    }
  }

  @override
  Future<void> removerDocumento({
    required int solicitacaoId,
    required int documentoId,
  }) async {
    try {
      await _dio.delete('/solicitacoes/$solicitacaoId/documentos/$documentoId');
    } catch (e) {
      throw AppHttpClient.parseErrorMessage(e);
    }
  }

  @override
  Future<void> reenviarDocumentoPendencia({
    required int solicitacaoId,
    required int itemChecklistId,
    required String filePath,
  }) async {
    try {
      await uploadDocumento(
        solicitacaoId: solicitacaoId,
        itemChecklistId: itemChecklistId,
        filePath: filePath,
      );
      // Reenvia para conferência na UBS sem perder os dados
      await submeterSolicitacao(solicitacaoId);
    } catch (e) {
      throw AppHttpClient.parseErrorMessage(e);
    }
  }

  @override
  Future<void> submeterSolicitacao(int solicitacaoId) async {
    try {
      await _dio.post('/solicitacoes/$solicitacaoId/enviar');
    } catch (e) {
      throw AppHttpClient.parseErrorMessage(e);
    }
  }
}

class MockSolicitacaoService implements ISolicitacaoService {
  final List<SolicitacaoModel> _mockList = [
    const SolicitacaoModel(
      id: 1,
      protocolo: '#2026-0184',
      pacienteId: 1,
      especialidadeId: 1,
      especialidadeNome: 'Ortopedia',
      unidadeId: 2,
      unidadeNome: 'UBS Jardim Brasil',
      telefoneUbs: '(19) 3462-8100',
      enderecoUbs: 'Rua das Rosas, 120 - Jardim Brasil, Americana',
      dataSolicitacao: '2026-11-08T09:42:00',
      status: 'PENDENCIA_DOCUMENTAL',
      prioridadeOficial: 'MEDIA',
      queixaRelatada:
          'Dor intensa no joelho direito há 3 meses com dificuldade de locomoção.',
      tempoEvolucao: '3 meses',
      observacaoProfissional:
          'A foto do Documento Pessoal está ilegível. Toque aqui para reenviar sem perder seu lugar.',
      linhaDoTempo: [
        LinhaTempoEventoModel(
          status: 'ENVIADO',
          titulo: 'Solicitação e pré-triagem enviadas',
          dataHora: '08 nov • 09:42',
        ),
        LinhaTempoEventoModel(
          status: 'SINAIS_VITAIS',
          titulo: 'Sinais vitais registrados no acolhimento UBS',
          dataHora: '08 nov • 14:10',
        ),
        LinhaTempoEventoModel(
          status: 'PENDENCIA_DOCUMENTAL',
          titulo: 'Devolvida por pendência documental',
          descricao: 'Reenviar RG legível',
          dataHora: '09 nov • 10:15',
        ),
        LinhaTempoEventoModel(
          status: 'APTO_REGULACAO',
          titulo: 'Apta para Central de Regulação',
          descricao: 'Aguardando correção',
          dataHora: 'Pendente',
        ),
      ],
      documentos: [
        DocumentoAnexoModel(
          id: 1,
          itemChecklistId: 101,
          nomeArquivoOriginal: 'Pedido_medico.jpg',
          statusValidacao: 'VALIDO',
          tamanhoBytes: 1468006,
        ),
        DocumentoAnexoModel(
          id: 2,
          itemChecklistId: 102,
          nomeArquivoOriginal: 'RaioX_coluna.pdf',
          statusValidacao: 'VALIDO',
          tamanhoBytes: 2202009,
        ),
        DocumentoAnexoModel(
          id: 3,
          itemChecklistId: 103,
          nomeArquivoOriginal: 'Documento_pessoal_borrado.jpg',
          statusValidacao: 'REJEITADO',
          motivoRejeicao: 'Foto escura e dados do RG ilegíveis',
          tamanhoBytes: 980000,
        ),
      ],
    ),
    const SolicitacaoModel(
      id: 2,
      protocolo: '#2026-0092',
      pacienteId: 1,
      especialidadeId: 2,
      especialidadeNome: 'Gastroenterologia',
      unidadeId: 1,
      unidadeNome: 'UBS Centro',
      telefoneUbs: '(19) 3462-8000',
      enderecoUbs: 'Av. Cillos, 200 - Centro, Americana',
      dataSolicitacao: '2026-10-15T10:15:00',
      status: 'APTO_REGULACAO',
      prioridadeOficial: 'ALTA',
      queixaRelatada: 'Queimação e dor epigástrica contínua.',
      tempoEvolucao: '6 meses',
      linhaDoTempo: [
        LinhaTempoEventoModel(
          status: 'ENVIADO',
          titulo: 'Solicitação e pré-triagem enviadas',
          dataHora: '15 out • 10:15',
        ),
        LinhaTempoEventoModel(
          status: 'SINAIS_VITAIS',
          titulo: 'Sinais vitais registrados no acolhimento UBS',
          dataHora: '15 out • 11:30',
        ),
        LinhaTempoEventoModel(
          status: 'APTO_REGULACAO',
          titulo: 'Apta para Central de Regulação',
          descricao: 'Conferência concluída e aprovada',
          dataHora: '16 out • 16:40',
        ),
      ],
      documentos: [
        DocumentoAnexoModel(
          id: 4,
          itemChecklistId: 201,
          nomeArquivoOriginal: 'Pedido_gastro.pdf',
          statusValidacao: 'VALIDO',
          tamanhoBytes: 1572864,
        ),
      ],
    ),
  ];

  @override
  Future<List<SolicitacaoModel>> getMinhasSolicitacoes() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return List.from(_mockList);
  }

  @override
  Future<SolicitacaoModel> getSolicitacaoById(int id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _mockList.firstWhere(
      (s) => s.id == id,
      orElse: () => _mockList.first,
    );
  }

  @override
  Future<SolicitacaoModel> criarSolicitacao({
    required int especialidadeId,
    required String queixaRelatada,
    required String tempoEvolucao,
    String? telefoneContato,
    SinaisVitaisDomiciliares? sinaisDomiciliares,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final nova = SolicitacaoModel(
      id: _mockList.length + 1,
      protocolo: 'TRI-2026-000${_mockList.length + 85}',
      pacienteId: 1,
      especialidadeId: especialidadeId,
      especialidadeNome: especialidadeId == 1
          ? 'Ortopedia'
          : 'Gastroenterologia',
      unidadeId: 1,
      unidadeNome: 'UBS Centro',
      dataSolicitacao: DateTime.now().toIso8601String(),
      status: 'RASCUNHO',
      prioridadeOficial: 'NAO_DEFINIDA',
      queixaRelatada: queixaRelatada,
      tempoEvolucao: tempoEvolucao,
      documentos: const [],
    );
    _mockList.insert(0, nova);
    return nova;
  }

  @override
  Future<DocumentoAnexoModel> uploadDocumento({
    required int solicitacaoId,
    required int itemChecklistId,
    required String filePath,
    void Function(int sent, int total)? onProgress,
  }) async {
    if (onProgress != null) {
      onProgress(300000, 1000000);
      await Future.delayed(const Duration(milliseconds: 200));
      onProgress(700000, 1000000);
      await Future.delayed(const Duration(milliseconds: 200));
      onProgress(1000000, 1000000);
    } else {
      await Future.delayed(const Duration(milliseconds: 500));
    }

    final file = File(filePath);
    int tamanho = 1468006;
    if (file.existsSync()) {
      tamanho = file.lengthSync();
    }

    final doc = DocumentoAnexoModel(
      id: DateTime.now().millisecondsSinceEpoch,
      itemChecklistId: itemChecklistId,
      nomeArquivoOriginal: filePath.split(RegExp(r'[/\\]')).last,
      statusValidacao: 'PENDENTE',
      tamanhoBytes: tamanho,
    );

    // Atualiza solicitação na lista mock
    final index = _mockList.indexWhere((s) => s.id == solicitacaoId);
    if (index != -1) {
      final s = _mockList[index];
      final novosDocs = List<DocumentoAnexoModel>.from(s.documentos)
        ..removeWhere((d) => d.itemChecklistId == itemChecklistId)
        ..add(doc);

      _mockList[index] = SolicitacaoModel(
        id: s.id,
        protocolo: s.protocolo,
        pacienteId: s.pacienteId,
        especialidadeId: s.especialidadeId,
        especialidadeNome: s.especialidadeNome,
        unidadeId: s.unidadeId,
        unidadeNome: s.unidadeNome,
        dataSolicitacao: s.dataSolicitacao,
        status: s.status,
        prioridadeOficial: s.prioridadeOficial,
        queixaRelatada: s.queixaRelatada,
        tempoEvolucao: s.tempoEvolucao,
        observacaoProfissional: s.observacaoProfissional,
        documentos: novosDocs,
      );
    }

    return doc;
  }

  @override
  Future<void> removerDocumento({
    required int solicitacaoId,
    required int documentoId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final index = _mockList.indexWhere((s) => s.id == solicitacaoId);
    if (index != -1) {
      final s = _mockList[index];
      final novosDocs = List<DocumentoAnexoModel>.from(s.documentos)
        ..removeWhere((d) => d.id == documentoId);

      _mockList[index] = SolicitacaoModel(
        id: s.id,
        protocolo: s.protocolo,
        pacienteId: s.pacienteId,
        especialidadeId: s.especialidadeId,
        especialidadeNome: s.especialidadeNome,
        unidadeId: s.unidadeId,
        unidadeNome: s.unidadeNome,
        dataSolicitacao: s.dataSolicitacao,
        status: s.status,
        prioridadeOficial: s.prioridadeOficial,
        queixaRelatada: s.queixaRelatada,
        tempoEvolucao: s.tempoEvolucao,
        observacaoProfissional: s.observacaoProfissional,
        documentos: novosDocs,
      );
    }
  }

  @override
  Future<void> reenviarDocumentoPendencia({
    required int solicitacaoId,
    required int itemChecklistId,
    required String filePath,
  }) async {
    try {
      await uploadDocumento(
        solicitacaoId: solicitacaoId,
        itemChecklistId: itemChecklistId,
        filePath: filePath,
      );
      // Reenvia para conferência na UBS sem perder os dados
      await submeterSolicitacao(solicitacaoId);
    } catch (e) {
      throw AppHttpClient.parseErrorMessage(e);
    }
  }

  @override
  Future<void> submeterSolicitacao(int solicitacaoId) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final index = _mockList.indexWhere((s) => s.id == solicitacaoId);
    if (index != -1) {
      final s = _mockList[index];
      _mockList[index] = SolicitacaoModel(
        id: s.id,
        protocolo: s.protocolo,
        pacienteId: s.pacienteId,
        especialidadeId: s.especialidadeId,
        especialidadeNome: s.especialidadeNome,
        unidadeId: s.unidadeId,
        unidadeNome: s.unidadeNome,
        dataSolicitacao: s.dataSolicitacao,
        status: 'EM_CONFERENCIA_UBS',
        prioridadeOficial: s.prioridadeOficial,
        queixaRelatada: s.queixaRelatada,
        tempoEvolucao: s.tempoEvolucao,
        documentos: s.documentos,
      );
    }
  }
}
