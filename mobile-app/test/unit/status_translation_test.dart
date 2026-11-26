import 'package:flutter_test/flutter_test.dart';
import 'package:triasus_app/models/models.dart';

void main() {
  group('Tradução e Descrição de Status da Solicitação', () {
    test('Deve traduzir status da API para textos simples em PT-BR', () {
      const rascunho = SolicitacaoModel(
        id: 1,
        protocolo: 'TRI-001',
        pacienteId: 1,
        especialidadeId: 1,
        unidadeId: 1,
        dataSolicitacao: '2026-11-26T10:00:00',
        status: 'RASCUNHO',
        prioridadeOficial: 'NAO_DEFINIDA',
        queixaRelatada: 'Dor',
        tempoEvolucao: '1 semana',
      );
      expect(rascunho.statusDescricao, equals('Rascunho'));
      expect(rascunho.etapaAtualNumero, equals(1));

      const conferencia = SolicitacaoModel(
        id: 2,
        protocolo: 'TRI-002',
        pacienteId: 1,
        especialidadeId: 1,
        unidadeId: 1,
        dataSolicitacao: '2026-11-26T10:00:00',
        status: 'EM_CONFERENCIA_UBS',
        prioridadeOficial: 'NAO_DEFINIDA',
        queixaRelatada: 'Dor',
        tempoEvolucao: '1 semana',
      );
      expect(conferencia.statusDescricao, equals('Em conferência na UBS'));
      expect(conferencia.etapaAtualNumero, equals(2));

      const pendencia = SolicitacaoModel(
        id: 3,
        protocolo: 'TRI-003',
        pacienteId: 1,
        especialidadeId: 1,
        unidadeId: 1,
        dataSolicitacao: '2026-11-26T10:00:00',
        status: 'PENDENCIA_DOCUMENTAL',
        prioridadeOficial: 'MEDIA',
        queixaRelatada: 'Dor',
        tempoEvolucao: '1 semana',
      );
      expect(pendencia.statusDescricao, equals('Pendência de documento'));
      expect(pendencia.etapaAtualNumero, equals(2));

      const apto = SolicitacaoModel(
        id: 4,
        protocolo: 'TRI-004',
        pacienteId: 1,
        especialidadeId: 1,
        unidadeId: 1,
        dataSolicitacao: '2026-11-26T10:00:00',
        status: 'APTO_REGULACAO',
        prioridadeOficial: 'ALTA',
        queixaRelatada: 'Dor',
        tempoEvolucao: '1 semana',
      );
      expect(apto.statusDescricao, equals('Apto para regulação'));
      expect(apto.etapaAtualNumero, equals(3));
      expect(apto.porcentagemProgresso, equals(1.0));
    });
  });
}
