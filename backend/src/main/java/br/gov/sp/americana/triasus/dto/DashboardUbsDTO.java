package br.gov.sp.americana.triasus.dto;

import java.util.List;
import java.util.Map;

public record DashboardUbsDTO(
    Map<String, Long> totaisPorStatus,
    long totalPendenciasDocumentais,
    Map<String, Long> encaminhamentosPorEspecialidade,
    List<SolicitacaoResumoDTO> solicitacoesRecentes
) {}
