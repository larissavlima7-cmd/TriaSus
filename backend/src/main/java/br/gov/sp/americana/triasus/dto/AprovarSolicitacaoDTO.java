package br.gov.sp.americana.triasus.dto;

import br.gov.sp.americana.triasus.model.PrioridadeOficial;
import jakarta.validation.constraints.NotNull;

public record AprovarSolicitacaoDTO(
    @NotNull(message = "Prioridade oficial é obrigatória")
    PrioridadeOficial prioridadeOficial,
    String observacaoProfissional
) {}
