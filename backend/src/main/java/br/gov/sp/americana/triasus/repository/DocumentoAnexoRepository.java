package br.gov.sp.americana.triasus.repository;

import br.gov.sp.americana.triasus.model.DocumentoAnexo;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;
import java.util.Optional;

public interface DocumentoAnexoRepository extends JpaRepository<DocumentoAnexo, Integer> {
    List<DocumentoAnexo> findBySolicitacaoId(Integer solicitacaoId);
    Optional<DocumentoAnexo> findBySolicitacaoIdAndItemChecklistId(Integer solicitacaoId, Integer itemChecklistId);
}

