package br.gov.sp.americana.triasus.model;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;
import java.time.LocalDateTime;

@Entity @Table(name = "solicitacao") @Getter @Setter
public class Solicitacao {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY) private Integer id;
    @Column(nullable = false, unique = true, length = 30) private String protocolo;
    @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "paciente_id", nullable = false) private Paciente paciente;
    @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "especialidade_id", nullable = false) private Especialidade especialidade;
    @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "unidade_id", nullable = false) private UnidadeUbs unidade;
    @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "profissional_conferencia_id") private Profissional profissionalConferencia;
    @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "criada_por_usuario_id") private Usuario criadaPorUsuario;
    @Column(name = "data_solicitacao", nullable = false) private LocalDateTime dataSolicitacao;
    @Enumerated(EnumType.STRING) @Column(nullable = false, length = 30) private SolicitacaoStatus status;
    @Enumerated(EnumType.STRING) @Column(name = "prioridade_oficial", nullable = false, length = 20) private PrioridadeOficial prioridadeOficial;
    @Column(name = "queixa_relatada", columnDefinition = "TEXT") private String queixaRelatada;
    @Column(name = "tempo_evolucao", length = 50) private String tempoEvolucao;
    @Column(name = "observacao_profissional", columnDefinition = "TEXT") private String observacaoProfissional;
}
