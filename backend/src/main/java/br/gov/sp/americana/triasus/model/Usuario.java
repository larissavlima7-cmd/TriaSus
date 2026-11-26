package br.gov.sp.americana.triasus.model;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;
import java.time.LocalDateTime;

@Entity @Table(name = "usuario") @Getter @Setter
public class Usuario {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY) private Integer id;
    @Column(nullable = false, length = 150) private String nome;
    @Column(unique = true, length = 150) private String email;
    @Column(nullable = false, unique = true, length = 11) private String cpf;
    @Column(name = "senha_hash", length = 100) private String senhaHash;
    @Column(nullable = false) private Boolean ativo;
    @Column(name = "criado_em", nullable = false) private LocalDateTime criadoEm;
}
