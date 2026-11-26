package br.gov.sp.americana.triasus.model;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

@Entity @Table(name = "checklist_protocolo") @Getter @Setter
public class ChecklistProtocolo {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY) private Integer id;
    @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "especialidade_id", nullable = false) private Especialidade especialidade;
    @Column(name = "nome_documento", nullable = false, length = 150) private String nomeDocumento;
    @Column(name = "descricao_orientacao", length = 255) private String descricaoOrientacao;
    @Column(nullable = false) private Boolean obrigatorio;
}
