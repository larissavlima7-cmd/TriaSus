package br.gov.sp.americana.triasus.service;

import br.gov.sp.americana.triasus.dto.*;
import br.gov.sp.americana.triasus.exception.RecursoNaoEncontradoException;
import br.gov.sp.americana.triasus.exception.RegraNegocioException;
import br.gov.sp.americana.triasus.model.*;
import br.gov.sp.americana.triasus.repository.*;
import br.gov.sp.americana.triasus.security.UsuarioAutenticado;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.time.Year;
import java.util.ArrayList;
import java.util.List;
import java.util.Set;
import java.util.stream.Collectors;

@Service
public class SolicitacaoService {

    private final SolicitacaoRepository solicitacaoRepository;
    private final EspecialidadeRepository especialidadeRepository;
    private final PacienteRepository pacienteRepository;
    private final UsuarioRepository usuarioRepository;
    private final ProfissionalRepository profissionalRepository;
    private final ProfissionalUnidadeRepository profissionalUnidadeRepository;
    private final ChecklistProtocoloRepository checklistProtocoloRepository;
    private final DocumentoAnexoRepository documentoAnexoRepository;
    private final AuditoriaService auditoriaService;

    public SolicitacaoService(
            SolicitacaoRepository solicitacaoRepository,
            EspecialidadeRepository especialidadeRepository,
            PacienteRepository pacienteRepository,
            UsuarioRepository usuarioRepository,
            ProfissionalRepository profissionalRepository,
            ProfissionalUnidadeRepository profissionalUnidadeRepository,
            ChecklistProtocoloRepository checklistProtocoloRepository,
            DocumentoAnexoRepository documentoAnexoRepository,
            AuditoriaService auditoriaService
    ) {
        this.solicitacaoRepository = solicitacaoRepository;
        this.especialidadeRepository = especialidadeRepository;
        this.pacienteRepository = pacienteRepository;
        this.usuarioRepository = usuarioRepository;
        this.profissionalRepository = profissionalRepository;
        this.profissionalUnidadeRepository = profissionalUnidadeRepository;
        this.checklistProtocoloRepository = checklistProtocoloRepository;
        this.documentoAnexoRepository = documentoAnexoRepository;
        this.auditoriaService = auditoriaService;
    }

    @Transactional
    public SolicitacaoDetalheDTO criar(CriarSolicitacaoDTO dto, UsuarioAutenticado autenticado, String ipOrigem) {
        Especialidade especialidade = especialidadeRepository.findById(dto.especialidadeId())
                .orElseThrow(() -> new RecursoNaoEncontradoException("Especialidade não encontrada."));

        Paciente paciente;
        if (autenticado.getPapeis().contains("CIDADAO")) {
            paciente = pacienteRepository.findByUsuarioId(autenticado.getUsuarioId())
                    .orElseThrow(() -> new RecursoNaoEncontradoException("Cadastro de paciente não localizado para o cidadão logado."));
        } else if (autenticado.getPapeis().contains("RECEPCAO_ACS")) {
            if (dto.pacienteId() == null) {
                throw new RegraNegocioException("É necessário informar o paciente para cadastro assistido pela recepção/ACS.");
            }
            paciente = pacienteRepository.findById(dto.pacienteId())
                    .orElseThrow(() -> new RecursoNaoEncontradoException("Paciente não encontrado."));
        } else {
            throw new AccessDeniedException("Perfil não autorizado a criar solicitações.");
        }

        if (paciente.getUnidadeReferencia() == null) {
            throw new RegraNegocioException("O paciente precisa ter uma UBS de referência associada.");
        }

        Usuario usuarioCriador = usuarioRepository.findById(autenticado.getUsuarioId())
                .orElseThrow(() -> new RecursoNaoEncontradoException("Usuário criador não encontrado."));

        Solicitacao solicitacao = new Solicitacao();
        solicitacao.setPaciente(paciente);
        solicitacao.setEspecialidade(especialidade);
        solicitacao.setUnidade(paciente.getUnidadeReferencia());
        solicitacao.setCriadaPorUsuario(usuarioCriador);
        solicitacao.setDataSolicitacao(LocalDateTime.now());
        solicitacao.setStatus(SolicitacaoStatus.RASCUNHO);
        solicitacao.setPrioridadeOficial(PrioridadeOficial.NAO_DEFINIDA);
        solicitacao.setQueixaRelatada(dto.queixaRelatada());
        solicitacao.setTempoEvolucao(dto.tempoEvolucao());
        solicitacao.setProtocolo(gerarProtocoloTemporario());

        solicitacao = solicitacaoRepository.saveAndFlush(solicitacao);
        solicitacao.setProtocolo(formatarProtocolo(solicitacao.getId()));
        solicitacao = solicitacaoRepository.save(solicitacao);

        return buscarDetalhe(solicitacao.getId(), autenticado, ipOrigem);
    }

    @Transactional(readOnly = true)
    public List<SolicitacaoResumoDTO> listarMinhas(UsuarioAutenticado autenticado) {
        if (!autenticado.getPapeis().contains("CIDADAO")) {
            throw new AccessDeniedException("Apenas cidadãos podem acessar a listagem pessoal.");
        }
        Paciente paciente = pacienteRepository.findByUsuarioId(autenticado.getUsuarioId())
                .orElseThrow(() -> new RecursoNaoEncontradoException("Paciente não localizado."));

        return solicitacaoRepository.findByPacienteIdOrderByDataSolicitacaoDesc(paciente.getId()).stream()
                .map(this::toResumoDTO)
                .toList();
    }

    @Transactional(readOnly = true)
    public Page<SolicitacaoResumoDTO> listarFilaUbs(
            Integer especialidadeId,
            SolicitacaoStatus status,
            PrioridadeOficial prioridade,
            Pageable pageable,
            UsuarioAutenticado autenticado
    ) {
        List<Integer> unidadeIds = obterUnidadesDoProfissional(autenticado);
        if (unidadeIds.isEmpty()) {
            return Page.empty(pageable);
        }

        return solicitacaoRepository.findFilaUbs(unidadeIds, especialidadeId, status, prioridade, pageable)
                .map(this::toResumoDTO);
    }

    @Transactional(readOnly = true)
    public SolicitacaoDetalheDTO buscarDetalhe(Integer id, UsuarioAutenticado autenticado, String ipOrigem) {
        Solicitacao s = solicitacaoRepository.findById(id)
                .orElseThrow(() -> new RecursoNaoEncontradoException("Solicitação não encontrada."));

        validarAcesso(s, autenticado, ipOrigem, "GET /api/solicitacoes/" + id);

        List<ChecklistItemDTO> checklist = checklistProtocoloRepository.findByEspecialidadeId(s.getEspecialidade().getId()).stream()
                .map(c -> new ChecklistItemDTO(c.getId(), c.getEspecialidade().getId(), c.getNomeDocumento(), c.getDescricaoOrientacao(), c.getObrigatorio()))
                .toList();

        List<DocumentoAnexoResumoDTO> anexos = documentoAnexoRepository.findBySolicitacaoId(s.getId()).stream()
                .map(a -> new DocumentoAnexoResumoDTO(
                        a.getId(),
                        a.getItemChecklist().getId(),
                        a.getItemChecklist().getNomeDocumento(),
                        a.getNomeArquivoOriginal(),
                        a.getTipoMime(),
                        a.getTamanhoBytes(),
                        a.getStatusValidacao(),
                        a.getMotivoRejeicao(),
                        a.getEnviadoEm()
                ))
                .toList();

        List<LinhaTempoEventoDTO> linhaDoTempo = new ArrayList<>();
        linhaDoTempo.add(new LinhaTempoEventoDTO("RASCUNHO", "Solicitação criada", s.getDataSolicitacao()));
        if (s.getStatus() != SolicitacaoStatus.RASCUNHO) {
            linhaDoTempo.add(new LinhaTempoEventoDTO(s.getStatus().name(), "Situação atualizada para " + s.getStatus().name(), LocalDateTime.now()));
        }

        return new SolicitacaoDetalheDTO(
                s.getId(),
                s.getProtocolo(),
                s.getPaciente().getId(),
                s.getPaciente().getUsuario().getNome(),
                s.getPaciente().getUsuario().getCpf(),
                s.getPaciente().getCartaoSus(),
                s.getEspecialidade().getId(),
                s.getEspecialidade().getNome(),
                s.getUnidade().getId(),
                s.getUnidade().getNome(),
                s.getProfissionalConferencia() != null ? s.getProfissionalConferencia().getId() : null,
                s.getProfissionalConferencia() != null ? s.getProfissionalConferencia().getUsuario().getNome() : null,
                s.getCriadaPorUsuario() != null ? s.getCriadaPorUsuario().getId() : null,
                s.getCriadaPorUsuario() != null ? s.getCriadaPorUsuario().getNome() : null,
                s.getDataSolicitacao(),
                s.getStatus(),
                s.getPrioridadeOficial(),
                s.getQueixaRelatada(),
                s.getTempoEvolucao(),
                s.getObservacaoProfissional(),
                checklist,
                anexos,
                linhaDoTempo
        );
    }

    @Transactional
    public SolicitacaoDetalheDTO enviarParaConferencia(Integer id, UsuarioAutenticado autenticado, String ipOrigem) {
        Solicitacao s = solicitacaoRepository.findById(id)
                .orElseThrow(() -> new RecursoNaoEncontradoException("Solicitação não encontrada."));

        validarAcesso(s, autenticado, ipOrigem, "POST /api/solicitacoes/" + id + "/enviar");

        List<ChecklistProtocolo> itensObrigatorios = checklistProtocoloRepository.findByEspecialidadeId(s.getEspecialidade().getId()).stream()
                .filter(ChecklistProtocolo::getObrigatorio)
                .toList();

        List<DocumentoAnexo> anexos = documentoAnexoRepository.findBySolicitacaoId(s.getId());
        Set<Integer> itensComAnexoValido = anexos.stream()
                .filter(a -> a.getStatusValidacao() == StatusValidacao.VALIDO || a.getStatusValidacao() == StatusValidacao.PENDENTE)
                .map(a -> a.getItemChecklist().getId())
                .collect(Collectors.toSet());

        List<String> faltantes = itensObrigatorios.stream()
                .filter(item -> !itensComAnexoValido.contains(item.getId()))
                .map(ChecklistProtocolo::getNomeDocumento)
                .toList();

        if (!faltantes.isEmpty()) {
            throw new RegraNegocioException("Não é possível enviar para conferência. Documentos obrigatórios pendentes: " + String.join(", ", faltantes));
        }

        s.setStatus(SolicitacaoStatus.EM_CONFERENCIA_UBS);
        solicitacaoRepository.save(s);

        return buscarDetalhe(id, autenticado, ipOrigem);
    }

    public void validarAcesso(Solicitacao s, UsuarioAutenticado autenticado, String ipOrigem, String rota) {
        if (autenticado.getPapeis().contains("CIDADAO")) {
            if (!s.getPaciente().getUsuario().getId().equals(autenticado.getUsuarioId())) {
                auditoriaService.registrarAcessoNegado(autenticado.getUsuarioId(), ipOrigem, rota);
                throw new AccessDeniedException("Cidadão não tem permissão para acessar solicitação de outro paciente.");
            }
            return;
        }

        List<Integer> unidadesProfissional = obterUnidadesDoProfissional(autenticado);
        if (!unidadesProfissional.contains(s.getUnidade().getId())) {
            auditoriaService.registrarAcessoNegado(autenticado.getUsuarioId(), ipOrigem, rota);
            throw new AccessDeniedException("Profissional não tem permissão para acessar solicitação de UBS fora de sua atuação.");
        }
    }

    private List<Integer> obterUnidadesDoProfissional(UsuarioAutenticado autenticado) {
        if (autenticado.getProfissionalId() == null) {
            Profissional prof = profissionalRepository.findByUsuarioId(autenticado.getUsuarioId()).orElse(null);
            if (prof == null) return List.of();
            return profissionalUnidadeRepository.findByProfissionalId(prof.getId()).stream()
                    .map(pu -> pu.getUnidade().getId())
                    .toList();
        }
        return profissionalUnidadeRepository.findByProfissionalId(autenticado.getProfissionalId()).stream()
                .map(pu -> pu.getUnidade().getId())
                .toList();
    }

    private SolicitacaoResumoDTO toResumoDTO(Solicitacao s) {
        return new SolicitacaoResumoDTO(
                s.getId(),
                s.getProtocolo(),
                s.getPaciente().getId(),
                s.getPaciente().getUsuario().getNome(),
                s.getEspecialidade().getNome(),
                s.getUnidade().getNome(),
                s.getDataSolicitacao(),
                s.getStatus(),
                s.getPrioridadeOficial()
        );
    }

    private String gerarProtocoloTemporario() {
        return "TMP-" + System.currentTimeMillis();
    }

    private String formatarProtocolo(Integer id) {
        int ano = Year.now().getValue();
        return String.format("TRIA-%d-%06d", ano, id);
    }
}
