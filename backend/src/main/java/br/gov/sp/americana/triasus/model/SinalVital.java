package br.gov.sp.americana.triasus.model;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;
import java.math.BigDecimal;
import java.time.LocalDateTime;

@Entity @Table(name = "sinal_vital") @Getter @Setter
public class SinalVital {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY) private Integer id;
    @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "solicitacao_id", nullable = false) private Solicitacao solicitacao;
    @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "profissional_id") private Profissional profissional;
    @Column(name = "pressao_arterial", length = 10) private String pressaoArterial;
    @Column(name = "frequencia_cardiaca") private Integer frequenciaCardiaca;
    @Column(precision = 4, scale = 1) private BigDecimal temperatura;
    private Integer glicemia;
    private Integer saturacao;
    @Enumerated(EnumType.STRING) @Column(name = "origem_afericao", nullable = false, length = 30) private OrigemAfericao origemAfericao;
    @Column(name = "aferido_em", nullable = false) private LocalDateTime aferidoEm;
}
