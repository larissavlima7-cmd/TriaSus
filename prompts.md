# Prompts TriaSUS para o Codex

## Como usar

- Cole **um prompt por vez**, na ordem. Depois de cada um: confira, rode e faça commit.
- O Codex lê `AGENTS.md` (não `CLAUDE.md`). O Prompt 0 gera esse arquivo.
- Todo prompt começa pedindo o plano. Responda "pode seguir" ou ajuste antes de ele alterar arquivos.
- Para o protótipo web, abra o Codex com a imagem anexada: `codex -i docs\prototipo-web.png` (ou cole a imagem no terminal).
- Ambiente: Windows/PowerShell. Atenção: `curl` no PowerShell é alias de `Invoke-WebRequest`. Os prompts mandam usar `curl.exe` ou `Invoke-RestMethod`.
- Pré-requisito: PostgreSQL rodando, banco `triasus_americana` criado e `database/dump_triasus.sql` aplicado (o seed já está nele).

Depois de cada etapa:
```powershell
git add .
git commit -m "descrição curta"
git push
```

---

## Prompt 0: gerar o AGENTS.md

```
Leia README.md e database/dump_triasus.sql. Crie um AGENTS.md na raiz com:
- resumo do projeto (2-3 linhas)
- stack: Java 21 + Spring Boot 3.4 + PostgreSQL (backend), Angular standalone (frontend-web), Flutter (mobile-app)
- comandos de build/run de cada módulo (ambiente Windows/PowerShell)
- convenções: arquitetura MVC, DTOs com record, nunca expor entidade nem senha_hash, mensagens de erro em PT-BR, enums como @Enumerated(EnumType.STRING), PKs com GenerationType.IDENTITY, entidades com @Getter/@Setter (nunca @Data), relacionamentos LAZY
- regras de negócio críticas (RF01-RF08, RNF01-RNF05) em lista curta
- lista das 13 tabelas reais do dump e os valores dos enums (extraídos dos CHECK do dump)
- regras de trabalho:
  * o dump_triasus.sql é a fonte de verdade do banco; o seed já está nele, não recriar
  * não alterar o dump nem o README sem me avisar
  * nunca trocar ddl-auto=validate por update/none para "resolver" erro; corrigir a entidade
  * em testes via terminal usar curl.exe ou Invoke-RestMethod (não o alias curl)
  * processos longos (mvn spring-boot:run, ng serve) rodam em background; confirmar pelo log e encerrar ao terminar
  * ao final de cada tarefa, listar os arquivos criados/alterados e como testar
Antes de criar, me avise se README e dump estiverem inconsistentes. O AGENTS.md deve ter no máximo 80 linhas e nenhuma instrução de "implemente X".
```

---

## Backend

### Etapa 1: projeto, entidades e repositoriess

```
Antes de alterar arquivos, me mostre um plano curto e espere eu aprovar.

Leia AGENTS.md, README.md e database/dump_triasus.sql.
Crie em /backend um projeto Maven (Java 21, Spring Boot 3.4.x, pacote br.gov.sp.americana.triasus) com web, data-jpa, postgresql, validation, security, lombok e jjwt (0.12.x).
Configure application.properties:
- datasource jdbc:postgresql://localhost:5432/triasus_americana (usuário postgres, senha postgres, com comentário de onde trocar)
- ddl-auto=validate e spring.jpa.open-in-view=false
- multipart max 5MB e diretório de uploads
- CORS para http://localhost:4200
Crie TODAS as 13 entidades JPA espelhando exatamente o dump (nomes, tipos, nulabilidade, enums como STRING). usuario_papel e profissional_unidade têm PK composta (@EmbeddedId ou @IdClass). Crie os repositories, com query para a fila da UBS (unidadeId, status, especialidadeId, prioridadeOficial).
Deixe o Spring Security temporariamente com CSRF desabilitado e permitAll, só para subir. Auth fica para a próxima etapa.
Rode mvn clean compile e mvn spring-boot:run (em background). Corrija até aparecer "Started ...Application" sem erro de validate. Não avance além disso.
```

### Etapa 2: segurança e autenticação

```
Antes de alterar arquivos, me mostre um plano curto e espere eu aprovar.

Leia AGENTS.md. Implemente segurança e autenticação no /backend:
- POST /api/auth/cidadao: CPF ou CNS + data de nascimento (sem senha). Retorna JWT.
- POST /api/auth/profissional: CPF ou e-mail + senha, verificada com BCrypt (o seed do dump já usa BCrypt). Retorna JWT.
- JWT (jjwt 0.12.x) com expiração configurável e claims de usuário e papéis. Segredo vindo da variável de ambiente JWT_SECRET (falhar com mensagem clara se ausente ou com menos de 32 caracteres). Nunca colocar o segredo no código.
- RBAC com Spring Security: CIDADAO, RECEPCAO_ACS, PROFISSIONAL_SAUDE. Rotas públicas: apenas /api/auth/**. Liberar OPTIONS para o CORS.
- @RestControllerAdvice com mensagens em PT-BR e JSON padronizado de erro (401, 403, 404, 422, 500). Respostas de login com erro não devem revelar se o CPF existe.
- Registrar em log_auditoria os acessos negados (403).
Teste com curl.exe ou Invoke-RestMethod, usando os usuários do seed (ver dump): login da equipe, login do cidadão, token inválido, papel errado. Mostre os resultados.
```

### Etapa 3: regras de negócio (RF02 a RF08)

```
Antes de alterar arquivos, me mostre um plano curto e espere eu aprovar.

Leia AGENTS.md e README.md. Implemente no /backend as regras RF02 a RF08 (o seed já existe no dump, não recriar):
- EspecialidadeController: GET /api/especialidades e GET /api/especialidades/{id}/checklist.
- SolicitacaoController: criar solicitação (cidadão ou RECEPCAO_ACS; gravar criada_por_usuario_id; gerar o campo protocolo único), listar fila da UBS com filtros e paginação, detalhe com linha do tempo, enviar para a UBS.
- Upload de anexos (JPG, PNG, PDF até 5 MB, validando tipo e tamanho) vinculados a item do checklist; arquivos salvos fora de qualquer pasta pública; download somente por endpoint autenticado e autorizado (dono ou equipe).
- Bloqueio de envio (status EM_CONFERENCIA_UBS) enquanto houver item obrigatorio=true sem anexo (RF03).
- SinalVitalController: ACOLHIMENTO_UBS (somente PROFISSIONAL_SAUDE, vinculando o profissional) e AUTO_RELATO_DOMICILIAR (RF04).
- ConferenciaUbsController: aprovar (define prioridade_oficial e vai para APTO_REGULACAO) e devolver (PENDENCIA_DOCUMENTAL, com item rejeitado e motivo_rejeicao); reenvio do cidadão substitui apenas o anexo rejeitado e volta para EM_CONFERENCIA_UBS (RF05, RF06).
- Exportação JSON estruturada para Conecta Saúde / SISREG (RF08).
- GET /api/ubs/dashboard com indicadores da UBS (totais por status, pendências, solicitações recentes, encaminhamentos por especialidade).
- log_auditoria automático em visualização clínica, aprovação e devolução.
Teste o fluxo completo com curl.exe ou Invoke-RestMethod: cidadão cria, tenta enviar incompleto (bloqueio), anexa, envia; profissional registra sinais vitais, devolve, cidadão reenvia, profissional aprova, exporta o JSON. Mostre os resultados.
```

---

## Web (Angular)

> Antes de começar o web, o backend precisa estar rodando em `http://localhost:8080` e `JWT_SECRET` definido no terminal.

### 2.1: base, tema e layout

```
Antes de alterar arquivos, me mostre um plano curto e espere eu aprovar.

Leia AGENTS.md e analise a imagem do protótipo web anexada (TRIA SUS Americana).
Crie /frontend-web com:
ng new frontend-web --standalone --style=scss --routing --ssr=false --skip-git --defaults
(--skip-git porque o repositório já existe na raiz; sem perguntas interativas).
Extraia do protótipo a paleta (verde institucional), tipografia e espaçamentos e crie variáveis CSS em src/styles.scss.
Crie o layout shell: sidebar verde (Visão Geral, Fila, Conferência Documental, Pré-triagem assistida) e topbar com nome da UBS e usuário.
Configure environment com apiUrl=http://localhost:8080/api, AuthInterceptor (Bearer), AuthGuard e rotas /login, /dashboard, /fila, /conferencia/:id (as telas ainda podem ser placeholders).
Rode npm run build e corrija os erros.
```

### 2.2: login

```
Antes de alterar arquivos, me mostre um plano curto e espere eu aprovar.

Implemente /login (POST /api/auth/profissional): guarde o JWT, redirecione para /dashboard, trate 401 com mensagem em PT-BR, logout, guard por perfil e redirecionamento automático ao login quando o token expirar. Teste contra o backend rodando com um usuário do seed.
```

### 2.3: dashboard

```
Antes de alterar arquivos, me mostre um plano curto e espere eu aprovar.

Implemente /dashboard conforme o protótipo: cards de indicadores da UBS, solicitações recentes, alertas de pendência, gráfico de barras de encaminhamentos por especialidade (Chart.js ou ng2-charts) e botão "+ Pré-triagem assistida" (RF07). Consuma GET /api/ubs/dashboard. Se faltar algum dado no endpoint, ajuste o backend e me avise. Trate estados de carregamento e erro.
```

### 2.4: fila

```
Antes de alterar arquivos, me mostre um plano curto e espere eu aprovar.

Implemente /fila: tabela paginada com filtros (especialidade, status documental, prioridade oficial), badges de status coloridos, clique abre /conferencia/:id e botão "Exportar para Conecta Saúde / SISREG" (RF08, baixa o JSON).
```

### 2.5: conferência documental

```
Antes de alterar arquivos, me mostre um plano curto e espere eu aprovar.

Implemente /conferencia/:id: dados do paciente, formulário de sinais vitais ACOLHIMENTO_UBS (PA, temperatura, glicemia, saturação; RF04), preview dos documentos do checklist (endpoint autenticado, usando blob), seleção de prioridade oficial, botão "Validar e liberar" (RF05) e "Devolver por pendência" com modal para escolher o item rejeitado e informar o motivo (RF06). Peça confirmação antes de ações irreversíveis. Rode npm run build.
```

### 2.6: pré-triagem assistida (RF07)

```
Antes de alterar arquivos, me mostre um plano curto e espere eu aprovar.

Implemente o modo simplificado de cadastro para RECEPCAO_ACS: busca/cadastro de paciente, escolha da especialidade, queixa, upload dos documentos pelo checklist. Fonte grande, alto contraste, poucos passos (RNF03). Rode npm run build.
```

---

## Erros comuns

| Erro | Causa | Solução |
| --- | --- | --- |
| `Schema-validation: wrong column type` | Entidade diferente do dump | Corrigir a **entidade**, nunca o dump nem o `validate` |
| `Connection refused` / senha falhou | Postgres parado ou senha diferente de `postgres` | Subir o serviço ou ajustar `application.properties` |
| `Port 8080 already in use` | Outro processo na porta | Encerrar o processo ou mudar `server.port` |
| 401/403 no preflight do Angular | `OPTIONS` bloqueado no Security | Liberar `OPTIONS` e conferir o CORS |
| `curl` com resposta estranha no PowerShell | `curl` é alias de `Invoke-WebRequest` | Usar `curl.exe` ou `Invoke-RestMethod` |
| Codex fica "preso" no `mvn spring-boot:run` | O comando nunca termina | Rodar em background e conferir o log |
| Angular criou um `.git` dentro de `frontend-web/` | `ng new` sem `--skip-git` | Apagar `frontend-web/.git` |
| `JWT_SECRET` ausente | Variável não definida no terminal | `$env:JWT_SECRET = "chave-longa-com-mais-de-32-caracteres"` |
| Codex alterou o dump ou o README | Ele "ajusta" para fazer o código passar | `git checkout -- database README.md` e reforçar a regra do `AGENTS.md` |