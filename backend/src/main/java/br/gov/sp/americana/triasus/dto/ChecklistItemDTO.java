package br.gov.sp.americana.triasus.dto;

public record ChecklistItemDTO(
    Integer id,
    Integer especialidadeId,
    String nomeDocumento,
    String descricaoOrientacao,
    Boolean obrigatorio
) {}
