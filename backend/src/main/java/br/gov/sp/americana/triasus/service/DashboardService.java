package br.gov.sp.americana.triasus.service;

import br.gov.sp.americana.triasus.dto.DashboardUbsDTO;
import br.gov.sp.americana.triasus.dto.SolicitacaoResumoDTO;
import br.gov.sp.americana.triasus.model.Profissional;
import br.gov.sp.americana.triasus.model.Solicitacao;
import br.gov.sp.americana.triasus.model.SolicitacaoStatus;
import br.gov.sp.americana.triasus.repository.ProfissionalRepository;
import br.gov.sp.americana.triasus.repository.ProfissionalUnidadeRepository;
import br.gov.sp.americana.triasus.repository.SolicitacaoRepository;
import br.gov.sp.americana.triasus.security.UsuarioAutenticado;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.*;
import java.util.stream.Collectors;

@Service
public class DashboardService {

    private final SolicitacaoRepository solicitacaoRepository;
    private final ProfissionalRepository profissionalRepository;
    private final ProfissionalUnidadeRepository profissionalUnidadeRepository;

    public DashboardService(
            SolicitacaoRepository solicitacaoRepository,
            ProfissionalRepository profissionalRepository,
            ProfissionalUnidadeRepository profissionalUnidadeRepository
    ) {
        this.solicitacaoRepository = solicitacaoRepository;
        this.profissionalRepository = profissionalRepository;
        this.profissionalUnidadeRepository = profissionalUnidadeRepository;
    }

    @Transactional(readOnly = true)
    public DashboardUbsDTO obterDashboard(UsuarioAutenticado autenticado) {
        List<Integer> unidadeIds = obterUnidadesDoUsuario(autenticado);
        if (unidadeIds.isEmpty()) {
            return new DashboardUbsDTO(Map.of(), 0L, Map.of(), List.of());
        }

        List<Solicitacao> solicitacoesUbs = solicitacaoRepository.findAll().stream()
                .filter(s -> unidadeIds.contains(s.getUnidade().getId()))
                .toList();

        Map<String, Long> totaisPorStatus = new LinkedHashMap<>();
        for (SolicitacaoStatus status : SolicitacaoStatus.values()) {
            totaisPorStatus.put(status.name(), 0L);
        }
        for (Solicitacao s : solicitacoesUbs) {
            String st = s.getStatus().name();
            totaisPorStatus.put(st, totaisPorStatus.getOrDefault(st, 0L) + 1);
        }

        long totalPendencias = totaisPorStatus.getOrDefault(SolicitacaoStatus.PENDENCIA_DOCUMENTAL.name(), 0L);

        Map<String, Long> porEspecialidade = solicitacoesUbs.stream()
                .collect(Collectors.groupingBy(s -> s.getEspecialidade().getNome(), Collectors.counting()));

        List<SolicitacaoResumoDTO> recentes = solicitacoesUbs.stream()
                .sorted(Comparator.comparing(Solicitacao::getDataSolicitacao).reversed())
                .limit(10)
                .map(s -> new SolicitacaoResumoDTO(
                        s.getId(),
                        s.getProtocolo(),
                        s.getPaciente().getId(),
                        s.getPaciente().getUsuario().getNome(),
                        s.getEspecialidade().getNome(),
                        s.getUnidade().getNome(),
                        s.getDataSolicitacao(),
                        s.getStatus(),
                        s.getPrioridadeOficial()
                ))
                .toList();

        return new DashboardUbsDTO(totaisPorStatus, totalPendencias, porEspecialidade, recentes);
    }

    private List<Integer> obterUnidadesDoUsuario(UsuarioAutenticado autenticado) {
        Integer profId = autenticado.getProfissionalId();
        if (profId == null) {
            profId = profissionalRepository.findByUsuarioId(autenticado.getUsuarioId())
                    .map(Profissional::getId)
                    .orElse(null);
        }
        if (profId == null) return List.of();

        return profissionalUnidadeRepository.findByProfissionalId(profId).stream()
                .map(pu -> pu.getUnidade().getId())
                .toList();
    }
}
