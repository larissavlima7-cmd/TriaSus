# TriaSUS — orientações do projeto

## Resumo
Plataforma web e mobile de pré-triagem e qualificação documental de encaminhamentos especializados nas UBSs de Americana.
Registra dados declarados pelo cidadão e sinais vitais aferidos no acolhimento, apoiando a conferência da UBS antes da regulação.

## Stack
- Backend: Java 21, Spring Boot 3.4, PostgreSQL (`backend/`).
- Painel web: Angular standalone (`frontend-web/`).
- Aplicativo cidadão: Flutter (`mobile-app/`).

## Build e execução (Windows/PowerShell)
- Backend: `cd backend; .\mvnw.cmd clean package`; executar com `cd backend; .\mvnw.cmd spring-boot:run` (se não houver Maven Wrapper, usar `mvn`).
- Angular: `cd frontend-web; npm install`; executar com `npm start` ou `npx ng serve` conforme scripts do `package.json`.
- Flutter: `cd mobile-app; flutter pub get`; executar com `flutter run`.
- Os diretórios/manifests dos módulos ainda não estão presentes; confirme os scripts locais quando forem adicionados.

## Convenções
- Arquitetura MVC.
- DTOs de dados usando `record`.
- Nunca exponha entidades JPA nem `senha_hash` em respostas ou contratos de API.
- Mensagens de erro em PT-BR.
- Persistir enums com `@Enumerated(EnumType.STRING)`.
- PKs com `GenerationType.IDENTITY`.

## Regras de negócio críticas
- RF01: identificar cidadão por CPF ou CNS e data de nascimento; `senha_hash` pode ser nulo para cidadão.
- RF02–RF03: pré-triagem por especialidade e checklist obrigatório; bloquear envio incompleto.
- RF04: registrar sinais vitais no acolhimento da UBS, separados de auto-relato; dump inclui também frequência cardíaca.
- RF05: equipe confere documentos, define prioridade clínica oficial e libera para regulação.
- RF06: devolver com documento e motivo da pendência, preservar histórico e notificar o cidadão; `PENDENTE` no anexo significa aguardando validação, não comprova ausência. O esquema não tem tabela de notificação nem registro explícito de item ausente.
- RF07: cadastro assistido; `solicitacao.criada_por_usuario_id` registra o usuário que cadastrou.
- RF08: validar contato, mostrar linha do tempo e gerar pacote estruturado para Conecta Saúde/SISREG.
- RNF01–RNF02: proteger dados, manter auditoria e aplicar acesso por perfil.
- RNF03–RNF04: acessibilidade/responsividade; aceitar JPG, PNG ou PDF até 5 MB e otimizar imagens.
- RNF05: separar Model, Controller/API REST e Views web/mobile conforme MVC.

## Banco — fonte de verdade
- `database/dump_triasus.sql` é a fonte de verdade do banco; o seed de desenvolvimento já está nele. Não recriar o seed.
- O dump define 13 tabelas: `usuario`, `papel`, `usuario_papel`, `unidade_ubs`, `especialidade`, `paciente`, `profissional`, `profissional_unidade`, `checklist_protocolo`, `solicitacao`, `documento_anexo`, `sinal_vital`, `log_auditoria`.
- Valores restringidos por CHECK no dump:
  - `papel.nome`: `CIDADAO`, `RECEPCAO_ACS`, `PROFISSIONAL_SAUDE`.
  - `solicitacao.status`: `RASCUNHO`, `EM_CONFERENCIA_UBS`, `PENDENCIA_DOCUMENTAL`, `APTO_REGULACAO`.
  - `solicitacao.prioridade_oficial`: `NAO_DEFINIDA`, `BAIXA`, `MEDIA`, `ALTA`, `URGENTE`.
  - `documento_anexo.status_validacao`: `PENDENTE`, `VALIDO`, `REJEITADO`.
  - `documento_anexo.tipo_mime`: `image/jpeg`, `image/png`, `application/pdf` (ou NULL).
  - `sinal_vital.origem_afericao`: `ACOLHIMENTO_UBS`, `AUTO_RELATO_DOMICILIAR`.
- Não altere `database/dump_triasus.sql` nem `README.md` sem avisar o usuário.

## Skills disponíveis e uso
- `angular-developer`, `angular-forms`, `angular-http`: trabalho no `frontend-web/`.
- `jpa-patterns`, `springboot-security`, `springboot-tdd`: trabalho no `backend/`.
- `frontend-design`: decisões e implementação de UI.
