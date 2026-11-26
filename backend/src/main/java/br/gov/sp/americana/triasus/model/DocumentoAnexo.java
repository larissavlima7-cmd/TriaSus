package br.gov.sp.americana.triasus.model;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;
import java.time.LocalDateTime;

@Entity @Table(name = "documento_anexo") @Getter @Setter
public class DocumentoAnexo {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY) private Integer id;
    @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "solicitacao_id", nullable = false) private Solicitacao solicitacao;
    @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "item_checklist_id", nullable = false) private ChecklistProtocolo itemChecklist;
    @Column(name = "nome_arquivo_original", length = 255) private String nomeArquivoOriginal;
    @Column(name = "url_arquivo", nullable = false, length = 500) private String urlArquivo;
    @Column(name = "tipo_mime", length = 100) private String tipoMime;
    @Column(name = "tamanho_bytes") private Long tamanhoBytes;
    @Enumerated(EnumType.STRING) @Column(name = "status_validacao", nullable = false, length = 20) private StatusValidacao statusValidacao;
    @Column(name = "motivo_rejeicao", columnDefinition = "TEXT") private String motivoRejeicao;
    @Column(name = "enviado_em", nullable = false) private LocalDateTime enviadoEm;
}
