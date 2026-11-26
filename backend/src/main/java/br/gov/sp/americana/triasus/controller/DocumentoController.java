package br.gov.sp.americana.triasus.controller;

import br.gov.sp.americana.triasus.dto.DocumentoAnexoResumoDTO;
import br.gov.sp.americana.triasus.security.UsuarioAutenticado;
import br.gov.sp.americana.triasus.service.DocumentoService;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.core.io.Resource;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

@RestController
public class DocumentoController {

    private final DocumentoService documentoService;

    public DocumentoController(DocumentoService documentoService) {
        this.documentoService = documentoService;
    }

    @PostMapping(value = "/api/solicitacoes/{id}/documentos", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ResponseEntity<DocumentoAnexoResumoDTO> uploadDocumento(
            @PathVariable Integer id,
            @RequestParam("itemChecklistId") Integer itemChecklistId,
            @RequestParam("arquivo") MultipartFile arquivo,
            UsuarioAutenticado autenticado,
            HttpServletRequest request
    ) {
        DocumentoAnexoResumoDTO resumo = documentoService.uploadDocumento(id, itemChecklistId, arquivo, autenticado, obterIp(request));
        return ResponseEntity.status(HttpStatus.CREATED).body(resumo);
    }

    @GetMapping("/api/documentos/{id}")
    public ResponseEntity<Resource> downloadDocumento(
            @PathVariable Integer id,
            UsuarioAutenticado autenticado,
            HttpServletRequest request
    ) {
        DocumentoService.DownloadArquivo download = documentoService.baixarDocumento(id, autenticado, obterIp(request));
        
        String nomeOriginal = download.nomeOriginal() != null ? download.nomeOriginal() : "documento";
        // Sanitizar caracteres proibidos (aspas, quebras de linha, barras, controles)
        String sanitizado = nomeOriginal.replaceAll("[\r\n\"'\\\\/\\x00-\\x1F\\x7F]", "_");
        
        org.springframework.http.ContentDisposition contentDisposition = org.springframework.http.ContentDisposition.inline()
                .filename(sanitizado, java.nio.charset.StandardCharsets.UTF_8)
                .build();

        return ResponseEntity.ok()
                .contentType(MediaType.parseMediaType(download.mimeType()))
                .header(HttpHeaders.CONTENT_DISPOSITION, contentDisposition.toString())
                .header(HttpHeaders.CONTENT_LENGTH, String.valueOf(download.tamanho()))
                .body(download.resource());
    }

    private String obterIp(HttpServletRequest request) {
        String xf = request.getHeader("X-Forwarded-For");
        if (xf == null || xf.isBlank()) {
            return request.getRemoteAddr();
        }
        return xf.split(",")[0].trim();
    }
}
