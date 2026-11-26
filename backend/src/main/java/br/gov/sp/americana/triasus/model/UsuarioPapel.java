package br.gov.sp.americana.triasus.model;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

@Entity @Table(name = "usuario_papel") @Getter @Setter
public class UsuarioPapel {
    @EmbeddedId private UsuarioPapelId id;
    @MapsId("usuarioId") @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "usuario_id", nullable = false) private Usuario usuario;
    @MapsId("papelId") @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "papel_id", nullable = false) private Papel papel;
}
