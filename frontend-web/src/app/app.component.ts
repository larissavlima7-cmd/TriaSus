import { Component, inject } from '@angular/core';
import { Router, RouterLink, RouterLinkActive, RouterOutlet } from '@angular/router';
import { NgClass } from '@angular/common';
import { AuthService } from './core/services/auth.service';

@Component({
  selector: 'tria-root',
  standalone: true,
  imports: [RouterOutlet, RouterLink, RouterLinkActive, NgClass],
  template: `
    @if (auth.isAuthenticated) {
      <div class="app-shell">
        <aside class="sidebar">
          <a class="brand" routerLink="/dashboard" aria-label="TRIA SUS início">
            <span class="brand-mark">T</span>
            <span><strong>TRIA SUS</strong><small>Americana · Saúde</small></span>
          </a>
          <div class="unit-label">UNIDADE DE SAÚDE</div>
          <div class="unit-name">{{ auth.user?.unidadeUbs || 'UBS de Americana' }}</div>
          <nav class="main-nav" aria-label="Menu principal">
            <a routerLink="/dashboard" routerLinkActive="active"><span class="nav-icon">▦</span> Visão Geral</a>
            <a routerLink="/fila" routerLinkActive="active"><span class="nav-icon">☷</span> Fila</a>
            @if (auth.hasRole(['PROFISSIONAL_SAUDE','ADMIN','GESTOR'])) {
              <a routerLink="/fila" [queryParams]="{view:'documentos'}"><span class="nav-icon">▤</span> Conferência Documental</a>
            }
            @if (auth.hasRole(['RECEPCAO_ACS','PROFISSIONAL_SAUDE','ADMIN','GESTOR'])) {
              <a routerLink="/pre-triagem-assistida" routerLinkActive="active"><span class="nav-icon">＋</span> Pré-triagem assistida</a>
            }
          </nav>
          <div class="sidebar-bottom">
            <div class="privacy-note"><span>●</span><div><b>Ambiente protegido</b><small>Acesso restrito a profissionais</small></div></div>
            <button class="logout-button" (click)="logout()">↪ Sair do sistema</button>
          </div>
        </aside>
        <main class="main-area">
          <header class="topbar">
            <div class="mobile-brand">TRIA SUS <span>Americana</span></div>
            <div class="topbar-spacer"></div>
            <div class="top-user">
              <div class="avatar">{{ initials }}</div>
              <div class="user-info"><strong>{{ auth.user?.nome || 'Profissional' }}</strong><small>{{ auth.user?.perfil || 'Equipe UBS' }}</small></div>
            </div>
          </header>
          <section class="page-area"><router-outlet /></section>
          <footer class="footer">TRIA SUS · Plataforma de apoio à pré-triagem e qualificação documental <span>Não substitui os sistemas oficiais de regulação.</span></footer>
        </main>
      </div>
    } @else {
      <router-outlet />
    }
  `
})
export class AppComponent {
  readonly auth = inject(AuthService);
  private readonly router = inject(Router);
  get initials(): string {
    return (this.auth.user?.nome ?? 'PS').split(' ').slice(0, 2).map(p => p[0]).join('').toUpperCase();
  }
  logout(): void { this.auth.logout(); }
}
