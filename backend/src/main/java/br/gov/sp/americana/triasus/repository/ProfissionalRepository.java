package br.gov.sp.americana.triasus.repository;

import br.gov.sp.americana.triasus.model.Profissional;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.Optional;

public interface ProfissionalRepository extends JpaRepository<Profissional, Integer> {
    Optional<Profissional> findByUsuarioId(Integer usuarioId);
}

