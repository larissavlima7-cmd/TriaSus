Leia @README.md e @database/dump_triasus.sql. Crie um CLAUDE.md na raiz com:
- resumo do projeto (2-3 linhas)
- stack: Java 21 + Spring Boot 3.4 + PostgreSQL (backend), Angular standalone (frontend-web), Flutter (mobile-app)
- comandos: build/run de cada módulo
- convenções: DTOs com record, nunca expor entidade nem senha_hash, mensagens de erro em PT-BR, status como enum STRING
- regras de negócio críticas (RF01-RF08, RNF01-RNF05) em formato de lista curta
- lista das tabelas reais do dump
Antes de criar, me avise se o README e o dump estiverem inconsistentes (tabelas faltando, nomes diferentes).

ETAPA 1 (plan mode): Leia @CLAUDE.md, @README.md e @database/dump_triasus.sql.
Crie em /backend um projeto Maven (Java 21, Spring Boot 3.4.x, pacote br.gov.sp.americana.triasus) com web, data-jpa, postgresql, validation, security, lombok e jjwt (0.12.x).
Configure application.properties: datasource postgres local (triasus_americana, postgres/postgres, comentário de onde trocar), ddl-auto=validate, multipart max 5MB, dir de uploads, CORS para http://localhost:4200.
Crie TODAS as entidades JPA espelhando exatamente o dump + repositories.
Rode mvn clean compile e mvn spring-boot:run. Corrija até subir sem erro de validate. Não avance além disso.

ETAPA 2: Implemente segurança e auth: AuthController com POST /api/auth/cidadao (CPF ou CNS + data de nascimento) e POST /api/auth/profissional (CPF/e-mail + senha com BCrypt), JWT com expiração, RBAC (CIDADAO, RECEPCAO_ACS, PROFISSIONAL_SAUDE), @RestControllerAdvice em PT-BR. Segredo do JWT via variável de ambiente. Teste os endpoints com curl.

ETAPA 3: Implemente RF02-RF08: SolicitacaoController, ConferenciaUbsController, SinalVitalController, EspecialidadeController (+ /{id}/checklist), upload (JPG/PNG/PDF até 5MB, endpoint autenticado para download), bloqueio de envio sem itens obrigatórios, aprovar/devolver, export JSON SISREG, log_auditoria automático. Crie um seed com 1 UBS, 1 profissional e 2 especialidades (Ortopedia, Gastro) com checklist. Teste o fluxo completo com curl e me mostre o resultado.

Leia @CLAUDE.md e veja a imagem @docs/prototipo-web.png.
Crie /frontend-web com: ng new --standalone --style=scss --routing --ssr=false (sem perguntas interativas).
Extraia do protótipo a paleta (verde institucional), tipografia e espaçamentos e crie variáveis CSS em src/styles.scss.
Crie o layout shell: sidebar verde (Visão Geral, Fila, Conferência Documental, Pré-triagem assistida) + topbar com nome da UBS e usuário.
Configure environment com apiUrl=http://localhost:8080/api, AuthInterceptor (Bearer), AuthGuard e rotas /login, /dashboard, /fila, /conferencia/:id.
Rode npm run build e corrija os erros.

Implemente /login (POST /api/auth/profissional), guarde o JWT, redirecione pro /dashboard, trate 401 com mensagem em PT-BR, logout e guard por perfil. Teste contra o backend rodando.

Implemente /dashboard conforme o protótipo: cards de indicadores da UBS, solicitações recentes, alertas de pendência, gráfico de barras de encaminhamentos por especialidade (use Chart.js ou ng2-charts) e botão "+ Pré-triagem assistida" (RF07). Se faltar endpoint de métricas no backend, crie um GET /api/ubs/dashboard e me avise.

Implemente /fila: tabela paginada com filtros (especialidade, status documental, prioridade oficial), badges de status coloridos, clique abre /conferencia/:id e botão "Exportar para Conecta Saúde / SISREG" (RF08, baixa o JSON).

Implemente /conferencia/:id: dados do paciente, form de sinais vitais ACOLHIMENTO_UBS (PA, temp, glicemia, saturação; RF04), preview dos documentos do checklist (via endpoint autenticado, use blob), seleção de prioridade oficial, botão "Validar e liberar" (RF05) e "Devolver por pendência" com modal pra escolher o item rejeitado e o motivo (RF06). Confirmação antes de ações irreversíveis.

Implemente o modo simplificado de cadastro para RECEPCAO_ACS: busca/cadastro de paciente, escolha da especialidade, queixa, upload dos documentos pelo checklist. Fonte grande, alto contraste, poucos passos.