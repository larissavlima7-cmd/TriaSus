package br.gov.sp.americana.triasus.service;

import br.gov.sp.americana.triasus.dto.AprovarSolicitacaoDTO;
import br.gov.sp.americana.triasus.dto.DevolverSolicitacaoDTO;
import br.gov.sp.americana.triasus.dto.DocumentoAnexoResumoDTO;
import br.gov.sp.americana.triasus.dto.SolicitacaoDetalheDTO;
import br.gov.sp.americana.triasus.dto.ValidarDocumentoDTO;
import br.gov.sp.americana.triasus.exception.RecursoNaoEncontradoException;
import br.gov.sp.americana.triasus.exception.RegraNegocioException;
import br.gov.sp.americana.triasus.model.*;
import br.gov.sp.americana.triasus.repository.ChecklistProtocoloRepository;
import br.gov.sp.americana.triasus.repository.DocumentoAnexoRepository;
import br.gov.sp.americana.triasus.repository.ProfissionalRepository;
import br.gov.sp.americana.triasus.repository.ProfissionalUnidadeRepository;
import br.gov.sp.americana.triasus.repository.SinalVitalRepository;
import br.gov.sp.americana.triasus.repository.SolicitacaoRepository;
import br.gov.sp.americana.triasus.security.UsuarioAutenticado;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Optional;
import java.util.Set;
import java.util.stream.Collectors;

@Service
public class ConferenciaUbsService {

    private final SolicitacaoRepository solicitacaoRepository;
    private final DocumentoAnexoRepository documentoAnexoRepository;
    private final ChecklistProtocoloRepository checklistProtocoloRepository;
    private final ProfissionalRepository profissionalRepository;
    private final ProfissionalUnidadeRepository profissionalUnidadeRepository;
    private final SinalVitalRepository sinalVitalRepository;
    private final SolicitacaoService solicitacaoService;
    private final AuditoriaService auditoriaService;

    public ConferenciaUbsService(
            SolicitacaoRepository solicitacaoRepository,
            DocumentoAnexoRepository documentoAnexoRepository,
            ChecklistProtocoloRepository checklistProtocoloRepository,
            ProfissionalRepository profissionalRepository,
            ProfissionalUnidadeRepository profissionalUnidadeRepository,
            SinalVitalRepository sinalVitalRepository,
            SolicitacaoService solicitacaoService,
            AuditoriaService auditoriaService
    ) {
        this.solicitacaoRepository = solicitacaoRepository;
        this.documentoAnexoRepository = documentoAnexoRepository;
        this.checklistProtocoloRepository = checklistProtocoloRepository;
        this.profissionalRepository = profissionalRepository;
        this.profissionalUnidadeRepository = profissionalUnidadeRepository;
        this.sinalVitalRepository = sinalVitalRepository;
        this.solicitacaoService = solicitacaoService;
        this.auditoriaService = auditoriaService;
    }

    @Transactional
    public SolicitacaoDetalheDTO aprovar(Integer solicitacaoId, AprovarSolicitacaoDTO dto, UsuarioAutenticado autenticado, String ipOrigem) {
        Solicitacao solicitacao = buscarEValidarAcessoProfissional(solicitacaoId, autenticado, ipOrigem, "POST /api/conferencia/" + solicitacaoId + "/aprovar");

        if (solicitacao.getStatus() != SolicitacaoStatus.EM_CONFERENCIA_UBS) {
            throw new RegraNegocioException("Transição inválida: apenas solicitações em conferência podem ser aprovadas.");
        }

        if (dto.prioridadeOficial() == null || dto.prioridadeOficial() == PrioridadeOficial.NAO_DEFINIDA) {
            throw new RegraNegocioException("A prioridade oficial é obrigatória para aprovação e não pode ser NÃO DEFINIDA.");
        }

        List<ChecklistProtocolo> obrigatorios = checklistProtocoloRepository.findByEspecialidadeId(solicitacao.getEspecialidade().getId()).stream()
                .filter(ChecklistProtocolo::getObrigatorio)
                .toList();

        List<DocumentoAnexo> anexos = documentoAnexoRepository.findBySolicitacaoId(solicitacaoId);
        Set<Integer> itensValidos = anexos.stream()
                .filter(a -> a.getStatusValidacao() == StatusValidacao.VALIDO)
                .map(a -> a.getItemChecklist().getId())
                .collect(Collectors.toSet());

        List<String> pendentes = obrigatorios.stream()
                .filter(item -> !itensValidos.contains(item.getId()))
                .map(ChecklistProtocolo::getNomeDocumento)
                .toList();

        if (!pendentes.isEmpty()) {
            throw new RegraNegocioException("Não é possível aprovar a solicitação. Documentos obrigatórios ainda não validados: " + String.join(", ", pendentes));
        }

        Profissional profissional = profissionalRepository.findByUsuarioId(autenticado.getUsuarioId())
                .orElseThrow(() -> new RegraNegocioException("Profissional não localizado para o usuário logado."));

        solicitacao.setProfissionalConferencia(profissional);
        solicitacao.setPrioridadeOficial(dto.prioridadeOficial());
        if (dto.observacaoProfissional() != null && !dto.observacaoProfissional().isBlank()) {
            solicitacao.setObservacaoProfissional(dto.observacaoProfissional());
        }
        solicitacao.setStatus(SolicitacaoStatus.APTO_REGULACAO);
        solicitacaoRepository.save(solicitacao);

        try {
            auditoriaService.registrarLog(
                    autenticado.getUsuarioId(),
                    "APROVAR",
                    "solicitacao",
                    "Aprovação da solicitação id=" + solicitacaoId + " com prioridade=" + dto.prioridadeOficial(),
                    ipOrigem
            );
        } catch (Exception ignored) {}

        return solicitacaoService.buscarDetalhe(solicitacaoId, autenticado, ipOrigem);
    }

    @Transactional
    public SolicitacaoDetalheDTO devolver(Integer solicitacaoId, DevolverSolicitacaoDTO dto, UsuarioAutenticado autenticado, String ipOrigem) {
        Solicitacao solicitacao = buscarEValidarAcessoProfissional(solicitacaoId, autenticado, ipOrigem, "POST /api/conferencia/" + solicitacaoId + "/devolver");

        if (solicitacao.getStatus() != SolicitacaoStatus.EM_CONFERENCIA_UBS) {
            throw new RegraNegocioException("Transição inválida: apenas solicitações em conferência podem ser devolvidas.");
        }

        Optional<DocumentoAnexo> optAnexo = documentoAnexoRepository.findBySolicitacaoIdAndItemChecklistId(solicitacaoId, dto.itemChecklistId());
        if (optAnexo.isEmpty()) {
            throw new RegraNegocioException("Nenhum anexo encontrado para o item de checklist informado.");
        }

        DocumentoAnexo anexo = optAnexo.get();
        anexo.setStatusValidacao(StatusValidacao.REJEITADO);
        anexo.setMotivoRejeicao(dto.motivoRejeicao());
        documentoAnexoRepository.save(anexo);

        solicitacao.setStatus(SolicitacaoStatus.PENDENCIA_DOCUMENTAL);
        solicitacaoRepository.save(solicitacao);

        try {
            auditoriaService.registrarLog(
                    autenticado.getUsuarioId(),
                    "DEVOLVER",
                    "solicitacao",
                    "Devolução da solicitação id=" + solicitacaoId + ". Item " + anexo.getItemChecklist().getNomeDocumento() + " rejeitado: " + dto.motivoRejeicao(),
                    ipOrigem
            );
        } catch (Exception ignored) {}

        return solicitacaoService.buscarDetalhe(solicitacaoId, autenticado, ipOrigem);
    }

    @Transactional
    public DocumentoAnexoResumoDTO validarDocumentoIndividual(Integer documentoId, ValidarDocumentoDTO dto, UsuarioAutenticado autenticado, String ipOrigem) {
        DocumentoAnexo anexo = documentoAnexoRepository.findById(documentoId)
                .orElseThrow(() -> new RecursoNaoEncontradoException("Documento não encontrado."));

        Solicitacao solicitacao = anexo.getSolicitacao();
        solicitacaoService.validarAcesso(solicitacao, autenticado, ipOrigem, "PATCH /api/conferencia/documentos/" + documentoId);

        if (!autenticado.getPapeis().contains("PROFISSIONAL_SAUDE")) {
            throw new AccessDeniedException("Apenas profissional de saúde pode validar ou rejeitar anexos.");
        }

        if (dto.statusValidacao() == StatusValidacao.REJEITADO) {
            if (dto.motivoRejeicao() == null || dto.motivoRejeicao().isBlank()) {
                throw new RegraNegocioException("O motivo de rejeição é obrigatório ao rejeitar um documento.");
            }
            anexo.setStatusValidacao(StatusValidacao.REJEITADO);
            anexo.setMotivoRejeicao(dto.motivoRejeicao());
        } else if (dto.statusValidacao() == StatusValidacao.VALIDO) {
            anexo.setStatusValidacao(StatusValidacao.VALIDO);
            anexo.setMotivoRejeicao(null);
        } else {
            anexo.setStatusValidacao(StatusValidacao.PENDENTE);
            anexo.setMotivoRejeicao(null);
        }

        anexo = documentoAnexoRepository.save(anexo);

        try {
            auditoriaService.registrarLog(
                    autenticado.getUsuarioId(),
                    "ATUALIZAR",
                    "documento_anexo",
                    "Validação de anexo id=" + documentoId + " para status=" + anexo.getStatusValidacao(),
                    ipOrigem
            );
        } catch (Exception ignored) {}

        return new DocumentoAnexoResumoDTO(
                anexo.getId(),
                anexo.getItemChecklist().getId(),
                anexo.getItemChecklist().getNomeDocumento(),
                anexo.getNomeArquivoOriginal(),
                anexo.getTipoMime(),
                anexo.getTamanhoBytes(),
                anexo.getStatusValidacao(),
                anexo.getMotivoRejeicao(),
                anexo.getEnviadoEm()
        );
    }

    @Transactional(readOnly = true)
    public List<br.gov.sp.americana.triasus.dto.PacoteRegulacaoDTO> exportarAptosRegulacao(
            Integer especialidadeId,
            java.time.LocalDate dataInicio,
            java.time.LocalDate dataFim,
            UsuarioAutenticado autenticado,
            String ipOrigem
    ) {
        if (!autenticado.getPapeis().contains("PROFISSIONAL_SAUDE")) {
            auditoriaService.registrarAcessoNegado(autenticado.getUsuarioId(), ipOrigem, "GET /api/conferencia/exportar");
            throw new AccessDeniedException("Apenas profissionais de saúde podem exportar o pacote de regulação.");
        }

        List<Integer> unidadesProfissional = profissionalUnidadeRepository.findByProfissionalId(autenticado.getProfissionalId()).stream()
                .map(pu -> pu.getUnidade().getId())
                .toList();

        if (unidadesProfissional.isEmpty()) {
            return List.of();
        }

        List<Solicitacao> todas = solicitacaoRepository.findAll();
        List<br.gov.sp.americana.triasus.dto.PacoteRegulacaoDTO> resultado = todas.stream()
                .filter(s -> s.getStatus() == SolicitacaoStatus.APTO_REGULACAO)
                .filter(s -> unidadesProfissional.contains(s.getUnidade().getId()))
                .filter(s -> especialidadeId == null || s.getEspecialidade().getId().equals(especialidadeId))
                .filter(s -> dataInicio == null || !s.getDataSolicitacao().toLocalDate().isBefore(dataInicio))
                .filter(s -> dataFim == null || !s.getDataSolicitacao().toLocalDate().isAfter(dataFim))
                .map(this::montarPacoteRegulacao)
                .toList();

        try {
            auditoriaService.registrarLog(
                    autenticado.getUsuarioId(),
                    "EXPORTAR",
                    "solicitacao",
                    "Exportação de pacote de regulação contendo " + resultado.size() + " solicitações aptas",
                    ipOrigem
            );
        } catch (Exception ignored) {}

        return resultado;
    }

    private br.gov.sp.americana.triasus.dto.PacoteRegulacaoDTO montarPacoteRegulacao(Solicitacao s) {
        List<br.gov.sp.americana.triasus.dto.SinalVitalDTO> sinaisAcolhimento = sinalVitalRepository.findBySolicitacaoIdOrderByAferidoEmDesc(s.getId()).stream()
                .filter(sv -> sv.getOrigemAfericao() == OrigemAfericao.ACOLHIMENTO_UBS)
                .map(sv -> new br.gov.sp.americana.triasus.dto.SinalVitalDTO(
                        sv.getId(),
                        sv.getSolicitacao().getId(),
                        sv.getOrigemAfericao(),
                        sv.getPressaoArterial(),
                        sv.getFrequenciaCardiaca(),
                        sv.getTemperatura(),
                        sv.getGlicemia(),
                        sv.getSaturacao(),
                        sv.getProfissional() != null ? sv.getProfissional().getId() : null,
                        sv.getProfissional() != null ? sv.getProfissional().getUsuario().getNome() : null,
                        sv.getProfissional() != null ? sv.getProfissional().getFuncao() : null,
                        sv.getAferidoEm()
                ))
                .toList();

        List<DocumentoAnexoResumoDTO> docsValidos = documentoAnexoRepository.findBySolicitacaoId(s.getId()).stream()
                .filter(a -> a.getStatusValidacao() == StatusValidacao.VALIDO)
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

        br.gov.sp.americana.triasus.dto.PacoteRegulacaoDTO.PacienteRegulacaoDTO pacienteDTO = new br.gov.sp.americana.triasus.dto.PacoteRegulacaoDTO.PacienteRegulacaoDTO(
                s.getPaciente().getId(),
                s.getPaciente().getUsuario().getNome(),
                s.getPaciente().getUsuario().getCpf(),
                s.getPaciente().getCartaoSus(),
                s.getPaciente().getDataNascimento(),
                s.getPaciente().getTelefone(),
                s.getPaciente().getContatoValidado()
        );

        br.gov.sp.americana.triasus.dto.PacoteRegulacaoDTO.ProfissionalRegulacaoDTO profissionalDTO = s.getProfissionalConferencia() != null
                ? new br.gov.sp.americana.triasus.dto.PacoteRegulacaoDTO.ProfissionalRegulacaoDTO(
                        s.getProfissionalConferencia().getId(),
                        s.getProfissionalConferencia().getUsuario().getNome(),
                        s.getProfissionalConferencia().getFuncao(),
                        s.getProfissionalConferencia().getNumeroRegistro()
                )
                : null;

        return new br.gov.sp.americana.triasus.dto.PacoteRegulacaoDTO(
                s.getId(),
                s.getProtocolo(),
                s.getDataSolicitacao(),
                s.getStatus(),
                s.getPrioridadeOficial(),
                s.getObservacaoProfissional(),
                s.getEspecialidade().getNome(),
                s.getUnidade().getNome(),
                s.getUnidade().getCnes(),
                pacienteDTO,
                profissionalDTO,
                s.getQueixaRelatada(),
                s.getTempoEvolucao(),
                sinaisAcolhimento,
                docsValidos
        );
    }

    private Solicitacao buscarEValidarAcessoProfissional(Integer solicitacaoId, UsuarioAutenticado autenticado, String ipOrigem, String rota) {
        Solicitacao solicitacao = solicitacaoRepository.findById(solicitacaoId)
                .orElseThrow(() -> new RecursoNaoEncontradoException("Solicitação não encontrada."));

        if (!autenticado.getPapeis().contains("PROFISSIONAL_SAUDE")) {
            auditoriaService.registrarAcessoNegado(autenticado.getUsuarioId(), ipOrigem, rota);
            throw new AccessDeniedException("Somente profissionais de saúde podem realizar conferência clínica da UBS.");
        }

        solicitacaoService.validarAcesso(solicitacao, autenticado, ipOrigem, rota);
        return solicitacao;
    }
}
