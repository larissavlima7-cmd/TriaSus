package br.gov.sp.americana.triasus.service;

import br.gov.sp.americana.triasus.model.LogAuditoria;
import br.gov.sp.americana.triasus.model.Usuario;
import br.gov.sp.americana.triasus.repository.LogAuditoriaRepository;
import br.gov.sp.americana.triasus.repository.UsuarioRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;

@Service
public class AuditoriaService {

    private final LogAuditoriaRepository logAuditoriaRepository;
    private final UsuarioRepository usuarioRepository;

    public AuditoriaService(LogAuditoriaRepository logAuditoriaRepository, UsuarioRepository usuarioRepository) {
        this.logAuditoriaRepository = logAuditoriaRepository;
        this.usuarioRepository = usuarioRepository;
    }

    @Transactional(propagation = Propagation.REQUIRES_NEW)
    public void registrarLog(Integer usuarioId, String acao, String entidade, String detalhes, String ipOrigem) {
        LogAuditoria auditoria = new LogAuditoria();
        if (usuarioId != null) {
            Usuario usuario = usuarioRepository.findById(usuarioId).orElse(null);
            auditoria.setUsuario(usuario);
        }
        auditoria.setAcao(acao);
        auditoria.setEntidadeAfetada(entidade);
        auditoria.setDetalhes(detalhes);
        auditoria.setIpOrigem(ipOrigem);
        auditoria.setDataHora(LocalDateTime.now());
        logAuditoriaRepository.save(auditoria);
    }

    @Transactional(propagation = Propagation.REQUIRES_NEW)
    public void registrarAcessoNegado(Integer usuarioId, String ipOrigem, String rota) {
        registrarLog(usuarioId, "ACESSO_NEGADO", "ROTA", "Acesso negado à rota: " + rota, ipOrigem);
    }
}
