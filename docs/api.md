# TriaSUS Americana — Documentação da API REST

Esta documentação descreve todos os endpoints reais implementados no backend do TriaSUS (Etapas 3A, 3B e 3C), incluindo perfis de acesso, formatos de requisição, respostas e tratamento de erros.

---

## 1. Padrões Gerais

- **Base URL**: `http://localhost:8080`
- **Autenticação**: Bearer Token JWT via header `Authorization: Bearer <token>`.
- **Formato de Dados**: `application/json; charset=utf-8` (exceto uploads, que utilizam `multipart/form-data`).
- **Formato Padronizado de Erro**:
  ```json
  {
    "timestamp": "2026-11-26T10:00:00.000",
    "status": 400,
    "mensagem": "Descrição do erro em PT-BR",
    "caminho": "/api/exemplo"
  }
  ```
  - `400 Bad Request`: Requisições malformadas ou parâmetros incorretos.
  - `401 Unauthorized`: Token ausente, inválido ou credenciais incorretas.
  - `403 Forbidden`: Perfil sem autorização ou acesso indevido à solicitação/UBS.
  - `404 Not Found`: Recurso não localizado.
  - `413 Payload Too Large`: Arquivo excede o limite de 5 MB.
  - `422 Unprocessable Entity`: Violação de regras de negócio ou validações de formulário.
  - `500 Internal Server Error`: Erro interno no servidor sem exposição de stack trace.

---

## 2. Autenticação (`/api/auth`)

### 2.1. Login do Cidadão
- **Endpoint**: `POST /api/auth/cidadao`
- **Acesso**: Público
- **Corpo da Requisição**:
  ```json
  {
    "identificador": "39053344705",
    "dataNascimento": "1958-03-14"
  }
  ```
  *Obs.: O `identificador` aceita CPF (11 dígitos) ou CNS (15 dígitos).*
- **Resposta (200 OK)**:
  ```json
  {
    "token": "eyJhbGciOiJIUzI1NiJ9...",
    "tipo": "Bearer",
    "expiracao": "2026-11-26T16:00:00Z",
    "usuarioId": 3,
    "nome": "Mariana Souza (teste)",
    "papeis": ["CIDADAO"],
    "pacienteId": 1,
    "profissionalId": null
  }
  ```

### 2.2. Login de Profissional / Recepção
- **Endpoint**: `POST /api/auth/profissional`
- **Acesso**: Público
- **Corpo da Requisição**:
  ```json
  {
    "login": "enfermagem@triasus.local",
    "senha": "Triasus@123"
  }
  ```
- **Resposta (200 OK)**:
  ```json
  {
    "token": "eyJhbGciOiJIUzI1NiJ9...",
    "tipo": "Bearer",
    "expiracao": "2026-11-26T16:00:00Z",
    "usuarioId": 1,
    "nome": "Ana Enfermeira (teste)",
    "papeis": ["PROFISSIONAL_SAUDE"],
    "pacienteId": null,
    "profissionalId": 1
  }
  ```

### 2.3. Usuário Autenticado (`/me`)
- **Endpoint**: `GET /api/auth/me`
- **Acesso**: Qualquer usuário autenticado
- **Resposta (200 OK)**:
  ```json
  {
    "id": 1,
    "nome": "Ana Enfermeira (teste)",
    "email": "enfermagem@triasus.local",
    "cpf": "52998224725",
    "papeis": ["PROFISSIONAL_SAUDE"],
    "pacienteId": null,
    "profissionalId": 1
  }
  ```

---

## 3. Cadastros Base e Contato

### 3.1. Especialidades Ativas
- **Endpoint**: `GET /api/especialidades`
- **Acesso**: Autenticado
- **Resposta (200 OK)**:
  ```json
  [
    {
      "id": 1,
      "nome": "Ortopedia",
      "descricao": "Consulta especializada em ortopedia",
      "ativo": true
    }
  ]
  ```

### 3.2. Checklist por Especialidade
- **Endpoint**: `GET /api/especialidades/{id}/checklist`
- **Acesso**: Autenticado
- **Resposta (200 OK)**:
  ```json
  [
    {
      "id": 2,
      "especialidadeId": 1,
      "nomeDocumento": "Exame prévio (Raio-X ou laudo)",
      "descricaoOrientacao": "PDF ou foto do laudo",
      "obrigatorio": true
    }
  ]
  ```

### 3.3. Confirmação de Contato do Cidadão (RF08)
- **Endpoint**: `POST /api/pacientes/me/contato`
- **Acesso**: `CIDADAO`
- **Corpo da Requisição**:
  ```json
  {
    "telefone": "19987654321"
  }
  ```
- **Resposta (200 OK)**:
  ```json
  {
    "id": 1,
    "usuarioId": 3,
    "nome": "Mariana Souza (teste)",
    "cpf": "39053344705",
    "cartaoSus": "700000000000001",
    "dataNascimento": "1958-03-14",
    "telefone": "19987654321",
    "contatoValidado": true,
    "unidadeReferenciaId": 1,
    "unidadeReferenciaNome": "UBS Centro"
  }
  ```

---

## 4. Solicitações de Encaminhamento (`/api/solicitacoes`)

### 4.1. Criar Solicitação (Própria ou Assistida RF07)
- **Endpoint**: `POST /api/solicitacoes`
- **Acesso**: `CIDADAO` (cria para si) ou `RECEPCAO_ACS` (informa `pacienteId`)
- **Corpo da Requisição**:
  ```json
  {
    "especialidadeId": 1,
    "pacienteId": 1,
    "queixaRelatada": "Dor intensa no joelho direito há semanas",
    "tempoEvolucao": "3 semanas"
  }
  ```
- **Resposta (201 Created)**:
  Retorna o objeto `SolicitacaoDetalheDTO` com status inicial `RASCUNHO` e protocolo formatado (`TRIA-YYYY-XXXXXX`).

### 4.2. Listar Solicitações
- **Endpoint**: `GET /api/solicitacoes`
- **Acesso**: 
  - `CIDADAO`: Retorna apenas suas próprias solicitações (`List<SolicitacaoResumoDTO>`).
  - `PROFISSIONAL_SAUDE` / `RECEPCAO_ACS`: Retorna a fila paginada das UBSs do profissional (`Page<SolicitacaoResumoDTO>`), suportando filtros `especialidadeId`, `status`, `prioridadeOficial`, `page`, `size`.

### 4.3. Detalhe da Solicitação
- **Endpoint**: `GET /api/solicitacoes/{id}`
- **Acesso**: Cidadão dono ou equipe de saúde da UBS vinculada (403 em outros casos).
- **Resposta (200 OK)**: Dados completos, itens do checklist, status dos documentos e linha do tempo.

### 4.4. Enviar para Conferência
- **Endpoint**: `POST /api/solicitacoes/{id}/enviar`
- **Acesso**: Cidadão dono ou equipe da UBS.
- **Regra**: Exige que todos os itens de checklist com `obrigatorio = true` possuam anexo `VALIDO` ou `PENDENTE`. Caso falte algum item, retorna **422 Unprocessable Entity** listando as pendências. Se aprovado, transiciona para `EM_CONFERENCIA_UBS`.

---

## 5. Anexos de Documentos

### 5.1. Upload de Documento
- **Endpoint**: `POST /api/solicitacoes/{id}/documentos`
- **Acesso**: Dono da solicitação ou equipe da UBS.
- **Content-Type**: `multipart/form-data`
- **Parâmetros**:
  - `itemChecklistId`: (Integer) ID do item do protocolo.
  - `arquivo`: Arquivo físico (JPG, PNG ou PDF até 5 MB).
- **Validação**: Verificação real de bytes mágicos. Salvo em diretório privado com nome UUID.
- **Reenvio**: Caso o item já possua documento `REJEITADO`, substitui o arquivo e retorna a solicitação para `EM_CONFERENCIA_UBS`.

### 5.2. Download de Documento
- **Endpoint**: `GET /api/documentos/{id}`
- **Acesso**: Dono da solicitação ou equipe da UBS.
- **Resposta**: Retorna stream de bytes com `Content-Disposition: inline; filename*=UTF-8''...` sanitizado e registra visualização clínica em `log_auditoria`.

---

## 6. Sinais Vitais no Acolhimento (`/api/solicitacoes/{id}/sinais-vitais`)

### 6.1. Registrar Sinais Vitais
- **Endpoint**: `POST /api/solicitacoes/{id}/sinais-vitais`
- **Acesso**:
  - `ACOLHIMENTO_UBS`: Somente `PROFISSIONAL_SAUDE` da UBS. Vincula o profissional logado.
  - `AUTO_RELATO_DOMICILIAR`: Somente `CIDADAO` dono da solicitação.
- **Corpo da Requisição**:
  ```json
  {
    "origemAfericao": "ACOLHIMENTO_UBS",
    "pressaoArterial": "130x85",
    "frequenciaCardiaca": 78,
    "temperatura": 36.7,
    "glicemia": 95,
    "saturacao": 98
  }
  ```
- **Resposta (201 Created)**: Objeto `SinalVitalDTO`.

### 6.2. Listar Sinais Vitais da Solicitação
- **Endpoint**: `GET /api/solicitacoes/{id}/sinais-vitais`
- **Acesso**: Cidadão dono ou equipe da UBS.
- **Resposta (200 OK)**: Histórico completo diferenciando medições da UBS de auto-relatos.

---

## 7. Conferência UBS (`/api/conferencia`)

### 7.1. Validação Individual de Documento
- **Endpoint**: `PATCH /api/conferencia/documentos/{documentoId}`
- **Acesso**: `PROFISSIONAL_SAUDE` da UBS vinculada.
- **Corpo da Requisição**:
  ```json
  {
    "statusValidacao": "VALIDO"
  }
  ```
  *Ou rejeitar individualmente com `motivoRejeicao`:*
  ```json
  {
    "statusValidacao": "REJEITADO",
    "motivoRejeicao": "Imagem embaçada, ilegível"
  }
  ```

### 7.2. Devolver Solicitação por Pendência (RF06)
- **Endpoint**: `POST /api/conferencia/{id}/devolver`
- **Acesso**: `PROFISSIONAL_SAUDE` da UBS vinculada.
- **Corpo da Requisição**:
  ```json
  {
    "itemChecklistId": 4,
    "motivoRejeicao": "Foto do pedido médico cortada nas bordas"
  }
  ```
- **Regra**: Marca o anexo como `REJEITADO`, altera o status da solicitação para `PENDENCIA_DOCUMENTAL` e preserva os demais documentos e histórico.

### 7.3. Aprovar Solicitação para Regulação (RF05)
- **Endpoint**: `POST /api/conferencia/{id}/aprovar`
- **Acesso**: `PROFISSIONAL_SAUDE` da UBS vinculada.
- **Corpo da Requisição**:
  ```json
  {
    "prioridadeOficial": "ALTA",
    "observacaoProfissional": "Paciente com dor aguda incapacitante, quadro confirmado."
  }
  ```
- **Regra**: Exige que todos os anexos obrigatórios estejam com status `VALIDO`. Transiciona para `APTO_REGULACAO`, gravando a prioridade clínica e o profissional responsável.

### 7.4. Exportar Pacote para Regulação (RF08)
- **Endpoint**: `GET /api/conferencia/exportar`
- **Acesso**: `PROFISSIONAL_SAUDE` da UBS vinculada.
- **Query Params**: `especialidadeId`, `dataInicio` (YYYY-MM-DD), `dataFim` (YYYY-MM-DD).
- **Resposta (200 OK)**: Lista estruturada contendo dados do paciente (com telefone validado e CNS), profissional conferencista, sinais de acolhimento e anexos validados para integração no Conecta Saúde / SISREG.

---

## 8. Dashboard da UBS (`/api/ubs/dashboard`)

- **Endpoint**: `GET /api/ubs/dashboard`
- **Acesso**: `PROFISSIONAL_SAUDE` ou `RECEPCAO_ACS`.
- **Resposta (200 OK)**:
  ```json
  {
    "totaisPorStatus": {
      "RASCUNHO": 2,
      "EM_CONFERENCIA_UBS": 1,
      "PENDENCIA_DOCUMENTAL": 0,
      "APTO_REGULACAO": 3
    },
    "totalPendenciasDocumentais": 0,
    "encaminhamentosPorEspecialidade": {
      "Ortopedia": 4,
      "Gastroenterologia": 2
    },
    "solicitacoesRecentes": [ ... ]
  }
  ```
