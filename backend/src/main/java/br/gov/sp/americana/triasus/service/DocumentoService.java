package br.gov.sp.americana.triasus.service;

import br.gov.sp.americana.triasus.dto.DocumentoAnexoResumoDTO;
import br.gov.sp.americana.triasus.exception.RecursoNaoEncontradoException;
import br.gov.sp.americana.triasus.exception.RegraNegocioException;
import br.gov.sp.americana.triasus.model.*;
import br.gov.sp.americana.triasus.repository.ChecklistProtocoloRepository;
import br.gov.sp.americana.triasus.repository.DocumentoAnexoRepository;
import br.gov.sp.americana.triasus.repository.SolicitacaoRepository;
import br.gov.sp.americana.triasus.security.UsuarioAutenticado;
import jakarta.annotation.PostConstruct;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.io.Resource;
import org.springframework.core.io.UrlResource;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.io.InputStream;
import java.net.MalformedURLException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;
import java.time.LocalDateTime;
import java.util.Optional;
import java.util.UUID;

@Service
public class DocumentoService {

    private static final long MAX_FILE_SIZE = 5 * 1024 * 1024; // 5 MB

    @Value("${app.upload-dir:uploads}")
    private String uploadDirProperty;

    private Path uploadDirPath;

    private final DocumentoAnexoRepository documentoAnexoRepository;
    private final SolicitacaoRepository solicitacaoRepository;
    private final ChecklistProtocoloRepository checklistProtocoloRepository;
    private final SolicitacaoService solicitacaoService;
    private final AuditoriaService auditoriaService;

    public DocumentoService(
            DocumentoAnexoRepository documentoAnexoRepository,
            SolicitacaoRepository solicitacaoRepository,
            ChecklistProtocoloRepository checklistProtocoloRepository,
            SolicitacaoService solicitacaoService,
            AuditoriaService auditoriaService
    ) {
        this.documentoAnexoRepository = documentoAnexoRepository;
        this.solicitacaoRepository = solicitacaoRepository;
        this.checklistProtocoloRepository = checklistProtocoloRepository;
        this.solicitacaoService = solicitacaoService;
        this.auditoriaService = auditoriaService;
    }

    @PostConstruct
    public void init() {
        this.uploadDirPath = Paths.get(uploadDirProperty).toAbsolutePath().normalize();
        try {
            Files.createDirectories(this.uploadDirPath);
        } catch (IOException e) {
            throw new IllegalStateException("Não foi possível criar o diretório de uploads: " + uploadDirPath, e);
        }
    }

    @Transactional
    public DocumentoAnexoResumoDTO uploadDocumento(
            Integer solicitacaoId,
            Integer itemChecklistId,
            MultipartFile file,
            UsuarioAutenticado autenticado,
            String ipOrigem
    ) {
        if (file == null || file.isEmpty()) {
            throw new RegraNegocioException("Arquivo de anexo é obrigatório.");
        }

        if (file.getSize() > MAX_FILE_SIZE) {
            throw new RegraNegocioException("Arquivo excede o limite máximo permitido de 5 MB.");
        }

        Solicitacao solicitacao = solicitacaoRepository.findById(solicitacaoId)
                .orElseThrow(() -> new RecursoNaoEncontradoException("Solicitação não encontrada."));

        solicitacaoService.validarAcesso(solicitacao, autenticado, ipOrigem, "POST /api/solicitacoes/" + solicitacaoId + "/documentos");

        ChecklistProtocolo itemChecklist = checklistProtocoloRepository.findById(itemChecklistId)
                .orElseThrow(() -> new RecursoNaoEncontradoException("Item de checklist não encontrado."));

        if (!itemChecklist.getEspecialidade().getId().equals(solicitacao.getEspecialidade().getId())) {
            throw new RegraNegocioException("O item de checklist informado não pertence à especialidade da solicitação.");
        }

        String mimeReal = detectarMimeReal(file);
        if (mimeReal == null) {
            throw new RegraNegocioException("Formato de arquivo não suportado. Envie apenas JPG, PNG ou PDF.");
        }

        String extensao = switch (mimeReal) {
            case "image/jpeg" -> ".jpg";
            case "image/png" -> ".png";
            case "application/pdf" -> ".pdf";
            default -> "";
        };

        String nomeArquivoDisco = UUID.randomUUID() + extensao;
        Path destino = this.uploadDirPath.resolve(nomeArquivoDisco).normalize();

        try (InputStream inputStream = file.getInputStream()) {
            Files.copy(inputStream, destino, StandardCopyOption.REPLACE_EXISTING);
        } catch (IOException e) {
            throw new IllegalStateException("Falha ao salvar arquivo no disco.", e);
        }

        Optional<DocumentoAnexo> anexoExistente = documentoAnexoRepository.findBySolicitacaoIdAndItemChecklistId(solicitacaoId, itemChecklistId);
        DocumentoAnexo anexo;

        if (anexoExistente.isPresent()) {
            anexo = anexoExistente.get();
            try {
                Path antigo = Paths.get(anexo.getUrlArquivo());
                Files.deleteIfExists(antigo);
            } catch (Exception ignored) {}

            anexo.setNomeArquivoOriginal(file.getOriginalFilename());
            anexo.setUrlArquivo(destino.toString());
            anexo.setTipoMime(mimeReal);
            anexo.setTamanhoBytes(file.getSize());
            anexo.setStatusValidacao(StatusValidacao.PENDENTE);
            anexo.setMotivoRejeicao(null);
            anexo.setEnviadoEm(LocalDateTime.now());
        } else {
            anexo = new DocumentoAnexo();
            anexo.setSolicitacao(solicitacao);
            anexo.setItemChecklist(itemChecklist);
            anexo.setNomeArquivoOriginal(file.getOriginalFilename());
            anexo.setUrlArquivo(destino.toString());
            anexo.setTipoMime(mimeReal);
            anexo.setTamanhoBytes(file.getSize());
            anexo.setStatusValidacao(StatusValidacao.PENDENTE);
            anexo.setEnviadoEm(LocalDateTime.now());
        }

        anexo = documentoAnexoRepository.save(anexo);

        if (solicitacao.getStatus() == SolicitacaoStatus.PENDENCIA_DOCUMENTAL) {
            solicitacao.setStatus(SolicitacaoStatus.EM_CONFERENCIA_UBS);
            solicitacaoRepository.save(solicitacao);
        }

        return new DocumentoAnexoResumoDTO(
                anexo.getId(),
                itemChecklist.getId(),
                itemChecklist.getNomeDocumento(),
                anexo.getNomeArquivoOriginal(),
                anexo.getTipoMime(),
                anexo.getTamanhoBytes(),
                anexo.getStatusValidacao(),
                anexo.getMotivoRejeicao(),
                anexo.getEnviadoEm()
        );
    }

    @Transactional(readOnly = true)
    public DownloadArquivo baixarDocumento(Integer documentoId, UsuarioAutenticado autenticado, String ipOrigem) {
        DocumentoAnexo anexo = documentoAnexoRepository.findById(documentoId)
                .orElseThrow(() -> new RecursoNaoEncontradoException("Documento não encontrado."));

        Solicitacao solicitacao = anexo.getSolicitacao();
        solicitacaoService.validarAcesso(solicitacao, autenticado, ipOrigem, "GET /api/documentos/" + documentoId);

        try {
            auditoriaService.registrarLog(
                    autenticado.getUsuarioId(),
                    "VISUALIZAR",
                    "documento_anexo",
                    "Visualização clínica do anexo id=" + documentoId + " (" + anexo.getNomeArquivoOriginal() + ")",
                    ipOrigem
            );
        } catch (Exception ignored) {}

        try {
            Path path = Paths.get(anexo.getUrlArquivo());
            Resource resource = new UrlResource(path.toUri());
            if (!resource.exists() || !resource.isReadable()) {
                throw new RecursoNaoEncontradoException("Arquivo físico não encontrado no servidor.");
            }
            return new DownloadArquivo(resource, anexo.getTipoMime(), anexo.getNomeArquivoOriginal(), anexo.getTamanhoBytes());
        } catch (MalformedURLException e) {
            throw new IllegalStateException("Erro ao carregar arquivo físico.", e);
        }
    }

    private String detectarMimeReal(MultipartFile file) {
        try (InputStream is = file.getInputStream()) {
            byte[] header = new byte[8];
            int read = is.read(header);
            if (read < 4) return null;

            // PDF: %PDF (0x25 0x50 0x44 0x46)
            if (header[0] == 0x25 && header[1] == 0x50 && header[2] == 0x44 && header[3] == 0x46) {
                return "application/pdf";
            }

            // PNG: 89 50 4E 47 0D 0A 1A 0A
            if ((header[0] & 0xFF) == 0x89 && header[1] == 0x50 && header[2] == 0x4E && header[3] == 0x47) {
                return "image/png";
            }

            // JPEG: FF D8 FF
            if ((header[0] & 0xFF) == 0xFF && (header[1] & 0xFF) == 0xD8 && (header[2] & 0xFF) == 0xFF) {
                return "image/jpeg";
            }

            return null;
        } catch (IOException e) {
            return null;
        }
    }

    public record DownloadArquivo(Resource resource, String mimeType, String nomeOriginal, Long tamanho) {}
}
