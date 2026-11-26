package br.gov.sp.americana.triasus.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

public record DevolverSolicitacaoDTO(
    @NotNull(message = "Item de checklist rejeitado é obrigatório")
    Integer itemChecklistId,
    @NotBlank(message = "Motivo da rejeição é obrigatório")
    String motivoRejeicao
) {}
