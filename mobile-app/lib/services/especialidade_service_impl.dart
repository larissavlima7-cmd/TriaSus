import 'package:dio/dio.dart';
import '../core/http_client.dart';
import '../models/models.dart';
import 'especialidade_service.dart';

class RealEspecialidadeService implements IEspecialidadeService {
  final Dio _dio = AppHttpClient.dio;

  @override
  Future<List<EspecialidadeModel>> getEspecialidades() async {
    try {
      final response = await _dio.get('/especialidades');
      return (response.data as List)
          .map((e) => EspecialidadeModel.fromJson(e))
          .toList();
    } catch (e) {
      throw AppHttpClient.parseErrorMessage(e);
    }
  }

  @override
  Future<List<ChecklistItemModel>> getChecklistByEspecialidade(int especialidadeId) async {
    try {
      final response = await _dio.get('/especialidades/$especialidadeId/checklist');
      return (response.data as List)
          .map((e) => ChecklistItemModel.fromJson(e))
          .toList();
    } catch (e) {
      throw AppHttpClient.parseErrorMessage(e);
    }
  }
}

class MockEspecialidadeService implements IEspecialidadeService {
  @override
  Future<List<EspecialidadeModel>> getEspecialidades() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return const [
      EspecialidadeModel(
        id: 1,
        nome: 'Ortopedia',
        descricao: 'Problemas osteomusculares, articulações, coluna e fraturas prévias.',
        ativo: true,
      ),
      EspecialidadeModel(
        id: 2,
        nome: 'Gastroenterologia',
        descricao: 'Doenças do trato digestivo, refluxo, dores abdominais e gastrite.',
        ativo: true,
      ),
      EspecialidadeModel(
        id: 3,
        nome: 'Cardiologia',
        descricao: 'Hipertensão severa, arritmias e acompanhamento coronariano.',
        ativo: true,
      ),
    ];
  }

  @override
  Future<List<ChecklistItemModel>> getChecklistByEspecialidade(int especialidadeId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (especialidadeId == 1) {
      // Ortopedia
      return const [
        ChecklistItemModel(
          id: 101,
          especialidadeId: 1,
          nomeDocumento: 'Encaminhamento Médico Legível',
          descricaoOrientacao: 'Foto clara do pedido emitido pelo médico da UBS com carimbo e CRM.',
          obrigatorio: true,
        ),
        ChecklistItemModel(
          id: 102,
          especialidadeId: 1,
          nomeDocumento: 'Exame de Raio-X ou Laudo Prévio',
          descricaoOrientacao: 'Laudo ou imagem do exame radiológico recente da articulação/osso afetado.',
          obrigatorio: true,
        ),
        ChecklistItemModel(
          id: 103,
          especialidadeId: 1,
          nomeDocumento: 'Documento Pessoal com Foto (RG/CNH)',
          descricaoOrientacao: 'Frente e verso do documento de identificação oficial.',
          obrigatorio: true,
        ),
      ];
    } else if (especialidadeId == 2) {
      // Gastroenterologia
      return const [
        ChecklistItemModel(
          id: 201,
          especialidadeId: 2,
          nomeDocumento: 'Pedido Médico de Encaminhamento',
          descricaoOrientacao: 'Encaminhamento da UBS com hipótese diagnóstica legível.',
          obrigatorio: true,
        ),
        ChecklistItemModel(
          id: 202,
          especialidadeId: 2,
          nomeDocumento: 'Endoscopia Digestiva ou Ultrassom',
          descricaoOrientacao: 'Laudo de exame complementar realizado nos últimos 12 meses.',
          obrigatorio: true,
        ),
        ChecklistItemModel(
          id: 203,
          especialidadeId: 2,
          nomeDocumento: 'Exames Laboratoriais Recentes',
          descricaoOrientacao: 'Hemograma recente e enzimas hepáticas.',
          obrigatorio: false,
        ),
      ];
    }

    return const [
      ChecklistItemModel(
        id: 301,
        especialidadeId: 3,
        nomeDocumento: 'Encaminhamento Médico da UBS',
        descricaoOrientacao: 'Guia de referência da Unidade Básica de Saúde.',
        obrigatorio: true,
      ),
    ];
  }
}
