package br.gov.sp.americana.triasus.dto;

import jakarta.validation.constraints.NotBlank;

public record LoginProfissionalDTO(
    @NotBlank(message = "CPF ou e-mail é obrigatório")
    String login,
    @NotBlank(message = "Senha é obrigatória")
    String senha
) {}
