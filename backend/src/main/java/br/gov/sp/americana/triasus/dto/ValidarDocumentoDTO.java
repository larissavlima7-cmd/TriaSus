package br.gov.sp.americana.triasus.dto;

import br.gov.sp.americana.triasus.model.StatusValidacao;
import jakarta.validation.constraints.NotNull;

public record ValidarDocumentoDTO(
    @NotNull(message = "Status da validação é obrigatório")
    StatusValidacao statusValidacao,
    String motivoRejeicao
) {}
