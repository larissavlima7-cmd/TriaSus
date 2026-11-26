package br.gov.sp.americana.triasus.repository;

import br.gov.sp.americana.triasus.model.Paciente;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.Optional;

public interface PacienteRepository extends JpaRepository<Paciente, Integer> {
    Optional<Paciente> findByUsuarioId(Integer usuarioId);
    Optional<Paciente> findByCartaoSus(String cartaoSus);
}

