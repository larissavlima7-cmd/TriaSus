package br.gov.sp.americana.triasus.service;

import br.gov.sp.americana.triasus.dto.RegistrarSinalVitalDTO;
import br.gov.sp.americana.triasus.dto.SinalVitalDTO;
import br.gov.sp.americana.triasus.exception.RecursoNaoEncontradoException;
import br.gov.sp.americana.triasus.exception.RegraNegocioException;
import br.gov.sp.americana.triasus.model.OrigemAfericao;
import br.gov.sp.americana.triasus.model.Profissional;
import br.gov.sp.americana.triasus.model.SinalVital;
import br.gov.sp.americana.triasus.model.Solicitacao;
import br.gov.sp.americana.triasus.repository.ProfissionalRepository;
import br.gov.sp.americana.triasus.repository.SinalVitalRepository;
import br.gov.sp.americana.triasus.repository.SolicitacaoRepository;
import br.gov.sp.americana.triasus.security.UsuarioAutenticado;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;

@Service
public class SinalVitalService {

    private final SinalVitalRepository sinalVitalRepository;
    private final SolicitacaoRepository solicitacaoRepository;
    private final ProfissionalRepository profissionalRepository;
    private final SolicitacaoService solicitacaoService;
    private final AuditoriaService auditoriaService;

    public SinalVitalService(
            SinalVitalRepository sinalVitalRepository,
            SolicitacaoRepository solicitacaoRepository,
            ProfissionalRepository profissionalRepository,
            SolicitacaoService solicitacaoService,
            AuditoriaService auditoriaService
    ) {
        this.sinalVitalRepository = sinalVitalRepository;
        this.solicitacaoRepository = solicitacaoRepository;
        this.profissionalRepository = profissionalRepository;
        this.solicitacaoService = solicitacaoService;
        this.auditoriaService = auditoriaService;
    }

    @Transactional
    public SinalVitalDTO registrar(Integer solicitacaoId, RegistrarSinalVitalDTO dto, UsuarioAutenticado autenticado, String ipOrigem) {
        Solicitacao solicitacao = solicitacaoRepository.findById(solicitacaoId)
                .orElseThrow(() -> new RecursoNaoEncontradoException("Solicitação não encontrada."));

        solicitacaoService.validarAcesso(solicitacao, autenticado, ipOrigem, "POST /api/solicitacoes/" + solicitacaoId + "/sinais-vitais");

        Profissional profissional = null;

        if (dto.origemAfericao() == OrigemAfericao.ACOLHIMENTO_UBS) {
            if (!autenticado.getPapeis().contains("PROFISSIONAL_SAUDE")) {
                throw new AccessDeniedException("Somente profissionais de saúde podem registrar sinais de acolhimento na UBS.");
            }
            profissional = profissionalRepository.findByUsuarioId(autenticado.getUsuarioId())
                    .orElseThrow(() -> new RegraNegocioException("Profissional de saúde não vinculado ao usuário logado."));
        } else if (dto.origemAfericao() == OrigemAfericao.AUTO_RELATO_DOMICILIAR) {
            if (!autenticado.getPapeis().contains("CIDADAO") ||
                    !solicitacao.getPaciente().getUsuario().getId().equals(autenticado.getUsuarioId())) {
                throw new AccessDeniedException("Apenas o cidadão dono da solicitação pode registrar auto-relato domiciliar.");
            }
        }

        SinalVital sinal = new SinalVital();
        sinal.setSolicitacao(solicitacao);
        sinal.setProfissional(profissional);
        sinal.setOrigemAfericao(dto.origemAfericao());
        sinal.setPressaoArterial(dto.pressaoArterial());
        sinal.setFrequenciaCardiaca(dto.frequenciaCardiaca());
        sinal.setTemperatura(dto.temperatura());
        sinal.setGlicemia(dto.glicemia());
        sinal.setSaturacao(dto.saturacao());
        sinal.setAferidoEm(LocalDateTime.now());

        sinal = sinalVitalRepository.save(sinal);

        try {
            auditoriaService.registrarLog(
                    autenticado.getUsuarioId(),
                    "CRIAR",
                    "sinal_vital",
                    "Registro de sinal vital id=" + sinal.getId() + " para solicitacao id=" + solicitacaoId + " com origem=" + dto.origemAfericao(),
                    ipOrigem
            );
        } catch (Exception ignored) {}

        return toDTO(sinal);
    }

    @Transactional(readOnly = true)
    public List<SinalVitalDTO> listarPorSolicitacao(Integer solicitacaoId, UsuarioAutenticado autenticado, String ipOrigem) {
        Solicitacao solicitacao = solicitacaoRepository.findById(solicitacaoId)
                .orElseThrow(() -> new RecursoNaoEncontradoException("Solicitação não encontrada."));

        solicitacaoService.validarAcesso(solicitacao, autenticado, ipOrigem, "GET /api/solicitacoes/" + solicitacaoId + "/sinais-vitais");

        return sinalVitalRepository.findBySolicitacaoIdOrderByAferidoEmDesc(solicitacaoId).stream()
                .map(this::toDTO)
                .toList();
    }

    private SinalVitalDTO toDTO(SinalVital s) {
        return new SinalVitalDTO(
                s.getId(),
                s.getSolicitacao().getId(),
                s.getOrigemAfericao(),
                s.getPressaoArterial(),
                s.getFrequenciaCardiaca(),
                s.getTemperatura(),
                s.getGlicemia(),
                s.getSaturacao(),
                s.getProfissional() != null ? s.getProfissional().getId() : null,
                s.getProfissional() != null ? s.getProfissional().getUsuario().getNome() : null,
                s.getProfissional() != null ? s.getProfissional().getFuncao() : null,
                s.getAferidoEm()
        );
    }
}
