package br.gov.sp.americana.triasus.dto;

import br.gov.sp.americana.triasus.model.OrigemAfericao;
import java.math.BigDecimal;
import java.time.LocalDateTime;

public record SinalVitalDTO(
    Integer id,
    Integer solicitacaoId,
    OrigemAfericao origemAfericao,
    String pressaoArterial,
    Integer frequenciaCardiaca,
    BigDecimal temperatura,
    Integer glicemia,
    Integer saturacao,
    Integer profissionalId,
    String profissionalNome,
    String profissionalFuncao,
    LocalDateTime aferidoEm
) {}
