import '../models/models.dart';

abstract class ISolicitacaoService {
  Future<List<SolicitacaoModel>> getMinhasSolicitacoes();
  Future<SolicitacaoModel> getSolicitacaoById(int id);
  Future<SolicitacaoModel> criarSolicitacao({
    required int especialidadeId,
    required String queixaRelatada,
    required String tempoEvolucao,
    String? telefoneContato,
    SinaisVitaisDomiciliares? sinaisDomiciliares,
  });
  Future<DocumentoAnexoModel> uploadDocumento({
    required int solicitacaoId,
    required int itemChecklistId,
    required String filePath,
  });
  Future<void> submeterSolicitacao(int solicitacaoId);
}
