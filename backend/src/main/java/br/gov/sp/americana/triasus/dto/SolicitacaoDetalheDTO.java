package br.gov.sp.americana.triasus.dto;

import br.gov.sp.americana.triasus.model.PrioridadeOficial;
import br.gov.sp.americana.triasus.model.SolicitacaoStatus;

import java.time.LocalDateTime;
import java.util.List;

public record SolicitacaoDetalheDTO(
    Integer id,
    String protocolo,
    Integer pacienteId,
    String pacienteNome,
    String pacienteCpf,
    String pacienteCartaoSus,
    Integer especialidadeId,
    String especialidadeNome,
    Integer unidadeId,
    String unidadeNome,
    Integer profissionalConferenciaId,
    String profissionalConferenciaNome,
    Integer criadaPorUsuarioId,
    String criadaPorUsuarioNome,
    LocalDateTime dataSolicitacao,
    SolicitacaoStatus status,
    PrioridadeOficial prioridadeOficial,
    String queixaRelatada,
    String tempoEvolucao,
    String observacaoProfissional,
    List<ChecklistItemDTO> checklist,
    List<DocumentoAnexoResumoDTO> anexos,
    List<LinhaTempoEventoDTO> linhaDoTempo
) {}
