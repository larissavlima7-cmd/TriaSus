package br.gov.sp.americana.triasus.controller;

import br.gov.sp.americana.triasus.dto.AtualizarContatoDTO;
import br.gov.sp.americana.triasus.dto.PacienteDTO;
import br.gov.sp.americana.triasus.exception.RecursoNaoEncontradoException;
import br.gov.sp.americana.triasus.model.Paciente;
import br.gov.sp.americana.triasus.repository.PacienteRepository;
import br.gov.sp.americana.triasus.security.UsuarioAutenticado;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/pacientes")
public class PacienteController {

    private final PacienteRepository pacienteRepository;

    public PacienteController(PacienteRepository pacienteRepository) {
        this.pacienteRepository = pacienteRepository;
    }

    @PostMapping("/me/contato")
    @PreAuthorize("hasRole('CIDADAO')")
    @Transactional
    public ResponseEntity<PacienteDTO> atualizarContato(
            UsuarioAutenticado autenticado,
            @Valid @RequestBody AtualizarContatoDTO dto
    ) {
        Paciente paciente = pacienteRepository.findByUsuarioId(autenticado.getUsuarioId())
                .orElseThrow(() -> new RecursoNaoEncontradoException("Paciente não encontrado para o usuário logado."));

        String telefoneLimpo = dto.telefone().replaceAll("[^0-9]", "");
        paciente.setTelefone(telefoneLimpo);
        paciente.setContatoValidado(true);
        pacienteRepository.save(paciente);

        PacienteDTO res = new PacienteDTO(
                paciente.getId(),
                paciente.getUsuario().getId(),
                paciente.getUsuario().getNome(),
                paciente.getUsuario().getCpf(),
                paciente.getCartaoSus(),
                paciente.getDataNascimento(),
                paciente.getTelefone(),
                paciente.getContatoValidado(),
                paciente.getUnidadeReferencia() != null ? paciente.getUnidadeReferencia().getId() : null,
                paciente.getUnidadeReferencia() != null ? paciente.getUnidadeReferencia().getNome() : null
        );

        return ResponseEntity.ok(res);
    }
}

