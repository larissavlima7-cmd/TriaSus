package br.gov.sp.americana.triasus.repository;
import br.gov.sp.americana.triasus.model.Paciente;
import org.springframework.data.jpa.repository.JpaRepository;
public interface PacienteRepository extends JpaRepository<Paciente, Integer> { }
