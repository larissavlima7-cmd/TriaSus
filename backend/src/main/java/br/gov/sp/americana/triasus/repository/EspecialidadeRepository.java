package br.gov.sp.americana.triasus.repository;

import br.gov.sp.americana.triasus.model.Especialidade;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;

public interface EspecialidadeRepository extends JpaRepository<Especialidade, Integer> {
    List<Especialidade> findByAtivoTrue();
}

