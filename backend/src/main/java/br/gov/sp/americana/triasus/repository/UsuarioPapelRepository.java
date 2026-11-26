package br.gov.sp.americana.triasus.repository;

import br.gov.sp.americana.triasus.model.UsuarioPapel;
import br.gov.sp.americana.triasus.model.UsuarioPapelId;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;

public interface UsuarioPapelRepository extends JpaRepository<UsuarioPapel, UsuarioPapelId> {
    List<UsuarioPapel> findByUsuarioId(Integer usuarioId);
}

