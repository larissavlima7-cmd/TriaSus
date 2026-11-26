package br.gov.sp.americana.triasus.model;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;
import java.time.LocalDate;

@Entity @Table(name = "paciente") @Getter @Setter
public class Paciente {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY) private Integer id;
    @OneToOne(fetch = FetchType.LAZY) @JoinColumn(name = "usuario_id", nullable = false, unique = true) private Usuario usuario;
    @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "unidade_referencia_id") private UnidadeUbs unidadeReferencia;
    @Column(name = "cartao_sus", unique = true, length = 15) private String cartaoSus;
    @Column(name = "data_nascimento", nullable = false) private LocalDate dataNascimento;
    @Column(length = 20) private String telefone;
    @Column(name = "contato_validado", nullable = false) private Boolean contatoValidado;
}
