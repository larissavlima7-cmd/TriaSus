import { Component, inject, OnInit } from '@angular/core';
import { RouterLink } from '@angular/router';
import { ApiService } from '../../core/services/api.service';
import { DashboardData } from '../../core/models';

@Component({
  standalone: true,
  imports: [RouterLink],
  template: `
    <div class="page-heading">
      <div><span class="eyebrow">PAINEL DA UNIDADE</span><h1>Visão geral</h1><p>Acompanhe as solicitações e a organização dos encaminhamentos da UBS.</p></div>
      <a class="btn btn-primary" routerLink="/pre-triagem-assistida">＋ Pré-triagem assistida</a>
    </div>
    @if (loading) { <div class="loading-panel">Carregando indicadores da unidade...</div> }
    @if (error) { <div class="alert alert-error">{{ error }} <button class="text-button" (click)="load()">Tentar novamente</button></div> }
    @if (data) {
      <div class="metric-grid">
        <article class="metric-card"><div class="metric-top"><span>Total de solicitações</span><span class="metric-icon green">▦</span></div><strong>{{ data.totalSolicitacoes ?? 0 }}</strong><small>Registros acompanhados</small></article>
        <article class="metric-card"><div class="metric-top"><span>Em conferência</span><span class="metric-icon blue">◷</span></div><strong>{{ data.emConferencia ?? 0 }}</strong><small>Aguardando análise da UBS</small></article>
        <article class="metric-card"><div class="metric-top"><span>Pendências documentais</span><span class="metric-icon orange">!</span></div><strong>{{ data.pendencias ?? 0 }}</strong><small>Precisam de complementação</small></article>
        <article class="metric-card"><div class="metric-top"><span>Aptas para regulação</span><span class="metric-icon teal">✓</span></div><strong>{{ data.aptasRegulacao ?? 0 }}</strong><small>Conferência concluída</small></article>
      </div>
      <div class="dashboard-grid">
        <section class="panel">
          <div class="panel-heading"><div><h2>Encaminhamentos por especialidade</h2><p>Distribuição das solicitações registradas</p></div><span class="panel-icon">▥</span></div>
          @if ((data.encaminhamentosPorEspecialidade ?? []).length) {
            <div class="chart-list">
              @for (item of data.encaminhamentosPorEspecialidade ?? []; track item.especialidade) {
                <div class="chart-row"><div><span>{{ item.especialidade }}</span><b>{{ item.quantidade }}</b></div><div class="bar-track"><div class="bar-fill" [style.width.%]="barWidth(item.quantidade)"></div></div></div>
              }
            </div>
          } @else { <div class="empty-state">Ainda não há dados de encaminhamentos por especialidade.</div> }
        </section>
        <section class="panel">
          <div class="panel-heading"><div><h2>Solicitações recentes</h2><p>Últimas movimentações da unidade</p></div><a routerLink="/fila" class="link">Ver fila →</a></div>
          @if ((data.recentes ?? []).length) {
            <div class="recent-list">
              @for (item of data.recentes ?? []; track item.id) {
                <a class="recent-item" [routerLink]="['/conferencia', item.id]"><span class="recent-avatar">{{ item.paciente.charAt(0) }}</span><span class="recent-info"><b>{{ item.paciente }}</b><small>{{ item.especialidade }} · {{ item.data || 'Data não informada' }}</small></span><span class="status-pill" [class]="statusClass(item.status)">{{ item.status }}</span></a>
              }
            </div>
          } @else { <div class="empty-state">Nenhuma solicitação recente retornada pela API.</div> }
        </section>
      </div>
      <section class="panel alerts-panel">
        <div class="panel-heading"><div><h2>Alertas e atenção</h2><p>Informações para acompanhamento da equipe</p></div></div>
        @if ((data.alertas ?? []).length) {
          @for (alerta of data.alertas ?? []; track alerta.titulo) { <div class="alert-row"><span class="alert-dot">!</span><div><b>{{ alerta.titulo }}</b><p>{{ alerta.descricao }}</p></div></div> }
        } @else { <div class="empty-state">Não há alertas no momento.</div> }
      </section>
    }
    <div class="disclaimer">O TRIA SUS apoia a qualificação das solicitações. A definição de prioridade clínica permanece sob responsabilidade do profissional habilitado.</div>
  `
})
export class DashboardComponent implements OnInit {
  private readonly api = inject(ApiService);
  data: DashboardData | null = null;
  loading = true;
  error = '';
  ngOnInit(): void { this.load(); }
  load(): void {
    this.loading = true; this.error = '';
    this.api.dashboard().subscribe({
      next: value => { this.data = value; this.loading = false; },
      error: () => { this.error = 'Não foi possível carregar o dashboard. Confirme a conexão com o backend e o contrato de GET /api/ubs/dashboard.'; this.loading = false; }
    });
  }
  barWidth(value: number): number {
    const max = Math.max(...(this.data?.encaminhamentosPorEspecialidade ?? []).map(x => x.quantidade), 1);
    return Math.max(4, value / max * 100);
  }
  statusClass(status: string): string {
    const s = status.toLowerCase();
    if (s.includes('pend')) return 'status-pending';
    if (s.includes('apto')) return 'status-done';
    return 'status-review';
  }
}
