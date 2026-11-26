package br.gov.sp.americana.triasus.repository;

import br.gov.sp.americana.triasus.model.SinalVital;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;

public interface SinalVitalRepository extends JpaRepository<SinalVital, Integer> {
    List<SinalVital> findBySolicitacaoIdOrderByAferidoEmDesc(Integer solicitacaoId);
}

