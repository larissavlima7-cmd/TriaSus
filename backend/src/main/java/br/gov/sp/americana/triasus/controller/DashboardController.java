package br.gov.sp.americana.triasus.controller;

import br.gov.sp.americana.triasus.dto.DashboardUbsDTO;
import br.gov.sp.americana.triasus.security.UsuarioAutenticado;
import br.gov.sp.americana.triasus.service.DashboardService;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/ubs")
public class DashboardController {

    private final DashboardService dashboardService;

    public DashboardController(DashboardService dashboardService) {
        this.dashboardService = dashboardService;
    }

    @GetMapping("/dashboard")
    @PreAuthorize("hasAnyRole('PROFISSIONAL_SAUDE', 'RECEPCAO_ACS')")
    public ResponseEntity<DashboardUbsDTO> obterDashboard(UsuarioAutenticado autenticado) {
        return ResponseEntity.ok(dashboardService.obterDashboard(autenticado));
    }
}
