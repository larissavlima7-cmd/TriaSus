package br.gov.sp.americana.triasus.dto;

import java.time.LocalDate;

public record PacienteDTO(
    Integer id,
    Integer usuarioId,
    String nome,
    String cpf,
    String cartaoSus,
    LocalDate dataNascimento,
    String telefone,
    Boolean contatoValidado,
    Integer unidadeReferenciaId,
    String unidadeReferenciaNome
) {}
