import { Routes } from '@angular/router';
import { authGuard, roleGuard } from './core/guards/auth.guard';
import { LoginComponent } from './pages/login/login.component';
import { DashboardComponent } from './pages/dashboard/dashboard.component';
import { QueueComponent } from './pages/queue/queue.component';
import { ReviewComponent } from './pages/review/review.component';
import { AssistedComponent } from './pages/assisted/assisted.component';

export const routes: Routes = [
  { path: 'login', component: LoginComponent },
  { path: 'dashboard', component: DashboardComponent, canActivate: [authGuard] },
  { path: 'fila', component: QueueComponent, canActivate: [authGuard] },
  { path: 'conferencia/:id', component: ReviewComponent, canActivate: [authGuard, roleGuard], data: { roles: ['PROFISSIONAL_SAUDE', 'ADMIN', 'GESTOR'] } },
  { path: 'pre-triagem-assistida', component: AssistedComponent, canActivate: [authGuard, roleGuard], data: { roles: ['RECEPCAO_ACS', 'PROFISSIONAL_SAUDE', 'ADMIN', 'GESTOR'] } },
  { path: '', pathMatch: 'full', redirectTo: 'dashboard' },
  { path: '**', redirectTo: 'dashboard' }
];
