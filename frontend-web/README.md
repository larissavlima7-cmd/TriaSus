# TRIA SUS Americana — Painel Web

Frontend Angular para apoiar a pré-triagem, a conferência documental e a organização de encaminhamentos das UBSs de Americana.

## Requisitos

- Node.js 20.19+, 22.12+ ou 24+
- npm
- Backend Spring Boot iniciado em `http://localhost:8080`
- `JWT_SECRET` configurado no terminal do backend

## Executar no VS Code (Windows / PowerShell)

1. Extraia o ZIP.
2. No VS Code, abra a pasta `frontend-web`.
3. Abra **Terminal > Novo Terminal**.
4. Execute:

```powershell
npm install
npm start
```

5. Acesse `http://localhost:4200`.

Para gerar a versão de produção:

```powershell
npm run build
```

## Integração com o backend

A URL-base está em `src/environments/environment.ts`:

```ts
apiUrl: 'http://localhost:8080/api'
```

O interceptor envia `Authorization: Bearer <token>` automaticamente. O login está configurado para `POST /api/auth/profissional` e o dashboard para `GET /api/ubs/dashboard`.

As rotas de fila, detalhes, documentos, validação, devolução e exportação estão centralizadas em `src/app/core/services/api.service.ts`. Como a documentação fornecida não especifica todos os contratos HTTP desses endpoints, os caminhos e formatos estão isolados nesse serviço para facilitar o ajuste conforme o backend real.

## Perfis

- `PROFISSIONAL_SAUDE`: acesso à conferência e ao registro de informações do acolhimento.
- `RECEPCAO_ACS`: acesso à pré-triagem assistida.
- `ADMIN` e `GESTOR`: acesso administrativo.

O backend deve validar as permissões. O guard do frontend melhora a navegação, mas não substitui a autorização no servidor.

## Observações importantes

- A interface não realiza diagnóstico nem define prioridade clínica automaticamente.
- A prioridade oficial é selecionada por profissional autorizado.
- Sinais vitais desta tela são identificados como dados aferidos presencialmente na UBS.
- O protótipo visual foi construído a partir da descrição textual fornecida. Nenhuma imagem de protótipo foi anexada nesta conversa.
- A integração real depende de os endpoints do backend seguirem os caminhos e contratos indicados no serviço de API.
