package br.gov.sp.americana.triasus.controller;

import br.gov.sp.americana.triasus.dto.AprovarSolicitacaoDTO;
import br.gov.sp.americana.triasus.dto.DevolverSolicitacaoDTO;
import br.gov.sp.americana.triasus.dto.DocumentoAnexoResumoDTO;
import br.gov.sp.americana.triasus.dto.SolicitacaoDetalheDTO;
import br.gov.sp.americana.triasus.dto.ValidarDocumentoDTO;
import br.gov.sp.americana.triasus.security.UsuarioAutenticado;
import br.gov.sp.americana.triasus.service.ConferenciaUbsService;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/conferencia")
public class ConferenciaUbsController {

    private final ConferenciaUbsService conferenciaUbsService;

    public ConferenciaUbsController(ConferenciaUbsService conferenciaUbsService) {
        this.conferenciaUbsService = conferenciaUbsService;
    }

    @PostMapping("/{id}/aprovar")
    @PreAuthorize("hasRole('PROFISSIONAL_SAUDE')")
    public ResponseEntity<SolicitacaoDetalheDTO> aprovar(
            @PathVariable Integer id,
            @Valid @RequestBody AprovarSolicitacaoDTO dto,
            UsuarioAutenticado autenticado,
            HttpServletRequest request
    ) {
        return ResponseEntity.ok(conferenciaUbsService.aprovar(id, dto, autenticado, obterIp(request)));
    }

    @PostMapping("/{id}/devolver")
    @PreAuthorize("hasRole('PROFISSIONAL_SAUDE')")
    public ResponseEntity<SolicitacaoDetalheDTO> devolver(
            @PathVariable Integer id,
            @Valid @RequestBody DevolverSolicitacaoDTO dto,
            UsuarioAutenticado autenticado,
            HttpServletRequest request
    ) {
        return ResponseEntity.ok(conferenciaUbsService.devolver(id, dto, autenticado, obterIp(request)));
    }

    @PatchMapping("/documentos/{documentoId}")
    @PreAuthorize("hasRole('PROFISSIONAL_SAUDE')")
    public ResponseEntity<DocumentoAnexoResumoDTO> validarDocumento(
            @PathVariable Integer documentoId,
            @Valid @RequestBody ValidarDocumentoDTO dto,
            UsuarioAutenticado autenticado,
            HttpServletRequest request
    ) {
        return ResponseEntity.ok(conferenciaUbsService.validarDocumentoIndividual(documentoId, dto, autenticado, obterIp(request)));
    }

    @GetMapping("/exportar")
    @PreAuthorize("hasRole('PROFISSIONAL_SAUDE')")
    public ResponseEntity<java.util.List<br.gov.sp.americana.triasus.dto.PacoteRegulacaoDTO>> exportar(
            @RequestParam(required = false) Integer especialidadeId,
            @RequestParam(required = false) java.time.LocalDate dataInicio,
            @RequestParam(required = false) java.time.LocalDate dataFim,
            UsuarioAutenticado autenticado,
            HttpServletRequest request
    ) {
        return ResponseEntity.ok(conferenciaUbsService.exportarAptosRegulacao(especialidadeId, dataInicio, dataFim, autenticado, obterIp(request)));
    }

    private String obterIp(HttpServletRequest request) {
        String xf = request.getHeader("X-Forwarded-For");
        if (xf == null || xf.isBlank()) {
            return request.getRemoteAddr();
        }
        return xf.split(",")[0].trim();
    }
}
