package br.gov.sp.americana.triasus.model;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

@Entity @Table(name = "papel") @Getter @Setter
public class Papel {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY) private Integer id;
    @Enumerated(EnumType.STRING) @Column(nullable = false, unique = true, length = 30) private PapelNome nome;
    @Column(length = 200) private String descricao;
}
