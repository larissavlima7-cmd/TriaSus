package br.gov.sp.americana.triasus.repository;

import br.gov.sp.americana.triasus.model.ChecklistProtocolo;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;

public interface ChecklistProtocoloRepository extends JpaRepository<ChecklistProtocolo, Integer> {
    List<ChecklistProtocolo> findByEspecialidadeId(Integer especialidadeId);
}

