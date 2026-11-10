## Sistema de Gerenciamento de Consultas e Redução de Filas para a Rede Municipal

### 1. Problemática: 
Na rede pública de saúde (SUS), a alta demanda por consultas e procedimentos especializados gera longas filas de espera e sobrecarga nas Unidades Básicas de Saúde (UBS) e Unidades de Pronto Atendimento (UPA). De acordo com uma pesquisa do Datafolha, 21% dos entrevistados apontaram a saúde como o principal desafio nacional. Já em Porto Alegre, unidades operam com até 400% de lotação. Isso, devido a vários fatores, como: 
Atendimento Inicial com problema: UBS com falta de médicos, infraestrutura inadequada e longas filas fazem as pessoas buscarem o pronto atendimento (UPAs).
 Insuficiência de leitos: não tem estrutura para acolher todos os pacientes.
Mal gestão e investimento: desperdício de recursos, a distribuição ineficiente de profissionais, o que dificulta a otimização dos atendimentos. 
Desse modo, desenvolvemos um Sistema de Gerenciamento de Consultas e Redução de Filas para a Rede Municipal de Americana, para minimizar os impactos na rede de saúde da nossa comunidade. 

### 2. Introdução: 
O documento especifica o planejamento e arquitetura para o desenvolvimento de uma plataforma web e mobile de triagem antecipada e organização de solicitações de atendimento do SUS, visando otimizar o fluxo de encaminhamentos, reduzir inconsistências nos registros e contribuir para a diminuição do tempo de espera por consultas e procedimentos especializados nas UPAs e UBSs. Para isso usaremos o Flutter para a interface gráfica em Mobile (que será focado ________) , _________ para o desenvolvimento web (para o controle ______ )e ________ para o back-end.

### 3. Relação com o projeto:
Os programas federais demonstram a importância de ampliar o acesso aos atendimentos especializados no SUS, porém a redução de filas também depende da organização das informações e da eficiência dos processos iniciais de atendimento.


### 4. Requisitos
#### 4.1 Requisitos Funcionais: 
- RF01 - Autenticação e Identificação: Permitir login via integração nativa com o Gov.br ou validação combinada de CPF / Cartão Nacional de Saúde (CNS) e data de nascimento.
- RF02 - Questionário Dinâmico de Triagem: Apresentar formulários adaptativos por sintomas e especialidades (ex: perguntas específicas para ortopedia ou cardiologia), com linguagem acessível e suporte a opções de múltipla escolha e texto.
- RF03 - Anexação de Mídias e Documentos: Permitir envio de fotos (ex: lesões de pele), PDF de exames anteriores, laudos e receitas através da câmera do celular ou upload de arquivos.
- RF04 - Linha do Tempo e Acompanhamento: Exibir o status em tempo real da solicitação (Criada, Em Análise na UBS, Validada para Regulação, Agendada, Devolvida com Pendência).
- RF05 - Recebimento de Notificações: Enviar alertas preventivos via WhatsApp, SMS ou Push Notification sobre atualizações de status, solicitações de novos exames ou confirmação de consultas.
- RF06 - Checagem Automática de Pendências: Verificar a presença de pré-requisitos essenciais antes de liberar o envio (ex: barrar um pedido de consulta com endocrinologista se não houver exame de glicemia anexo).
- RF07 - Detecção de Duplicidades: Cruzar solicitações ativas do mesmo paciente no banco de dados para sinalizar à equipe registros idênticos ou redundantes para a mesma especialidade.
- RF08 - Sugestão de Prioridade Clínica: Executar algoritmo de pré-classificação de risco (baseado em protocolos como Manchester ou protocolos de regulação do Ministério da Saúde) atribuindo uma prioridade preliminar (Vermelho, Laranja, Amarelo, Verde, Azul).
- RF09 - Painel de Homologação (APS): Permitir que enfermeiros ou médicos da Atenção Primária revisem, complementem ou indeferam os dados inseridos na pré-triagem antes de enviar à regulação municipal/estadual.
- RF10 - Triagem Assistida por Agentes (ACS/Recepção): Disponibilizar interface simplificada para que Agentes Comunitários de Saúde ou recepcionistas das UBS realizem o preenchimento por pacientes sem acesso digital.
- RF11 - Devolução Orientada de Solicitações: Permitir que o regulador devolva uma solicitação marcando exatamente o campo ou documento faltante, com notificação automática ao responsável.
- RF12 - Gestão da Fila por Critério Clínico: Exibir a fila de solicitações organizadas dinamicamente por prioridade médica, tempo de espera e especialidade, evitando a ordenação por ordem de chegada simples.
- RF13 - Exportação/Sincronização de Dados: Gerar arquivos ou chamadas de API compatíveis com os campos exigidos pelos sistemas legados (SISREG e e-SUS APS). 

#### 4.2 Requisitos Não Funcionais:
- RNF01 - Conformidade com a LGPD: Garantir criptografia de dados sensíveis de saúde em trânsito (TLS 1.3) e em repouso (AES-256), além de gestão de consentimento e logs auditáveis de acesso.
- RNF02 - Autenticação Segura e Controle de Acesso (RBAC): Restringir o acesso a dados médicos completos apenas a profissionais de saúde validados por e-CPF ou registro de conselho de classe (CRM/COREN).
- RNF03 - Suporte ao Padrão HL7 / FHIR: Estruturar as APIs e o modelo de dados seguindo o padrão internacional de interoperabilidade em saúde para rápida conexão com a Rede Nacional de Dados em Saúde (RNDS).
- RNF04 - Arquitetura Orientada a Microserviços: Isolar os serviços de triagem, notificações e motor de validação para permitir escalabilidade independente.
- RNF05 - Desempenho em Redes de Baixa Velocidade: Garantir que o aplicativo web/PWA do paciente seja extremamente leve (carregamento em menos de 3 segundos em conexões 3G).
- RNF06 - Acessibilidade (WCAG 2.1 AA): Garantir acessibilidade com leitores de tela, alto contraste e navegação por voz para idosos ou pessoas com deficiência visual.
- RNF07 - Disponibilidade: O sistema deve manter um SLA mínimo de 99,9% de disponibilidade operacional.

### 5. Casos de Teste

#### 5.1 Casos de Teste Funcionais
| ID | Requisitos | Cenário | Descrição | Resultado Esperado |
| --- | --- | --- | --- | --- |
| CT-01 | RF01, RF02, RF03 e RF06 | Jornada do Paciente: Submissão Completa de Triagem | Paciente autentica via Gov.br/CPF, inicia triagem de especialidade, responde perguntas dinâmicas e tenta enviar sem anexar exame. Após alerta do sistema, anexa a mídia/PDF necessária e conclui o envio. | Login realizado, regras de validação impedem envio incompleto e solicitação é criada com documentos anexados. |
| CT-02 | RF07, RF08, RF04 e RF05 | Motor de Regras: Duplicidade, Risco e Notificação | Sistema processa a solicitação enviada no CT-01, verifica ausência de duplicidade (ou alerta se houver), calcula a prioridade clínica preliminar (ex: Amarelo/Laranja), atualiza a linha do tempo e envia notificação Push/WhatsApp ao paciente. | Prioridade calculada corretamente, linha do tempo atualizada em tempo real e notificação entregue no dispositivo.|
| CT-03 | RF09, RF10 e RF11 | Atenção Primária (APS) e Devolução Assistida | preenche pré-triagem para paciente sem acesso digital. Em seguida, o enfermeiro/médico da UBS acessa o painel, identifica uma inconsistência e devolve a solicitação marcando o campo pendente, gerando alerta ao responsável. | Triagem assistida cadastrada com sucesso e fluxo de devolução orientada com notificação de pendência validado. |
| CT-04 | RF12 e RF13 | Gestão da Fila e Interoperabilidade Legada | Médico Regulador visualiza a fila municipal reordenada dinamicamente por gravidade e tempo de espera (não por ordem de chegada), homologa os casos graves e aciona a sincronização automática com SISREG/e-SUS. | Fila exibida por critério clínico de risco e payload de dados gerado/sincronizado com os sistemas legados. |

#### 5.2 Casos de Teste Não Funcionais 
| ID | Requisitos | Escopo | Descrição | Critério | 
| --- | --- | --- | --- | --- | 
| CT-05 | RNF01, RNF02 e RNF03 | Segurança, Permissões e Padrões de Saúde | Validar se dados trafegam criptografados (TLS 1.3/AES-256), tentar acessar prontuários com perfil sem CRM/COREN (RBAC) e validar se as APIs REST seguem a estrutura HL7/FHIR para a RNDS. | Dados protegidos, acessos não autorizados bloqueados (403 Forbidden) e payloads em conformidade com o padrão FHIR. | 
| CT-06 | RNF04, RNF05, RNF06 e RNF07 | Performance, Resiliência e Acessibilidade | Simular alta carga de acessos mantendo SLA de 99,9%, testar PWA em conexão 3G lenta (carregamento < 3s), simular queda do microserviço de notificações e navegar via leitor de tela (WCAG 2.1 AA).| Sistema permanece estável em alta carga, PWA leve, interface acessível e falha em microserviço não derruba o restante da plataforma. | 