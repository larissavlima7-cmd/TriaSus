export type UserRole = 'PROFISSIONAL_SAUDE' | 'RECEPCAO_ACS' | 'ADMIN' | 'GESTOR';

export interface AuthUser {
  id?: number | string;
  nome: string;
  email?: string;
  perfil: UserRole | string;
  unidadeUbs?: string;
}

export interface LoginResponse {
  token?: string;
  accessToken?: string;
  jwt?: string;
  usuario?: AuthUser;
  user?: AuthUser;
  perfil?: string;
  nome?: string;
  unidadeUbs?: string;
}

export interface DashboardData {
  totalSolicitacoes?: number;
  emConferencia?: number;
  pendencias?: number;
  aptasRegulacao?: number;
  recentes?: Array<{
    id: number | string;
    paciente: string;
    especialidade: string;
    status: string;
    data?: string;
  }>;
  alertas?: Array<{ titulo: string; descricao: string }>;
  encaminhamentosPorEspecialidade?: Array<{ especialidade: string; quantidade: number }>;
}

export interface Solicitacao {
  id: number | string;
  paciente: string;
  cpf?: string;
  especialidade: string;
  status: string;
  prioridade?: string;
  data?: string;
  telefone?: string;
  queixa?: string;
  documentos?: Array<{ id: number | string; nome: string; status?: string }>;
}
