package br.gov.sp.americana.triasus.dto;

import br.gov.sp.americana.triasus.model.PrioridadeOficial;
import br.gov.sp.americana.triasus.model.SolicitacaoStatus;

import java.time.LocalDateTime;

public record SolicitacaoResumoDTO(
    Integer id,
    String protocolo,
    Integer pacienteId,
    String pacienteNome,
    String especialidadeNome,
    String unidadeNome,
    LocalDateTime dataSolicitacao,
    SolicitacaoStatus status,
    PrioridadeOficial prioridadeOficial
) {}
