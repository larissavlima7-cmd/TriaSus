import { Component, inject } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { ApiService } from '../../core/services/api.service';

@Component({
  standalone: true,
  imports: [FormsModule],
  template: `
    <div class="page-heading"><div><span class="eyebrow">ATENDIMENTO ASSISTIDO · RF07</span><h1>Pré-triagem assistida</h1><p>Cadastre a solicitação junto ao cidadão, com orientação da equipe da UBS.</p></div><span class="accessibility-tag">Fonte ampliada · Alto contraste</span></div>
    <div class="steps"><div class="step active"><span>1</span><b>Paciente</b></div><i></i><div class="step" [class.active]="step >= 2"><span>2</span><b>Solicitação</b></div><i></i><div class="step" [class.active]="step >= 3"><span>3</span><b>Documentos</b></div></div>
    @if (notice) { <div class="alert alert-info">{{ notice }}</div> }
    @if (error) { <div class="alert alert-error">{{ error }}</div> }
    <section class="panel assisted-panel">
      @if (step === 1) {
        <div class="panel-heading"><div><h2>Identificação do cidadão</h2><p>Localize um cadastro existente ou preencha os dados para novo paciente.</p></div></div>
        <label>Buscar por CPF, CNS ou nome<input [(ngModel)]="searchTerm" placeholder="Digite os dados do cidadão" (keyup.enter)="search()"></label>
        <button class="btn btn-outline" (click)="search()" [disabled]="searching">{{ searching ? 'Buscando...' : '⌕ Buscar paciente' }}</button>
        @if (foundMessage) { <p class="muted">{{ foundMessage }}</p> }
        <div class="form-divider"></div>
        <div class="assisted-fields">
          <label>Nome completo<input [(ngModel)]="patient.nome" placeholder="Nome completo do paciente" required></label>
          <label>CPF ou CNS<input [(ngModel)]="patient.documento" placeholder="Documento do cidadão"></label>
          <label>Data de nascimento<input type="date" [(ngModel)]="patient.nascimento"></label>
          <label>Telefone / WhatsApp<input [(ngModel)]="patient.telefone" placeholder="(19) 99999-9999"></label>
        </div>
        <label class="check-line"><input type="checkbox" [(ngModel)]="patient.contatoValidado"> Confirmei com o cidadão que este telefone/WhatsApp está ativo.</label>
        <div class="step-actions"><span></span><button class="btn btn-primary" (click)="next()" [disabled]="!patient.nome.trim() || !patient.documento.trim() || !patient.nascimento || !patient.telefone.trim() || !patient.contatoValidado">Continuar →</button></div>
      } @else if (step === 2) {
        <div class="panel-heading"><div><h2>Dados da solicitação</h2><p>Registre a especialidade e a queixa relatada pelo cidadão.</p></div></div>
        <label>Especialidade<select [(ngModel)]="request.especialidade"><option value="">Selecione a especialidade</option><option>Ortopedia</option><option>Gastroenterologia</option><option>Dermatologia</option><option>Urologia</option><option>Neurologia</option><option>Endocrinologia</option><option>Cardiologia</option><option>Oftalmologia</option><option>Outra</option></select></label>
        <label>Queixa principal<textarea [(ngModel)]="request.queixa" rows="4" placeholder="Descreva, com as palavras do cidadão, o motivo do encaminhamento."></textarea></label>
        <label>Tempo de evolução dos sintomas<input [(ngModel)]="request.tempo" placeholder="Ex.: há aproximadamente 2 meses"></label>
        <div class="alert alert-info">Este formulário organiza informações relatadas. Não realiza diagnóstico nem classificação de risco.</div>
        <div class="step-actions"><button class="btn btn-outline" (click)="step = 1">← Voltar</button><button class="btn btn-primary" (click)="next()" [disabled]="!request.especialidade || request.queixa.trim().length < 5">Continuar →</button></div>
      } @else {
        <div class="panel-heading"><div><h2>Documentos do encaminhamento</h2><p>Anexe os documentos indicados no protocolo da especialidade.</p></div></div>
        <div class="upload-box"><div class="upload-symbol">⇧</div><b>Adicionar documentos</b><p>Selecione arquivos JPG, PNG ou PDF de até 5 MB cada.</p><input type="file" multiple accept=".jpg,.jpeg,.png,.pdf" (change)="onFiles($event)"></div>
        @for (file of selectedFiles; track file.name) { <div class="file-row"><span>▤</span><b>{{ file.name }}</b><small>{{ (file.size / 1024 / 1024).toFixed(2) }} MB</small></div> }
        <div class="alert alert-info">A lista de documentos obrigatórios deve ser fornecida pelo protocolo configurado no backend. Confirme os itens exigidos antes de concluir.</div>
        <div class="step-actions"><button class="btn btn-outline" (click)="step = 2">← Voltar</button><button class="btn btn-primary" (click)="submit()" [disabled]="saving || !selectedFiles.length">{{ saving ? 'Enviando...' : 'Concluir cadastro' }}</button></div>
      }
    </section>
  `
})
export class AssistedComponent {
  private readonly api = inject(ApiService);
  step = 1; searching = false; saving = false; error = ''; notice = ''; foundMessage = '';
  searchTerm = '';
  patient = { nome: '', documento: '', nascimento: '', telefone: '', contatoValidado: false };
  request = { especialidade: '', queixa: '', tempo: '' };
  selectedFiles: File[] = [];

  search(): void {
    if (!this.searchTerm.trim()) return;
    this.searching = true; this.foundMessage = '';
    this.api.buscarPaciente(this.searchTerm).subscribe({
      next: results => { this.searching = false; this.foundMessage = results.length ? 'Cadastro localizado. Confira os dados antes de continuar.' : 'Nenhum cadastro encontrado. Preencha os dados para novo cadastro.'; },
      error: () => { this.searching = false; this.foundMessage = 'A busca não está disponível no backend. Você pode preencher os dados manualmente.'; }
    });
  }
  next(): void { this.error = ''; this.step = Math.min(3, this.step + 1); }
  onFiles(event: Event): void {
    const input = event.target as HTMLInputElement;
    const files = Array.from(input.files ?? []);
    const invalid = files.find(f => f.size > 5 * 1024 * 1024 || !['image/jpeg','image/png','application/pdf'].includes(f.type));
    if (invalid) { this.error = 'Arquivo inválido. Use JPG, PNG ou PDF com até 5 MB.'; return; }
    this.error = ''; this.selectedFiles = [...this.selectedFiles, ...files];
  }
  submit(): void {
    const body = new FormData();
    body.append('paciente', new Blob([JSON.stringify(this.patient)], { type: 'application/json' }));
    body.append('solicitacao', new Blob([JSON.stringify(this.request)], { type: 'application/json' }));
    this.selectedFiles.forEach(file => body.append('documentos', file));
    this.saving = true; this.error = '';
    this.api.criarPreTriagem(body).subscribe({
      next: () => { this.saving = false; this.notice = 'Pré-triagem enviada para conferência da UBS.'; this.step = 1; this.patient = { nome: '', documento: '', nascimento: '', telefone: '', contatoValidado: false }; this.request = { especialidade: '', queixa: '', tempo: '' }; this.selectedFiles = []; },
      error: () => { this.saving = false; this.error = 'Não foi possível concluir. Verifique o endpoint POST /api/ubs/pre-triagem-assistida e o formato esperado pelo backend.'; }
    });
  }
}
