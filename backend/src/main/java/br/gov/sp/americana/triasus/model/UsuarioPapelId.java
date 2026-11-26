package br.gov.sp.americana.triasus.model;

import jakarta.persistence.Embeddable;
import lombok.EqualsAndHashCode;
import lombok.Getter;
import lombok.Setter;
import java.io.Serializable;

@Embeddable @Getter @Setter @EqualsAndHashCode
public class UsuarioPapelId implements Serializable {
    private Integer usuarioId;
    private Integer papelId;
}

