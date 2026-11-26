package br.gov.sp.americana.triasus.dto;

import java.time.LocalDateTime;

public record ErroRespostaDTO(
    LocalDateTime timestamp,
    int status,
    String mensagem,
    String caminho
) {}
