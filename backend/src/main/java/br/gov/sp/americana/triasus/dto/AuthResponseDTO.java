package br.gov.sp.americana.triasus.dto;

import java.time.Instant;
import java.util.List;

public record AuthResponseDTO(
    String token,
    String tipo,
    Instant expiracao,
    Integer usuarioId,
    String nome,
    List<String> papeis,
    Integer pacienteId,
    Integer profissionalId
) {}
