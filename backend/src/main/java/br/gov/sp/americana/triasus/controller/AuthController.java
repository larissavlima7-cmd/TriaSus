package br.gov.sp.americana.triasus.controller;

import br.gov.sp.americana.triasus.dto.AuthResponseDTO;
import br.gov.sp.americana.triasus.dto.LoginCidadaoDTO;
import br.gov.sp.americana.triasus.dto.LoginProfissionalDTO;
import br.gov.sp.americana.triasus.dto.UsuarioMeDTO;
import br.gov.sp.americana.triasus.security.UsuarioAutenticado;
import br.gov.sp.americana.triasus.service.AuthService;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/auth")
public class AuthController {

    private final AuthService authService;

    public AuthController(AuthService authService) {
        this.authService = authService;
    }

    @PostMapping("/cidadao")
    public ResponseEntity<AuthResponseDTO> loginCidadao(@Valid @RequestBody LoginCidadaoDTO dto) {
        return ResponseEntity.ok(authService.loginCidadao(dto));
    }

    @PostMapping("/profissional")
    public ResponseEntity<AuthResponseDTO> loginProfissional(@Valid @RequestBody LoginProfissionalDTO dto) {
        return ResponseEntity.ok(authService.loginProfissional(dto));
    }

    @GetMapping("/me")
    public ResponseEntity<UsuarioMeDTO> me(UsuarioAutenticado autenticado) {
        return ResponseEntity.ok(authService.getUsuarioLogado(autenticado));
    }

    @GetMapping("/teste-profissional")
    @PreAuthorize("hasRole('PROFISSIONAL_SAUDE')")
    public ResponseEntity<String> testeRestritoProfissional() {
        return ResponseEntity.ok("Acesso restrito para profissional de saúde concedido.");
    }
}
