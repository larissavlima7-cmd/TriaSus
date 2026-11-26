package br.gov.sp.americana.triasus.controller;

import br.gov.sp.americana.triasus.dto.ChecklistItemDTO;
import br.gov.sp.americana.triasus.dto.EspecialidadeDTO;
import br.gov.sp.americana.triasus.repository.ChecklistProtocoloRepository;
import br.gov.sp.americana.triasus.repository.EspecialidadeRepository;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/especialidades")
public class EspecialidadeController {

    private final EspecialidadeRepository especialidadeRepository;
    private final ChecklistProtocoloRepository checklistProtocoloRepository;

    public EspecialidadeController(EspecialidadeRepository especialidadeRepository, ChecklistProtocoloRepository checklistProtocoloRepository) {
        this.especialidadeRepository = especialidadeRepository;
        this.checklistProtocoloRepository = checklistProtocoloRepository;
    }

    @GetMapping
    public ResponseEntity<List<EspecialidadeDTO>> listarAtivas() {
        List<EspecialidadeDTO> dtos = especialidadeRepository.findByAtivoTrue().stream()
                .map(e -> new EspecialidadeDTO(e.getId(), e.getNome(), e.getDescricao(), e.getAtivo()))
                .toList();
        return ResponseEntity.ok(dtos);
    }

    @GetMapping("/{id}/checklist")
    public ResponseEntity<List<ChecklistItemDTO>> listarChecklist(@PathVariable Integer id) {
        List<ChecklistItemDTO> dtos = checklistProtocoloRepository.findByEspecialidadeId(id).stream()
                .map(c -> new ChecklistItemDTO(
                        c.getId(),
                        c.getEspecialidade().getId(),
                        c.getNomeDocumento(),
                        c.getDescricaoOrientacao(),
                        c.getObrigatorio()
                ))
                .toList();
        return ResponseEntity.ok(dtos);
    }
}
