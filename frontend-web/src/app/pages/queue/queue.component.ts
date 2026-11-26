import { Component, inject, OnInit } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { RouterLink } from '@angular/router';
import { ApiService } from '../../core/services/api.service';
import { Solicitacao } from '../../core/models';

@Component({
  standalone: true,
  imports: [FormsModule, RouterLink],
  template: `
    <div class="page-heading"><div><span class="eyebrow">GESTÃO DE ENCAMINHAMENTOS</span><h1>Fila de solicitações</h1><p>Consulte e acompanhe os pedidos recebidos pela unidade.</p></div><button class="btn btn-outline" (click)="exportar()" [disabled]="exporting">⇩ {{ exporting ? 'Preparando...' : 'Exportar JSON' }}</button></div>
    <section class="panel filters-panel">
      <div class="filter-heading"><b>Filtros</b><button class="text-button" (click)="limpar()">Limpar filtros</button></div>
      <div class="filters-grid">
        <label>Especialidade<select [(ngModel)]="especialidade"><option value="">Todas</option><option>Ortopedia</option><option>Dermatologia</option><option>Urologia</option><option>Gastroenterologia</option><option>Neurologia</option></select></label>
        <label>Status documental<select [(ngModel)]="status"><option value="">Todos</option><option value="EM_CONFERENCIA">Em conferência</option><option value="PENDENCIA_DOCUMENTAL">Pendência documental</option><option value="APTO_REGULACAO">Apto para regulação</option></select></label>
        <label>Prioridade oficial<select [(ngModel)]="prioridade"><option value="">Todas</option><option>Baixa</option><option>Moderada</option><option>Alta</option><option>Urgente</option></select></label>
        <button class="btn btn-primary filter-button" (click)="load()">Aplicar filtros</button>
      </div>
    </section>
    @if (message) { <div class="alert alert-info">{{ message }}</div> }
    @if (error) { <div class="alert alert-error">{{ error }}</div> }
    <section class="panel table-panel">
      <div class="panel-heading"><div><h2>Solicitações recebidas</h2><p>{{ rows.length }} registro(s) nesta página</p></div><span class="panel-icon">☷</span></div>
      @if (loading) { <div class="loading-panel">Carregando fila...</div> }
      @else if (rows.length) {
        <div class="table-scroll"><table><thead><tr><th>Paciente</th><th>Especialidade</th><th>Data</th><th>Status documental</th><th>Prioridade oficial</th><th></th></tr></thead><tbody>
          @for (row of rows; track row.id) {
            <tr><td><b>{{ row.paciente }}</b><small class="table-sub">{{ row.cpf || 'Documento não informado' }}</small></td><td>{{ row.especialidade }}</td><td>{{ row.data || '—' }}</td><td><span class="status-pill" [class]="statusClass(row.status)">{{ statusLabel(row.status) }}</span></td><td>{{ row.prioridade || 'Não definida' }}</td><td><a class="table-action" [routerLink]="['/conferencia', row.id]" aria-label="Abrir solicitação">Abrir →</a></td></tr>
          }
        </tbody></table></div>
        <div class="pagination"><span>Exibindo página {{ page + 1 }}</span><div><button class="btn btn-small btn-outline" (click)="changePage(-1)" [disabled]="page === 0">Anterior</button><button class="btn btn-small btn-outline" (click)="changePage(1)" [disabled]="rows.length < size">Próxima</button></div></div>
      } @else if (!error) { <div class="empty-state">Nenhuma solicitação encontrada com os filtros selecionados.</div> }
    </section>
  `
})
export class QueueComponent implements OnInit {
  private readonly api = inject(ApiService);
  rows: Solicitacao[] = [];
  especialidade = ''; status = ''; prioridade = '';
  page = 0; size = 10; loading = false; exporting = false; error = ''; message = '';
  ngOnInit(): void { this.load(); }
  load(): void {
    this.loading = true; this.error = ''; this.message = '';
    this.api.listarSolicitacoes({ especialidade: this.especialidade, status: this.status, prioridade: this.prioridade, page: this.page, size: this.size }).subscribe({
      next: result => { this.rows = Array.isArray(result) ? result : result.content ?? []; this.loading = false; },
      error: () => { this.error = 'Não foi possível consultar a fila. Verifique se GET /api/ubs/solicitacoes está disponível no backend.'; this.loading = false; }
    });
  }
  limpar(): void { this.especialidade = ''; this.status = ''; this.prioridade = ''; this.page = 0; this.load(); }
  changePage(delta: number): void { this.page = Math.max(0, this.page + delta); this.load(); }
  statusClass(value: string): string {
    const s = value.toLowerCase();
    return s.includes('pend') ? 'status-pending' : s.includes('apto') ? 'status-done' : 'status-review';
  }
  statusLabel(value: string): string {
    return ({ EM_CONFERENCIA: 'Em conferência', PENDENCIA_DOCUMENTAL: 'Pendência documental', APTO_REGULACAO: 'Apto para regulação' } as Record<string,string>)[value] ?? value.replaceAll('_',' ');
  }
  exportar(): void {
    this.exporting = true; this.api.exportar().subscribe({
      next: blob => {
        const url = URL.createObjectURL(blob); const a = document.createElement('a');
        a.href = url; a.download = 'tria-sus-solicitacoes.json'; a.click(); URL.revokeObjectURL(url);
        this.exporting = false; this.message = 'Arquivo JSON gerado.';
      },
      error: () => { this.exporting = false; this.error = 'Não foi possível exportar. Verifique o endpoint de exportação do backend.'; }
    });
  }
}
