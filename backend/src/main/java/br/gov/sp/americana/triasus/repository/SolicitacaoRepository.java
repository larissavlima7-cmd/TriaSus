package br.gov.sp.americana.triasus.repository;

import br.gov.sp.americana.triasus.model.PrioridadeOficial;
import br.gov.sp.americana.triasus.model.Solicitacao;
import br.gov.sp.americana.triasus.model.SolicitacaoStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import java.util.List;

public interface SolicitacaoRepository extends JpaRepository<Solicitacao, Integer> {
    @Query("select s from Solicitacao s where s.unidade.id = :unidadeId and s.status = :status and s.especialidade.id = :especialidadeId and s.prioridadeOficial = :prioridadeOficial")
    List<Solicitacao> buscarFilaUbs(@Param("unidadeId") Integer unidadeId, @Param("status") SolicitacaoStatus status,
                                    @Param("especialidadeId") Integer especialidadeId,
                                    @Param("prioridadeOficial") PrioridadeOficial prioridadeOficial);
}
