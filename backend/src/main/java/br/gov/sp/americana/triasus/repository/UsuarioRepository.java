package br.gov.sp.americana.triasus.repository;
import br.gov.sp.americana.triasus.model.Usuario;
import org.springframework.data.jpa.repository.JpaRepository;
public interface UsuarioRepository extends JpaRepository<Usuario, Integer> { }
