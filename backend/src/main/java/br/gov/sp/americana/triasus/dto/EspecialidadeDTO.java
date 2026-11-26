package br.gov.sp.americana.triasus.dto;

public record EspecialidadeDTO(
    Integer id,
    String nome,
    String descricao,
    Boolean ativo
) {}
