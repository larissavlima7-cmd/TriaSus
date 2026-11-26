package br.gov.sp.americana.triasus.controller;

import br.gov.sp.americana.triasus.dto.CriarSolicitacaoDTO;
import br.gov.sp.americana.triasus.dto.SolicitacaoDetalheDTO;
import br.gov.sp.americana.triasus.dto.SolicitacaoResumoDTO;
import br.gov.sp.americana.triasus.model.PrioridadeOficial;
import br.gov.sp.americana.triasus.model.SolicitacaoStatus;
import br.gov.sp.americana.triasus.security.UsuarioAutenticado;
import br.gov.sp.americana.triasus.service.SolicitacaoService;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/solicitacoes")
public class SolicitacaoController {

    private final SolicitacaoService solicitacaoService;

    public SolicitacaoController(SolicitacaoService solicitacaoService) {
        this.solicitacaoService = solicitacaoService;
    }

    @PostMapping
    public ResponseEntity<SolicitacaoDetalheDTO> criar(
            @Valid @RequestBody CriarSolicitacaoDTO dto,
            UsuarioAutenticado autenticado,
            HttpServletRequest request
    ) {
        SolicitacaoDetalheDTO detalhe = solicitacaoService.criar(dto, autenticado, obterIp(request));
        return ResponseEntity.status(HttpStatus.CREATED).body(detalhe);
    }

    @GetMapping
    public ResponseEntity<?> listar(
            @RequestParam(required = false) Integer especialidadeId,
            @RequestParam(required = false) SolicitacaoStatus status,
            @RequestParam(required = false) PrioridadeOficial prioridadeOficial,
            Pageable pageable,
            UsuarioAutenticado autenticado
    ) {
        if (autenticado.getPapeis().contains("CIDADAO")) {
            List<SolicitacaoResumoDTO> minhas = solicitacaoService.listarMinhas(autenticado);
            return ResponseEntity.ok(minhas);
        } else {
            Page<SolicitacaoResumoDTO> fila = solicitacaoService.listarFilaUbs(especialidadeId, status, prioridadeOficial, pageable, autenticado);
            return ResponseEntity.ok(fila);
        }
    }

    @GetMapping("/{id}")
    public ResponseEntity<SolicitacaoDetalheDTO> buscarPorId(
            @PathVariable Integer id,
            UsuarioAutenticado autenticado,
            HttpServletRequest request
    ) {
        return ResponseEntity.ok(solicitacaoService.buscarDetalhe(id, autenticado, obterIp(request)));
    }

    @PostMapping("/{id}/enviar")
    public ResponseEntity<SolicitacaoDetalheDTO> enviar(
            @PathVariable Integer id,
            UsuarioAutenticado autenticado,
            HttpServletRequest request
    ) {
        return ResponseEntity.ok(solicitacaoService.enviarParaConferencia(id, autenticado, obterIp(request)));
    }

    private String obterIp(HttpServletRequest request) {
        String xf = request.getHeader("X-Forwarded-For");
        if (xf == null || xf.isBlank()) {
            return request.getRemoteAddr();
        }
        return xf.split(",")[0].trim();
    }
}
