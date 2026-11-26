import { Component, inject, OnDestroy, OnInit } from '@angular/core';
import { ActivatedRoute } from '@angular/router';
import { FormsModule } from '@angular/forms';
import { ApiService } from '../../core/services/api.service';
import { Solicitacao } from '../../core/models';

@Component({
  standalone: true,
  imports: [FormsModule],
  template: `
    <div class="page-heading"><div><span class="eyebrow">ANÁLISE DA UNIDADE</span><h1>Conferência documental</h1><p>Revise os dados e os documentos antes de liberar a solicitação.</p></div><span class="record-tag">Solicitação #{{ id }}</span></div>
    @if (loading) { <div class="loading-panel">Carregando solicitação...</div> }
    @if (error) { <div class="alert alert-error">{{ error }}</div> }
    @if (item) {
      <div class="review-grid">
        <div class="review-main">
          <section class="panel">
            <div class="panel-heading"><div><h2>Dados do paciente</h2><p>Informações vinculadas ao encaminhamento</p></div></div>
            <div class="patient-summary"><div class="patient-avatar">{{ item.paciente.charAt(0) }}</div><div><h3>{{ item.paciente }}</h3><span>{{ item.cpf || 'CPF não informado' }}</span></div></div>
            <div class="detail-grid"><div><small>Especialidade</small><b>{{ item.especialidade }}</b></div><div><small>Telefone / WhatsApp</small><b>{{ item.telefone || 'Não informado' }}</b></div><div><small>Data da solicitação</small><b>{{ item.data || '—' }}</b></div><div><small>Status atual</small><b>{{ item.status }}</b></div></div>
            <div class="complaint"><small>Queixa relatada</small><p>{{ item.queixa || 'Não informada pela API.' }}</p></div>
          </section>
          <section class="panel">
            <div class="panel-heading"><div><h2>Sinais vitais do acolhimento</h2><p>Preenchimento pela equipe durante aferição presencial na UBS</p></div><span class="status-pill status-review">Acolhimento UBS</span></div>
            <div class="alert alert-info">Registre somente valores aferidos presencialmente. Não misture estes dados com medições domiciliares autorrelatadas.</div>
            <div class="vitals-grid">
              <label>Pressão arterial<input [(ngModel)]="vitals.pa" placeholder="Ex.: 120x80 mmHg"></label>
              <label>Temperatura<input [(ngModel)]="vitals.temperatura" placeholder="Ex.: 36,5 °C"></label>
              <label>Glicemia capilar<input [(ngModel)]="vitals.glicemia" placeholder="Ex.: 98 mg/dL"></label>
              <label>Saturação<input [(ngModel)]="vitals.saturacao" placeholder="Ex.: 98%"></label>
            </div>
          </section>
          <section class="panel">
            <div class="panel-heading"><div><h2>Checklist de documentos</h2><p>Visualize os anexos recebidos e confira a legibilidade.</p></div></div>
            @if ((item.documentos ?? []).length) {
              @for (doc of item.documentos ?? []; track doc.id) {
                <div class="document-row"><span class="document-icon">▤</span><div class="document-info"><b>{{ doc.nome }}</b><small>{{ doc.status || 'Aguardando conferência' }}</small></div><button class="btn btn-small btn-outline" (click)="preview(doc.id)">Visualizar</button></div>
              }
            } @else { <div class="empty-state">A API não retornou documentos para esta solicitação.</div> }
            @if (previewUrl) { <div class="preview-box"><div class="preview-head"><b>Pré-visualização do documento</b><button class="text-button" (click)="closePreview()">Fechar</button></div><iframe [src]="safePreviewUrl" title="Pré-visualização do documento"></iframe></div> }
          </section>
        </div>
        <aside class="review-side">
          <section class="panel">
            <h2>Prioridade clínica oficial</h2><p class="muted">Definida exclusivamente pelo profissional responsável.</p>
            <label>Classificação<select [(ngModel)]="prioridade"><option value="">Selecione</option><option value="BAIXA">Baixa</option><option value="MODERADA">Moderada</option><option value="ALTA">Alta</option><option value="URGENTE">Urgente</option></select></label>
            <div class="side-note">A plataforma não calcula nem sugere prioridade clínica automaticamente.</div>
            <button class="btn btn-primary full-button" (click)="confirmarValidacao()" [disabled]="saving || !prioridade">{{ saving ? 'Salvando...' : '✓ Validar e liberar' }}</button>
            <button class="btn btn-danger-outline full-button" (click)="showReturn = true">Devolver por pendência</button>
          </section>
        </aside>
      </div>
    }
    @if (showReturn) {
      <div class="modal-backdrop" role="presentation"><section class="modal" role="dialog" aria-modal="true" aria-labelledby="return-title">
        <button class="modal-close" (click)="showReturn = false" aria-label="Fechar">×</button><span class="eyebrow">DEVOLUÇÃO ORIENTADA</span><h2 id="return-title">Informar pendência</h2><p class="muted">Selecione o documento que precisa ser corrigido e descreva o motivo.</p>
        <label>Documento<select [(ngModel)]="returnDoc"><option value="">Selecione o item</option>@for (doc of item?.documentos ?? []; track doc.id) { <option [value]="doc.id">{{ doc.nome }}</option> }</select></label>
        <label>Motivo da devolução<textarea [(ngModel)]="returnReason" rows="4" placeholder="Ex.: imagem ilegível; enviar novamente com boa iluminação."></textarea></label>
        <div class="modal-actions"><button class="btn btn-outline" (click)="showReturn = false">Cancelar</button><button class="btn btn-danger" (click)="confirmarDevolucao()" [disabled]="saving || !returnDoc || returnReason.trim().length < 5">Confirmar devolução</button></div>
      </section></div>
    }
    @if (notice) { <div class="toast">{{ notice }}</div> }
  `
})
export class ReviewComponent implements OnInit, OnDestroy {
  private readonly route = inject(ActivatedRoute);
  private readonly api = inject(ApiService);
  id = ''; item: Solicitacao | null = null; loading = true; saving = false; error = ''; notice = '';
  prioridade = ''; showReturn = false; returnDoc = ''; returnReason = '';
  vitals = { pa: '', temperatura: '', glicemia: '', saturacao: '' };
  previewUrl = ''; safePreviewUrl = '';
  ngOnInit(): void {
    this.id = this.route.snapshot.paramMap.get('id') ?? '';
    this.api.solicitacao(this.id).subscribe({
      next: value => { this.item = value; this.prioridade = value.prioridade ?? ''; this.loading = false; },
      error: () => { this.error = 'Não foi possível carregar os dados. Verifique GET /api/ubs/solicitacoes/{id}.'; this.loading = false; }
    });
  }
  preview(docId: string | number): void {
    this.api.documento(String(docId)).subscribe({
      next: blob => { this.closePreview(); this.previewUrl = URL.createObjectURL(blob); this.safePreviewUrl = this.previewUrl; },
      error: () => this.notice = 'Não foi possível abrir o documento. Verifique sua permissão e o endpoint autenticado.'
    });
  }
  closePreview(): void { if (this.previewUrl) URL.revokeObjectURL(this.previewUrl); this.previewUrl = ''; this.safePreviewUrl = ''; }
  confirmarValidacao(): void {
    if (!confirm('Confirma a validação documental e a liberação desta solicitação para a regulação?')) return;
    this.saving = true;
    this.api.validar(this.id, { prioridadeOficial: this.prioridade, sinaisVitais: this.vitals }).subscribe({
      next: () => { this.saving = false; this.notice = 'Solicitação validada e liberada.'; },
      error: () => { this.saving = false; this.notice = 'Não foi possível validar. Confira o endpoint e os dados exigidos pelo backend.'; }
    });
  }
  confirmarDevolucao(): void {
    if (!confirm('Confirma a devolução desta solicitação por pendência documental?')) return;
    this.saving = true;
    this.api.devolver(this.id, { documentoId: this.returnDoc, motivo: this.returnReason }).subscribe({
      next: () => { this.saving = false; this.showReturn = false; this.notice = 'Solicitação devolvida para correção.'; },
      error: () => { this.saving = false; this.notice = 'Não foi possível registrar a pendência. Confira o endpoint do backend.'; }
    });
  }
  ngOnDestroy(): void { this.closePreview(); }
}
