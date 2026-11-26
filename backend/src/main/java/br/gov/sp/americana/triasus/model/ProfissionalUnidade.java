package br.gov.sp.americana.triasus.model;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

@Entity @Table(name = "profissional_unidade") @Getter @Setter
public class ProfissionalUnidade {
    @EmbeddedId private ProfissionalUnidadeId id;
    @MapsId("profissionalId") @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "profissional_id", nullable = false) private Profissional profissional;
    @MapsId("unidadeId") @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "unidade_id", nullable = false) private UnidadeUbs unidade;
}
