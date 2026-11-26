package br.gov.sp.americana.triasus.model;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

@Entity @Table(name = "especialidade") @Getter @Setter
public class Especialidade {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY) private Integer id;
    @Column(nullable = false, unique = true, length = 100) private String nome;
    @Column(columnDefinition = "TEXT") private String descricao;
    @Column(nullable = false) private Boolean ativo;
}
