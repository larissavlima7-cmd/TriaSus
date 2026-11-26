package br.gov.sp.americana.triasus.controller;

import br.gov.sp.americana.triasus.dto.RegistrarSinalVitalDTO;
import br.gov.sp.americana.triasus.dto.SinalVitalDTO;
import br.gov.sp.americana.triasus.security.UsuarioAutenticado;
import br.gov.sp.americana.triasus.service.SinalVitalService;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/solicitacoes/{id}/sinais-vitais")
public class SinalVitalController {

    private final SinalVitalService sinalVitalService;

    public SinalVitalController(SinalVitalService sinalVitalService) {
        this.sinalVitalService = sinalVitalService;
    }

    @PostMapping
    public ResponseEntity<SinalVitalDTO> registrar(
            @PathVariable Integer id,
            @Valid @RequestBody RegistrarSinalVitalDTO dto,
            UsuarioAutenticado autenticado,
            HttpServletRequest request
    ) {
        SinalVitalDTO res = sinalVitalService.registrar(id, dto, autenticado, obterIp(request));
        return ResponseEntity.status(HttpStatus.CREATED).body(res);
    }

    @GetMapping
    public ResponseEntity<List<SinalVitalDTO>> listar(
            @PathVariable Integer id,
            UsuarioAutenticado autenticado,
            HttpServletRequest request
    ) {
        return ResponseEntity.ok(sinalVitalService.listarPorSolicitacao(id, autenticado, obterIp(request)));
    }

    private String obterIp(HttpServletRequest request) {
        String xf = request.getHeader("X-Forwarded-For");
        if (xf == null || xf.isBlank()) {
            return request.getRemoteAddr();
        }
        return xf.split(",")[0].trim();
    }
}
