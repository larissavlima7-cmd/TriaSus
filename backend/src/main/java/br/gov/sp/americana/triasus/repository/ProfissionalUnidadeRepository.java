package br.gov.sp.americana.triasus.repository;

import br.gov.sp.americana.triasus.model.ProfissionalUnidade;
import br.gov.sp.americana.triasus.model.ProfissionalUnidadeId;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;

public interface ProfissionalUnidadeRepository extends JpaRepository<ProfissionalUnidade, ProfissionalUnidadeId> {
    List<ProfissionalUnidade> findByProfissionalId(Integer profissionalId);
}

