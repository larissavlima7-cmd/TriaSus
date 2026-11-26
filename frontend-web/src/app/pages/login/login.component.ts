import { Component, inject } from '@angular/core';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { ActivatedRoute, Router } from '@angular/router';
import { AuthService } from '../../core/services/auth.service';

@Component({
  standalone: true,
  imports: [ReactiveFormsModule],
  template: `
    <main class="login-page">
      <section class="login-aside">
        <div class="login-brand"><span class="brand-mark">T</span><div><b>TRIA SUS</b><small>Americana · Saúde</small></div></div>
        <div class="login-message">
          <span class="eyebrow light">CUIDADO QUE CONECTA</span>
          <h1>Mais organização.<br>Mais cuidado.</h1>
          <p>Uma rede de informação que apoia as equipes das Unidades Básicas de Saúde na qualificação dos encaminhamentos.</p>
          <div class="login-feature"><span>✓</span> Conferência documental estruturada</div>
          <div class="login-feature"><span>✓</span> Acompanhamento das solicitações</div>
          <div class="login-feature"><span>✓</span> Apoio à organização da regulação</div>
        </div>
        <small class="aside-foot">Secretaria Municipal de Saúde · Americana/SP</small>
      </section>
      <section class="login-main">
        <div class="login-card">
          <div class="login-symbol">✚</div>
          <span class="eyebrow">ÁREA DO PROFISSIONAL</span>
          <h2>Acesse sua conta</h2>
          <p class="muted">Entre com suas credenciais institucionais para continuar.</p>
          @if (expired) { <div class="alert alert-info">Sua sessão expirou. Entre novamente para continuar.</div> }
          @if (error) { <div class="alert alert-error">{{ error }}</div> }
          <form [formGroup]="form" (ngSubmit)="submit()">
            <label for="email">E-mail</label>
            <input id="email" type="email" formControlName="email" placeholder="nome@americana.sp.gov.br" autocomplete="username">
            @if (form.controls.email.touched && form.controls.email.invalid) { <small class="field-error">Informe um e-mail válido.</small> }
            <label for="senha">Senha</label>
            <input id="senha" type="password" formControlName="senha" placeholder="Digite sua senha" autocomplete="current-password">
            <button class="btn btn-primary login-submit" type="submit" [disabled]="form.invalid || loading">{{ loading ? 'Entrando...' : 'Entrar no sistema' }} <span>→</span></button>
          </form>
          <div class="login-security">▣ Seus dados são protegidos e o acesso é registrado.</div>
        </div>
        <div class="login-copyright">TRIA SUS · Americana</div>
      </section>
    </main>
  `
})
export class LoginComponent {
  private readonly fb = inject(FormBuilder);
  private readonly auth = inject(AuthService);
  private readonly router = inject(Router);
  private readonly route = inject(ActivatedRoute);
  readonly expired = this.route.snapshot.queryParamMap.get('expired') === '1';
  readonly form = this.fb.nonNullable.group({
    email: ['', [Validators.required, Validators.email]],
    senha: ['', [Validators.required, Validators.minLength(1)]]
  });
  loading = false;
  error = '';

  submit(): void {
    if (this.form.invalid || this.loading) return;
    this.loading = true;
    this.error = '';
    this.auth.login(this.form.getRawValue()).subscribe({
      next: () => {
        const returnUrl = this.route.snapshot.queryParamMap.get('returnUrl') || '/dashboard';
        void this.router.navigateByUrl(returnUrl);
      },
      error: err => {
        this.loading = false;
        this.error = err.status === 401
          ? 'E-mail ou senha incorretos. Confira seus dados e tente novamente.'
          : err.status === 0
            ? 'Não foi possível conectar ao servidor. Verifique se o backend está rodando em localhost:8080.'
            : 'Não foi possível realizar o acesso. Tente novamente ou contate o suporte.';
      }
    });
  }
}
