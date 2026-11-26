package br.gov.sp.americana.triasus.service;

import br.gov.sp.americana.triasus.dto.AuthResponseDTO;
import br.gov.sp.americana.triasus.dto.LoginCidadaoDTO;
import br.gov.sp.americana.triasus.dto.LoginProfissionalDTO;
import br.gov.sp.americana.triasus.dto.UsuarioMeDTO;
import br.gov.sp.americana.triasus.exception.CredenciaisInvalidasException;
import br.gov.sp.americana.triasus.exception.RecursoNaoEncontradoException;
import br.gov.sp.americana.triasus.model.Paciente;
import br.gov.sp.americana.triasus.model.Profissional;
import br.gov.sp.americana.triasus.model.Usuario;
import br.gov.sp.americana.triasus.model.UsuarioPapel;
import br.gov.sp.americana.triasus.repository.PacienteRepository;
import br.gov.sp.americana.triasus.repository.ProfissionalRepository;
import br.gov.sp.americana.triasus.repository.UsuarioPapelRepository;
import br.gov.sp.americana.triasus.repository.UsuarioRepository;
import br.gov.sp.americana.triasus.security.TokenService;
import br.gov.sp.americana.triasus.security.UsuarioAutenticado;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.List;
import java.util.Optional;

@Service
public class AuthService {

    private static final String MENSAGEM_ERRO_CREDENCIAIS = "Credenciais inválidas. Verifique os dados informados.";

    private final UsuarioRepository usuarioRepository;
    private final PacienteRepository pacienteRepository;
    private final ProfissionalRepository profissionalRepository;
    private final UsuarioPapelRepository usuarioPapelRepository;
    private final PasswordEncoder passwordEncoder;
    private final TokenService tokenService;

    public AuthService(
            UsuarioRepository usuarioRepository,
            PacienteRepository pacienteRepository,
            ProfissionalRepository profissionalRepository,
            UsuarioPapelRepository usuarioPapelRepository,
            PasswordEncoder passwordEncoder,
            TokenService tokenService
    ) {
        this.usuarioRepository = usuarioRepository;
        this.pacienteRepository = pacienteRepository;
        this.profissionalRepository = profissionalRepository;
        this.usuarioPapelRepository = usuarioPapelRepository;
        this.passwordEncoder = passwordEncoder;
        this.tokenService = tokenService;
    }

    @Transactional(readOnly = true)
    public AuthResponseDTO loginCidadao(LoginCidadaoDTO dto) {
        String idLimpo = dto.identificador() != null ? dto.identificador().replaceAll("[^0-9]", "") : "";
        if (idLimpo.isBlank()) {
            throw new CredenciaisInvalidasException(MENSAGEM_ERRO_CREDENCIAIS);
        }

        Optional<Paciente> optPaciente = Optional.empty();
        if (idLimpo.length() == 11) {
            Optional<Usuario> optUsuario = usuarioRepository.findByCpf(idLimpo);
            if (optUsuario.isPresent()) {
                optPaciente = pacienteRepository.findByUsuarioId(optUsuario.get().getId());
            }
        } else if (idLimpo.length() == 15) {
            optPaciente = pacienteRepository.findByCartaoSus(idLimpo);
        }

        if (optPaciente.isEmpty()) {
            throw new CredenciaisInvalidasException(MENSAGEM_ERRO_CREDENCIAIS);
        }

        Paciente paciente = optPaciente.get();
        Usuario usuario = paciente.getUsuario();

        if (usuario == null || !Boolean.TRUE.equals(usuario.getAtivo())) {
            throw new CredenciaisInvalidasException(MENSAGEM_ERRO_CREDENCIAIS);
        }

        if (dto.dataNascimento() == null || !dto.dataNascimento().equals(paciente.getDataNascimento())) {
            throw new CredenciaisInvalidasException(MENSAGEM_ERRO_CREDENCIAIS);
        }

        List<String> papeis = buscarNomesPapeis(usuario.getId());
        if (!papeis.contains("CIDADAO")) {
            throw new CredenciaisInvalidasException(MENSAGEM_ERRO_CREDENCIAIS);
        }

        Integer profissionalId = profissionalRepository.findByUsuarioId(usuario.getId())
                .map(Profissional::getId)
                .orElse(null);

        Instant expiracao = tokenService.calcularExpiracao();
        String token = tokenService.gerarToken(
                usuario.getId(),
                papeis,
                paciente.getId(),
                profissionalId,
                expiracao
        );

        return new AuthResponseDTO(
                token,
                "Bearer",
                expiracao,
                usuario.getId(),
                usuario.getNome(),
                papeis,
                paciente.getId(),
                profissionalId
        );
    }

    @Transactional(readOnly = true)
    public AuthResponseDTO loginProfissional(LoginProfissionalDTO dto) {
        String loginLimpo = dto.login() != null ? dto.login().trim() : "";
        if (loginLimpo.isBlank() || dto.senha() == null || dto.senha().isBlank()) {
            throw new CredenciaisInvalidasException(MENSAGEM_ERRO_CREDENCIAIS);
        }

        Optional<Usuario> optUsuario;
        String apenasDigitos = loginLimpo.replaceAll("[^0-9]", "");
        if (apenasDigitos.length() == 11 && !loginLimpo.contains("@")) {
            optUsuario = usuarioRepository.findByCpf(apenasDigitos);
        } else {
            optUsuario = usuarioRepository.findByEmail(loginLimpo.toLowerCase());
        }

        if (optUsuario.isEmpty()) {
            throw new CredenciaisInvalidasException(MENSAGEM_ERRO_CREDENCIAIS);
        }

        Usuario usuario = optUsuario.get();
        if (!Boolean.TRUE.equals(usuario.getAtivo())) {
            throw new CredenciaisInvalidasException(MENSAGEM_ERRO_CREDENCIAIS);
        }

        if (usuario.getSenhaHash() == null || !passwordEncoder.matches(dto.senha(), usuario.getSenhaHash())) {
            throw new CredenciaisInvalidasException(MENSAGEM_ERRO_CREDENCIAIS);
        }

        List<String> papeis = buscarNomesPapeis(usuario.getId());
        boolean temPapelEquipe = papeis.contains("PROFISSIONAL_SAUDE") || papeis.contains("RECEPCAO_ACS");
        if (!temPapelEquipe) {
            throw new CredenciaisInvalidasException(MENSAGEM_ERRO_CREDENCIAIS);
        }

        Integer pacienteId = pacienteRepository.findByUsuarioId(usuario.getId())
                .map(Paciente::getId)
                .orElse(null);
        Integer profissionalId = profissionalRepository.findByUsuarioId(usuario.getId())
                .map(Profissional::getId)
                .orElse(null);

        Instant expiracao = tokenService.calcularExpiracao();
        String token = tokenService.gerarToken(
                usuario.getId(),
                papeis,
                pacienteId,
                profissionalId,
                expiracao
        );

        return new AuthResponseDTO(
                token,
                "Bearer",
                expiracao,
                usuario.getId(),
                usuario.getNome(),
                papeis,
                pacienteId,
                profissionalId
        );
    }

    @Transactional(readOnly = true)
    public UsuarioMeDTO getUsuarioLogado(UsuarioAutenticado autenticado) {
        Usuario usuario = usuarioRepository.findById(autenticado.getUsuarioId())
                .orElseThrow(() -> new RecursoNaoEncontradoException("Usuário não encontrado."));

        return new UsuarioMeDTO(
                usuario.getId(),
                usuario.getNome(),
                usuario.getEmail(),
                usuario.getCpf(),
                autenticado.getPapeis(),
                autenticado.getPacienteId(),
                autenticado.getProfissionalId()
        );
    }

    private List<String> buscarNomesPapeis(Integer usuarioId) {
        return usuarioPapelRepository.findByUsuarioId(usuarioId).stream()
                .map(up -> up.getPapel().getNome().name())
                .toList();
    }
}
