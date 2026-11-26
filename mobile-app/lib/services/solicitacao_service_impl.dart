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
    required String telefoneContato,
  }) async {
    try {
      final response = await _dio.post('/solicitacoes', data: {
        'especialidadeId': especialidadeId,
        'queixaRelatada': queixaRelatada,
        'tempoEvolucao': tempoEvolucao,
        'telefoneContato': telefoneContato,
      });
      return SolicitacaoModel.fromJson(response.data);
    } catch (e) {
      throw AppHttpClient.parseErrorMessage(e);
    }
  }

  @override
  Future<DocumentoAnexoModel> uploadDocumento({
    required int solicitacaoId,
    required int itemChecklistId,
    required String filePath,
  }) async {
    try {
      final formData = FormData.fromMap({
        'itemChecklistId': itemChecklistId,
        'arquivo': await MultipartFile.fromFile(filePath),
      });
      final response = await _dio.post(
        '/solicitacoes/$solicitacaoId/anexos',
        data: formData,
      );
      return DocumentoAnexoModel.fromJson(response.data);
    } catch (e) {
      throw AppHttpClient.parseErrorMessage(e);
    }
  }

  @override
  Future<void> submeterSolicitacao(int solicitacaoId) async {
    try {
      await _dio.post('/solicitacoes/$solicitacaoId/submeter');
    } catch (e) {
      throw AppHttpClient.parseErrorMessage(e);
    }
  }
}

class MockSolicitacaoService implements ISolicitacaoService {
  final List<SolicitacaoModel> _mockList = [
    const SolicitacaoModel(
      id: 1,
      protocolo: 'TRI-2026-00084',
      pacienteId: 1,
      especialidadeId: 1,
      especialidadeNome: 'Ortopedia',
      unidadeId: 2,
      unidadeNome: 'UBS Vila Mathiesen',
      dataSolicitacao: '2026-11-20T10:30:00',
      status: 'EM_CONFERENCIA_UBS',
      prioridadeOficial: 'NAO_DEFINIDA',
      queixaRelatada: 'Dor intensa no joelho direito há 3 meses com dificuldade de locomoção.',
      tempoEvolucao: '3 meses',
      documentos: [
        DocumentoAnexoModel(
          id: 1,
          itemChecklistId: 101,
          nomeArquivoOriginal: 'encaminhamento_medico.jpg',
          statusValidacao: 'VALIDO',
        ),
        DocumentoAnexoModel(
          id: 2,
          itemChecklistId: 102,
          nomeArquivoOriginal: 'raio_x_joelho.pdf',
          statusValidacao: 'PENDENTE',
        ),
      ],
    ),
    const SolicitacaoModel(
      id: 2,
      protocolo: 'TRI-2026-00045',
      pacienteId: 1,
      especialidadeId: 2,
      especialidadeNome: 'Gastroenterologia',
      unidadeId: 1,
      unidadeNome: 'UBS Centro',
      dataSolicitacao: '2026-11-10T14:15:00',
      status: 'PENDENCIA_DOCUMENTAL',
      prioridadeOficial: 'MEDIA',
      queixaRelatada: 'Queimação e dor epigástrica contínua.',
      tempoEvolucao: '6 meses',
      observacaoProfissional: 'A foto do encaminhamento está ilegível. Favor reenviar com boa iluminação.',
      documentos: [
        DocumentoAnexoModel(
          id: 3,
          itemChecklistId: 201,
          nomeArquivoOriginal: 'foto_pedido.png',
          statusValidacao: 'REJEITADO',
          motivoRejeicao: 'Documento borrado / dados do médico ilegíveis.',
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
    required String telefoneContato,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final nova = SolicitacaoModel(
      id: _mockList.length + 1,
      protocolo: 'TRI-2026-000${_mockList.length + 85}',
      pacienteId: 1,
      especialidadeId: especialidadeId,
      especialidadeNome: especialidadeId == 1 ? 'Ortopedia' : 'Gastroenterologia',
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
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return DocumentoAnexoModel(
      id: DateTime.now().millisecondsSinceEpoch,
      itemChecklistId: itemChecklistId,
      nomeArquivoOriginal: filePath.split(RegExp(r'[/\\]')).last,
      statusValidacao: 'PENDENTE',
    );
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
