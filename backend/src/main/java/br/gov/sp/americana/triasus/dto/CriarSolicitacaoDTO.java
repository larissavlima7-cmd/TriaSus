package br.gov.sp.americana.triasus.dto;

import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

public record CriarSolicitacaoDTO(
    @NotNull(message = "Especialidade é obrigatória")
    Integer especialidadeId,
    Integer pacienteId, // Opcional se for Cidadão; obrigatório se for Recepção/ACS
    @Size(max = 2000, message = "Queixa relatada deve ter no máximo 2000 caracteres")
    String queixaRelatada,
    @Size(max = 50, message = "Tempo de evolução deve ter no máximo 50 caracteres")
    String tempoEvolucao
) {}
