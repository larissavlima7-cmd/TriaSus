package br.gov.sp.americana.triasus.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;

public record AtualizarContatoDTO(
    @NotBlank(message = "Telefone é obrigatório")
    @Pattern(regexp = "^[0-9]{10,11}$", message = "Telefone deve conter DDD e número com 10 ou 11 dígitos")
    String telefone
) {}
