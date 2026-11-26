package br.gov.sp.americana.triasus.model;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

@Entity @Table(name = "profissional") @Getter @Setter
public class Profissional {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY) private Integer id;
    @OneToOne(fetch = FetchType.LAZY) @JoinColumn(name = "usuario_id", nullable = false, unique = true) private Usuario usuario;
    @Column(nullable = false, length = 80) private String funcao;
    @Column(name = "numero_registro", length = 30) private String numeroRegistro;
}
