package br.gov.sp.americana.triasus.dto;

import java.util.List;

public record UsuarioMeDTO(
    Integer id,
    String nome,
    String email,
    String cpf,
    List<String> papeis,
    Integer pacienteId,
    Integer profissionalId
) {}
