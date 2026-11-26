package br.gov.sp.americana.triasus.dto;

import br.gov.sp.americana.triasus.model.PrioridadeOficial;
import br.gov.sp.americana.triasus.model.SolicitacaoStatus;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

public record PacoteRegulacaoDTO(
    Integer solicitacaoId,
    String protocolo,
    LocalDateTime dataSolicitacao,
    SolicitacaoStatus status,
    PrioridadeOficial prioridadeOficial,
    String observacaoProfissional,
    String especialidadeNome,
    String ubsNome,
    String ubsCnes,
    PacienteRegulacaoDTO paciente,
    ProfissionalRegulacaoDTO profissionalConferencia,
    String queixaRelatada,
    String tempoEvolucao,
    List<SinalVitalDTO> sinaisVitaisAcolhimento,
    List<DocumentoAnexoResumoDTO> documentosValidados
) {
    public record PacienteRegulacaoDTO(
        Integer id,
        String nome,
        String cpf,
        String cartaoSus,
        LocalDate dataNascimento,
        String telefone,
        Boolean contatoValidado
    ) {}

    public record ProfissionalRegulacaoDTO(
        Integer id,
        String nome,
        String funcao,
        String numeroRegistro
    ) {}
}
