package br.gov.sp.americana.triasus.dto;

import br.gov.sp.americana.triasus.model.OrigemAfericao;
import jakarta.validation.constraints.*;
import java.math.BigDecimal;

public record RegistrarSinalVitalDTO(
    @NotNull(message = "Origem da aferição é obrigatória")
    OrigemAfericao origemAfericao,

    @Pattern(regexp = "^[0-9]{2,3}x[0-9]{2,3}$", message = "Pressão arterial deve seguir o formato NNNxNN (ex.: 120x80)")
    String pressaoArterial,

    @Min(value = 20, message = "Frequência cardíaca deve ser de no mínimo 20 bpm")
    @Max(value = 300, message = "Frequência cardíaca deve ser de no máximo 300 bpm")
    Integer frequenciaCardiaca,

    @DecimalMin(value = "30.0", message = "Temperatura deve ser de no mínimo 30.0 ºC")
    @DecimalMax(value = "45.0", message = "Temperatura deve ser de no máximo 45.0 ºC")
    @Digits(integer = 3, fraction = 1, message = "Temperatura deve ter no máximo 1 casa decimal")
    BigDecimal temperatura,

    @Min(value = 10, message = "Glicemia deve ser de no mínimo 10 mg/dL")
    @Max(value = 1000, message = "Glicemia deve ser de no máximo 1000 mg/dL")
    Integer glicemia,

    @Min(value = 0, message = "Saturação deve ser entre 0 e 100%")
    @Max(value = 100, message = "Saturação deve ser entre 0 e 100%")
    Integer saturacao
) {}
