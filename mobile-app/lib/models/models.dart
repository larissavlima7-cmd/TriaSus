/// Modelos de dados do TriaSUS
library;

class AuthResult {
  final String token;
  final String tipo;
  final int usuarioId;
  final String nome;
  final String email;
  final List<String> papeis;
  final int? pacienteId;
  final int? profissionalId;
  final bool contatoValidado;
  final String? telefone;

  const AuthResult({
    required this.token,
    required this.tipo,
    required this.usuarioId,
    required this.nome,
    required this.email,
    required this.papeis,
    this.pacienteId,
    this.profissionalId,
    this.contatoValidado = false,
    this.telefone,
  });

  factory AuthResult.fromJson(Map<String, dynamic> json) {
    return AuthResult(
      token: json['token'] ?? '',
      tipo: json['tipo'] ?? 'Bearer',
      usuarioId: json['usuarioId'] ?? 0,
      nome: json['nome'] ?? '',
      email: json['email'] ?? '',
      papeis:
          (json['papeis'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      pacienteId: json['pacienteId'],
      profissionalId: json['profissionalId'],
      contatoValidado: json['contatoValidado'] ?? false,
      telefone: json['telefone'],
    );
  }
}

class EspecialidadeModel {
  final int id;
  final String nome;
  final String? descricao;
  final bool ativo;

  const EspecialidadeModel({
    required this.id,
    required this.nome,
    this.descricao,
    required this.ativo,
  });

  factory EspecialidadeModel.fromJson(Map<String, dynamic> json) {
    return EspecialidadeModel(
      id: json['id'] ?? 0,
      nome: json['nome'] ?? '',
      descricao: json['descricao'],
      ativo: json['ativo'] ?? true,
    );
  }
}

class ChecklistItemModel {
  final int id;
  final int especialidadeId;
  final String nomeDocumento;
  final String descricaoOrientacao;
  final bool obrigatorio;

  const ChecklistItemModel({
    required this.id,
    required this.especialidadeId,
    required this.nomeDocumento,
    required this.descricaoOrientacao,
    required this.obrigatorio,
  });

  factory ChecklistItemModel.fromJson(Map<String, dynamic> json) {
    return ChecklistItemModel(
      id: json['id'] ?? 0,
      especialidadeId: json['especialidadeId'] ?? 0,
      nomeDocumento: json['nomeDocumento'] ?? '',
      descricaoOrientacao: json['descricaoOrientacao'] ?? '',
      obrigatorio: json['obrigatorio'] ?? true,
    );
  }
}

class DocumentoAnexoModel {
  final int id;
  final int itemChecklistId;
  final String nomeArquivoOriginal;
  final String? urlArquivo;
  final String? statusValidacao; // PENDENTE, VALIDO, REJEITADO
  final String? motivoRejeicao;

  const DocumentoAnexoModel({
    required this.id,
    required this.itemChecklistId,
    required this.nomeArquivoOriginal,
    this.urlArquivo,
    this.statusValidacao,
    this.motivoRejeicao,
  });

  factory DocumentoAnexoModel.fromJson(Map<String, dynamic> json) {
    return DocumentoAnexoModel(
      id: json['id'] ?? 0,
      itemChecklistId: json['itemChecklistId'] ?? 0,
      nomeArquivoOriginal: json['nomeArquivoOriginal'] ?? '',
      urlArquivo: json['urlArquivo'],
      statusValidacao: json['statusValidacao'] ?? 'PENDENTE',
      motivoRejeicao: json['motivoRejeicao'],
    );
  }
}

class SolicitacaoModel {
  final int id;
  final String protocolo;
  final int pacienteId;
  final int especialidadeId;
  final String? especialidadeNome;
  final int unidadeId;
  final String? unidadeNome;
  final String dataSolicitacao;
  final String
  status; // RASCUNHO, EM_CONFERENCIA_UBS, PENDENCIA_DOCUMENTAL, APTO_REGULACAO
  final String prioridadeOficial; // NAO_DEFINIDA, BAIXA, MEDIA, ALTA, URGENTE
  final String queixaRelatada;
  final String tempoEvolucao;
  final String? observacaoProfissional;
  final List<DocumentoAnexoModel> documentos;

  const SolicitacaoModel({
    required this.id,
    required this.protocolo,
    required this.pacienteId,
    required this.especialidadeId,
    this.especialidadeNome,
    required this.unidadeId,
    this.unidadeNome,
    required this.dataSolicitacao,
    required this.status,
    required this.prioridadeOficial,
    required this.queixaRelatada,
    required this.tempoEvolucao,
    this.observacaoProfissional,
    this.documentos = const [],
  });

  factory SolicitacaoModel.fromJson(Map<String, dynamic> json) {
    return SolicitacaoModel(
      id: json['id'] ?? 0,
      protocolo: json['protocolo'] ?? '',
      pacienteId: json['pacienteId'] ?? 0,
      especialidadeId: json['especialidadeId'] ?? 0,
      especialidadeNome: json['especialidadeNome'],
      unidadeId: json['unidadeId'] ?? 0,
      unidadeNome: json['unidadeNome'],
      dataSolicitacao: json['dataSolicitacao'] ?? '',
      status: json['status'] ?? 'RASCUNHO',
      prioridadeOficial: json['prioridadeOficial'] ?? 'NAO_DEFINIDA',
      queixaRelatada: json['queixaRelatada'] ?? '',
      tempoEvolucao: json['tempoEvolucao'] ?? '',
      observacaoProfissional: json['observacaoProfissional'],
      documentos:
          (json['documentos'] as List<dynamic>?)
              ?.map(
                (e) => DocumentoAnexoModel.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          const [],
    );
  }

  String get statusDescricao {
    switch (status) {
      case 'RASCUNHO':
        return 'Rascunho';
      case 'EM_CONFERENCIA_UBS':
        return 'Em conferência na UBS';
      case 'PENDENCIA_DOCUMENTAL':
        return 'Pendência de documento';
      case 'APTO_REGULACAO':
        return 'Apto para regulação';
      default:
        return status;
    }
  }

  int get etapaAtualNumero {
    switch (status) {
      case 'RASCUNHO':
        return 1;
      case 'EM_CONFERENCIA_UBS':
      case 'PENDENCIA_DOCUMENTAL':
        return 2;
      case 'APTO_REGULACAO':
        return 3;
      default:
        return 1;
    }
  }

  double get porcentagemProgresso {
    switch (status) {
      case 'RASCUNHO':
        return 0.33;
      case 'EM_CONFERENCIA_UBS':
        return 0.65;
      case 'PENDENCIA_DOCUMENTAL':
        return 0.50;
      case 'APTO_REGULACAO':
        return 1.0;
      default:
        return 0.33;
    }
  }
}
