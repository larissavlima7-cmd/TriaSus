import { Injectable, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Router } from '@angular/router';
import { Observable, tap } from 'rxjs';
import { environment } from '../../../environments/environment';
import { AuthUser, LoginResponse, UserRole } from '../models';

@Injectable({ providedIn: 'root' })
export class AuthService {
  private readonly http = inject(HttpClient);
  private readonly router = inject(Router);
  private readonly tokenKey = 'tria_sus_token';
  private readonly userKey = 'tria_sus_user';

  login(credentials: { email: string; senha: string }): Observable<LoginResponse> {
    return this.http.post<LoginResponse>(`${environment.apiUrl}/auth/profissional`, {
      login: credentials.email.trim(),
      senha: credentials.senha
    }).pipe(
      tap(response => {
        const token = response.token ?? response.accessToken ?? response.jwt;
        if (!token) throw new Error('A resposta do servidor não contém um token JWT.');
        const user: AuthUser = response.usuario ?? response.user ?? {
          nome: response.nome ?? credentials.email,
          perfil: response.perfil ?? response.papeis?.[0] ?? 'PROFISSIONAL_SAUDE',
          unidadeUbs: response.unidadeUbs
        };
        localStorage.setItem(this.tokenKey, token);
        localStorage.setItem(this.userKey, JSON.stringify(user));
      })
    );
  }

  get token(): string | null { return localStorage.getItem(this.tokenKey); }
  get isAuthenticated(): boolean { return !!this.token; }

  get user(): AuthUser | null {
    const raw = localStorage.getItem(this.userKey);
    if (!raw) return null;
    try { return JSON.parse(raw) as AuthUser; } catch { return null; }
  }

  hasRole(roles: UserRole[]): boolean {
    const role = this.user?.perfil?.toUpperCase();
    return !!role && roles.includes(role as UserRole);
  }

  logout(): void {
    localStorage.removeItem(this.tokenKey);
    localStorage.removeItem(this.userKey);
    void this.router.navigate(['/login']);
  }

  clearSession(): void {
    localStorage.removeItem(this.tokenKey);
    localStorage.removeItem(this.userKey);
  }
}
