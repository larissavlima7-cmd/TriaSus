import { Injectable, inject } from '@angular/core';
import { HttpClient, HttpParams } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '../../../environments/environment';
import { DashboardData, Solicitacao } from '../models';

@Injectable({ providedIn: 'root' })
export class ApiService {
  private readonly http = inject(HttpClient);
  private readonly base = environment.apiUrl;

  dashboard(): Observable<DashboardData> {
    return this.http.get<DashboardData>(`${this.base}/ubs/dashboard`);
  }

  listarSolicitacoes(filtros: { especialidade?: string; status?: string; prioridade?: string; page?: number; size?: number }): Observable<Solicitacao[] | { content: Solicitacao[] }> {
    let params = new HttpParams();
    Object.entries(filtros).forEach(([key, value]) => {
      if (value !== undefined && value !== '') params = params.set(key, String(value));
    });
    return this.http.get<Solicitacao[] | { content: Solicitacao[] }>(`${this.base}/ubs/solicitacoes`, { params });
  }

  solicitacao(id: string): Observable<Solicitacao> {
    return this.http.get<Solicitacao>(`${this.base}/ubs/solicitacoes/${id}`);
  }

  documento(id: string): Observable<Blob> {
    return this.http.get(`${this.base}/ubs/documentos/${id}/arquivo`, { responseType: 'blob' });
  }

  validar(id: string, payload: { prioridadeOficial: string; sinaisVitais: Record<string, string> }): Observable<unknown> {
    return this.http.post(`${this.base}/ubs/solicitacoes/${id}/validar`, payload);
  }

  devolver(id: string, payload: { documentoId: string; motivo: string }): Observable<unknown> {
    return this.http.post(`${this.base}/ubs/solicitacoes/${id}/devolver`, payload);
  }

  exportar(): Observable<Blob> {
    return this.http.get(`${this.base}/ubs/solicitacoes/exportar`, { responseType: 'blob' });
  }

  criarPreTriagem(payload: FormData): Observable<unknown> {
    return this.http.post(`${this.base}/ubs/pre-triagem-assistida`, payload);
  }

  buscarPaciente(termo: string): Observable<unknown[]> {
    const params = new HttpParams().set('termo', termo);
    return this.http.get<unknown[]>(`${this.base}/ubs/pacientes`, { params });
  }
}
