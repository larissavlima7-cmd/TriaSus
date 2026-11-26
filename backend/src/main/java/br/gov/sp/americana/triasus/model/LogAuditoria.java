package br.gov.sp.americana.triasus.model;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;
import java.time.LocalDateTime;

@Entity @Table(name = "log_auditoria") @Getter @Setter
public class LogAuditoria {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY) private Long id;
    @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "usuario_id") private Usuario usuario;
    @Column(nullable = false, length = 50) private String acao;
    @Column(name = "entidade_afetada", length = 50) private String entidadeAfetada;
    @Column(name = "registro_id") private Integer registroId;
    @Column(columnDefinition = "TEXT") private String detalhes;
    @Column(name = "ip_origem", length = 45) private String ipOrigem;
    @Column(name = "data_hora", nullable = false) private LocalDateTime dataHora;
}
