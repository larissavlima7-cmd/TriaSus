# TriaSUS — orientações do projeto

## Resumo
Plataforma web e mobile de pré-triagem e qualificação documental de encaminhamentos especializados nas UBSs de Americana.
Registra informações declaradas pelo cidadão e sinais vitais aferidos no acolhimento, apoiando a conferência da UBS antes da regulação.

## Stack
- Backend: Java 21, Spring Boot 3.4 e PostgreSQL (`backend/`).
- Painel web: Angular standalone (`frontend-web/`).
- Aplicativo cidadão: Flutter (`mobile-app/`).

## Build e execução (Windows/PowerShell)
- Backend: `cd backend; .\mvnw.cmd clean package`; executar com `cd backend; .\mvnw.cmd spring-boot:run`. Sem wrapper, usar `mvn`.
- Angular: `cd frontend-web; npm install`; executar com `npm start` ou `npx ng serve`, conforme `package.json`.
- Flutter: `cd mobile-app; flutter pub get`; executar com `flutter run`.

## Convenções
- Arquitetura MVC; DTOs de dados com `record`.
- Nunca expor entidades JPA nem `senha_hash` em contratos ou respostas de API.
- Mensagens de erro em PT-BR; enums com `@Enumerated(EnumType.STRING)`.
- PKs com `GenerationType.IDENTITY`; entidades usam `@Getter` e `@Setter`, nunca `@Data`.
- Relacionamentos JPA devem ser `LAZY`.

## Regras de negócio
- RF01: cidadão por CPF ou CNS e data de nascimento; `senha_hash` pode ser nulo.
- RF02–RF03: pré-triagem por especialidade e checklist obrigatório; bloquear envio incompleto.
- RF04: separar sinais vitais de acolhimento UBS do auto-relato; incluir frequência cardíaca.
- RF05: profissional confere documentos, define prioridade oficial e libera para regulação.
- RF06: devolver com documento e motivo; preservar histórico e notificar o cidadão.
- RF07: cadastro assistido; `solicitacao.criada_por_usuario_id` identifica quem cadastrou.
- RF08: validar contato, exibir linha do tempo e gerar pacote para Conecta Saúde/SISREG.
- RNF01–RNF02: proteger dados, manter auditoria e aplicar acesso por perfil.
- RNF03–RNF04: responsividade, acessibilidade e JPG/PNG/PDF até 5 MB com otimização.
- RNF05: separar Model, Controller/API REST e Views web/mobile.

## Banco de dados
- `database/dump_triasus.sql` é a fonte de verdade; o seed já está nele e não deve ser recriado.
- Tabelas: `usuario`, `papel`, `usuario_papel`, `unidade_ubs`, `especialidade`, `paciente`, `profissional`, `profissional_unidade`, `checklist_protocolo`, `solicitacao`, `documento_anexo`, `sinal_vital`, `log_auditoria`.
- `solicitacao` contém `criada_por_usuario_id`; `sinal_vital` contém `frequencia_cardiaca`.
- `papel.nome`: `CIDADAO`, `RECEPCAO_ACS`, `PROFISSIONAL_SAUDE`.
- `solicitacao.status`: `RASCUNHO`, `EM_CONFERENCIA_UBS`, `PENDENCIA_DOCUMENTAL`, `APTO_REGULACAO`.
- `solicitacao.prioridade_oficial`: `NAO_DEFINIDA`, `BAIXA`, `MEDIA`, `ALTA`, `URGENTE`.
- `documento_anexo.status_validacao`: `PENDENTE`, `VALIDO`, `REJEITADO`.
- `documento_anexo.tipo_mime`: `image/jpeg`, `image/png`, `application/pdf` ou `NULL`.
- `sinal_vital.origem_afericao`: `ACOLHIMENTO_UBS`, `AUTO_RELATO_DOMICILIAR`.

## Regras de trabalho
- Não alterar `database/dump_triasus.sql` nem `README.md` sem avisar o usuário.
- Nunca trocar `ddl-auto=validate` por `update` ou `none` para mascarar erro; corrigir a entidade.
- Em testes no terminal, usar `curl.exe` ou `Invoke-RestMethod`, nunca o alias `curl`.
- Processos longos (`mvn spring-boot:run`, `ng serve`) devem rodar em segundo plano; confirmar pelo log e encerrar ao terminar.
- Ao final de cada tarefa, listar arquivos criados ou alterados e como testar.

## mobile-app
- Stack: Flutter (Dart) com arquitetura em camadas e Provider para gerenciamento de estado.
- Estrutura `lib/`: `core/` (tema, config, http, storage, escala de fonte), `models/`, `services/`, `screens/<tela>/` e `widgets/`.
- Rede e serviços: isolar chamadas de API em `services/`; não colocar lógica de rede em widgets.
- Configuração de rede: URL base em `lib/core/config.dart`; usar `10.0.2.2` para emulador Android em vez de `localhost`.
- Autenticação e segurança: JWT exclusivamente em `flutter_secure_storage` (nunca em `shared_preferences`). Proibido logar token, CPF ou documentos.
- Acessibilidade (RNF03): textos escaláveis por controle "A+ Fonte", suporte a alto contraste, alvos de toque >= 48dp, linguagem simples sem jargão clínico (o app não faz diagnóstico).
- Comandos essenciais: `cd mobile-app; flutter pub get`, `flutter analyze` (deve passar sem erros) e `flutter run`.

