package br.gov.sp.americana.triasus.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import java.time.LocalDate;

public record LoginCidadaoDTO(
    @NotBlank(message = "CPF ou CNS é obrigatório")
    String identificador,
    @NotNull(message = "Data de nascimento é obrigatória")
    LocalDate dataNascimento
) {}
