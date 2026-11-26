package br.gov.sp.americana.triasus.dto;

import br.gov.sp.americana.triasus.model.PrioridadeOficial;
import br.gov.sp.americana.triasus.model.SolicitacaoStatus;
import br.gov.sp.americana.triasus.model.StatusValidacao;

import java.time.LocalDateTime;
import java.util.List;

public record DocumentoAnexoResumoDTO(
    Integer id,
    Integer itemChecklistId,
    String nomeDocumento,
    String nomeArquivoOriginal,
    String tipoMime,
    Long tamanhoBytes,
    StatusValidacao statusValidacao,
    String motivoRejeicao,
    LocalDateTime enviadoEm
) {}
