package br.gov.sp.americana.triasus.model;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

@Entity @Table(name = "unidade_ubs") @Getter @Setter
public class UnidadeUbs {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY) private Integer id;
    @Column(nullable = false, length = 150) private String nome;
    @Column(length = 7) private String cnes;
    @Column(length = 255) private String endereco;
    @Column(nullable = false) private Boolean ativo;
}
