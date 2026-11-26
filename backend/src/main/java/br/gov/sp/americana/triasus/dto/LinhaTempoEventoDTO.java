package br.gov.sp.americana.triasus.dto;

import java.time.LocalDateTime;

public record LinhaTempoEventoDTO(
    String status,
    String descricao,
    LocalDateTime dataHora
) {}
