import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:provider/provider.dart';
import '../../core/font_scale.dart';
import '../../models/models.dart';
import '../../services/especialidade_service.dart';
import '../../services/solicitacao_service.dart';

enum MotivoEncaminhamento {
  consultaEspecialista,
  examesDiagnosticos,
  retornoAcompanhamento,
  outroMotivo,
}

enum TempoEvolucaoOpcao {
  menosDe1Semana,
  de1a4Semanas,
  maisDe1Mes,
}

class PreTriagemScreen extends StatefulWidget {
  const PreTriagemScreen({super.key});

  @override
  State<PreTriagemScreen> createState() => _PreTriagemScreenState();
}

class _PreTriagemScreenState extends State<PreTriagemScreen> {
  int _currentStep = 1;
  final int _totalSteps = 6;

  // Passo 1: Motivo
  MotivoEncaminhamento _motivo = MotivoEncaminhamento.consultaEspecialista;

  // Passo 2: Especialidade
  int? _especialidadeSelecionadaId;
  String _especialidadeSelecionadaNome = 'Ortopedia';
  List<EspecialidadeModel> _especialidades = [];
  bool _carregandoEspecialidades = true;

  // Passo 3: Queixa principal
  final _queixaController = TextEditingController();
  final int _maxCharsQueixa = 500;

  // Passo 4: Tempo de evolução
  TempoEvolucaoOpcao _tempoEvolucao = TempoEvolucaoOpcao.menosDe1Semana;

  // Passo 5: Sinais vitais domiciliares (opcional)
  final _paController = TextEditingController();
  final _tempController = TextEditingController();
  final _glicemiaController = TextEditingController();
  final _satController = TextEditingController();

  final _paFormatter = MaskTextInputFormatter(
    mask: '###x##',
    filter: {'#': RegExp(r'[0-9]')},
  );

  bool _isSubmitting = false;
  String? _erroPasso;

  @override
  void initState() {
    super.initState();
    _carregarEspecialidades();
  }

  Future<void> _carregarEspecialidades() async {
    try {
      final lista =
          await context.read<IEspecialidadeService>().getEspecialidades();
      if (mounted) {
        setState(() {
          _especialidades = lista;
          if (lista.isNotEmpty) {
            _especialidadeSelecionadaId = lista.first.id;
            _especialidadeSelecionadaNome = lista.first.nome;
          }
          _carregandoEspecialidades = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _carregandoEspecialidades = false);
    }
  }

  @override
  void dispose() {
    _queixaController.dispose();
    _paController.dispose();
    _tempController.dispose();
    _glicemiaController.dispose();
    _satController.dispose();
    super.dispose();
  }

  String get _tempoEvolucaoTexto {
    switch (_tempoEvolucao) {
      case TempoEvolucaoOpcao.menosDe1Semana:
        return 'Menos de 1 semana';
      case TempoEvolucaoOpcao.de1a4Semanas:
        return 'De 1 a 4 semanas';
      case TempoEvolucaoOpcao.maisDe1Mes:
        return 'Mais de 1 mês';
    }
  }

  String get _motivoTexto {
    switch (_motivo) {
      case MotivoEncaminhamento.consultaEspecialista:
        return 'Consulta com especialista';
      case MotivoEncaminhamento.examesDiagnosticos:
        return 'Exames diagnósticos';
      case MotivoEncaminhamento.retornoAcompanhamento:
        return 'Retorno de acompanhamento';
      case MotivoEncaminhamento.outroMotivo:
        return 'Outro motivo';
    }
  }

  void _avancarPasso() {
    setState(() => _erroPasso = null);

    if (_currentStep == 2 && _especialidadeSelecionadaId == null) {
      setState(() => _erroPasso = 'Selecione uma especialidade para continuar.');
      return;
    }

    if (_currentStep == 3) {
      if (_queixaController.text.trim().isEmpty) {
        setState(
            () => _erroPasso = 'Descreva resumidamente os sintomas para a UBS.');
        return;
      }
    }

    if (_currentStep == 5) {
      // Validação opcional de formato de pressão arterial NNNxNN
      if (_paController.text.isNotEmpty) {
        final paRegex = RegExp(r'^\d{2,3}x\d{2,3}$');
        if (!paRegex.hasMatch(_paController.text.trim())) {
          setState(() =>
              _erroPasso = 'Pressão arterial deve seguir o formato 120x80.');
          return;
        }
      }

      // Validação opcional de temperatura
      if (_tempController.text.isNotEmpty) {
        final t = double.tryParse(_tempController.text.replaceAll(',', '.'));
        if (t == null || t < 30.0 || t > 45.0) {
          setState(() =>
              _erroPasso = 'Temperatura deve estar entre 30.0 ºC e 45.0 ºC.');
          return;
        }
      }

      // Validação opcional de glicemia
      if (_glicemiaController.text.isNotEmpty) {
        final g = int.tryParse(_glicemiaController.text);
        if (g == null || g < 10 || g > 1000) {
          setState(
              () => _erroPasso = 'Glicemia deve estar entre 10 e 1000 mg/dL.');
          return;
        }
      }

      // Validação opcional de saturação
      if (_satController.text.isNotEmpty) {
        final s = int.tryParse(_satController.text);
        if (s == null || s < 0 || s > 100) {
          setState(() => _erroPasso = 'Saturação deve estar entre 0% e 100%.');
          return;
        }
      }
    }

    if (_currentStep < _totalSteps) {
      setState(() => _currentStep++);
    } else {
      _finalizarCriacao();
    }
  }

  void _voltarPasso() {
    if (_currentStep > 1) {
      setState(() {
        _erroPasso = null;
        _currentStep--;
      });
    } else {
      context.pop();
    }
  }

  Future<void> _finalizarCriacao() async {
    setState(() => _isSubmitting = true);

    try {
      SinaisVitaisDomiciliares? sinais;
      if (_paController.text.isNotEmpty ||
          _tempController.text.isNotEmpty ||
          _glicemiaController.text.isNotEmpty ||
          _satController.text.isNotEmpty) {
        sinais = SinaisVitaisDomiciliares(
          pressaoArterial: _paController.text.trim().isNotEmpty
              ? _paController.text.trim()
              : null,
          temperatura: _tempController.text.isNotEmpty
              ? double.tryParse(_tempController.text.replaceAll(',', '.'))
              : null,
          glicemia: _glicemiaController.text.isNotEmpty
              ? int.tryParse(_glicemiaController.text)
              : null,
          saturacao: _satController.text.isNotEmpty
              ? int.tryParse(_satController.text)
              : null,
        );
      }

      final nova = await context.read<ISolicitacaoService>().criarSolicitacao(
            especialidadeId: _especialidadeSelecionadaId!,
            queixaRelatada: _queixaController.text.trim(),
            tempoEvolucao: _tempoEvolucaoTexto,
            sinaisDomiciliares: sinais,
          );

      if (mounted) {
        context.pushReplacement('/checklist/${nova.id}');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _erroPasso = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final double progresso = _currentStep / _totalSteps;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),
        elevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Voltar',
          onPressed: _voltarPasso,
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(
                Icons.local_hospital_rounded,
                color: Color(0xFF007A48),
                size: 20,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Pré Triagem',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
          ],
        ),
        actions: const [
          FontScaleActionButton(),
          SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Card com Cabeçalho e Barra de Progresso
              Card(
                elevation: 0.8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(18.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Nova solicitação',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFD1F2DF),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.assignment_ind_outlined,
                              color: Color(0xFF007A48),
                              size: 22,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progresso,
                          minHeight: 6,
                          backgroundColor: const Color(0xFFE2E8F0),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFF007A48),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Passo $_currentStep de $_totalSteps',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Preencha os dados abaixo para direcionarmos seu atendimento na UBS.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF475569),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Mensagem de erro do passo
              if (_erroPasso != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFDAD6),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFBA1A1A)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline,
                          color: Color(0xFFBA1A1A), size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _erroPasso!,
                          style: const TextStyle(
                            color: Color(0xFFBA1A1A),
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Conteúdo Dinâmico por Passo
              _buildStepContent(),

              const SizedBox(height: 24),

              // Botão Principal de Avanço
              ElevatedButton(
                onPressed: _isSubmitting ? null : _avancarPasso,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF005A32),
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _currentStep == _totalSteps
                                ? 'Salvar rascunho e ir para documentos'
                                : 'Continuar',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward_rounded, size: 18),
                        ],
                      ),
              ),
              const SizedBox(height: 12),

              // Botão Voltar (secundário)
              if (_currentStep > 1)
                OutlinedButton(
                  onPressed: _isSubmitting ? null : _voltarPasso,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Voltar ao passo anterior'),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 1:
        return _buildPasso1Motivo();
      case 2:
        return _buildPasso2Especialidade();
      case 3:
        return _buildPasso3Queixa();
      case 4:
        return _buildPasso4Tempo();
      case 5:
        return _buildPasso5Medicoes();
      case 6:
        return _buildPasso6Resumo();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildOptionTile({
    required String titulo,
    required String subtitulo,
    required IconData icon,
    required bool selecionado,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selecionado ? const Color(0xFFD1F2DF) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selecionado
                ? const Color(0xFF007A48)
                : const Color(0xFFE2E8F0),
            width: selecionado ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: selecionado ? Colors.white : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: const Color(0xFF007A48),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: selecionado
                          ? const Color(0xFF0A331E)
                          : const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitulo,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              selecionado ? Icons.radio_button_checked : Icons.radio_button_off,
              color: selecionado
                  ? const Color(0xFF007A48)
                  : const Color(0xFF94A3B8),
            ),
          ],
        ),
      ),
    );
  }

  // PASSO 1
  Widget _buildPasso1Motivo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Qual o motivo da solicitação?',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        _buildOptionTile(
          titulo: 'Consulta com especialista',
          subtitulo: 'Ex.: Ortopedia, Gastroenterologia',
          icon: Icons.medical_services_outlined,
          selecionado: _motivo == MotivoEncaminhamento.consultaEspecialista,
          onTap: () => setState(
              () => _motivo = MotivoEncaminhamento.consultaEspecialista),
        ),
        _buildOptionTile(
          titulo: 'Exames diagnósticos',
          subtitulo: 'Raio-X, ultrassom, sangue e outros',
          icon: Icons.science_outlined,
          selecionado: _motivo == MotivoEncaminhamento.examesDiagnosticos,
          onTap: () =>
              setState(() => _motivo = MotivoEncaminhamento.examesDiagnosticos),
        ),
        _buildOptionTile(
          titulo: 'Retorno de acompanhamento',
          subtitulo: 'Continuidade de tratamento já iniciado',
          icon: Icons.calendar_month_outlined,
          selecionado: _motivo == MotivoEncaminhamento.retornoAcompanhamento,
          onTap: () => setState(
              () => _motivo = MotivoEncaminhamento.retornoAcompanhamento),
        ),
        _buildOptionTile(
          titulo: 'Outro motivo',
          subtitulo: 'Dúvidas ou encaminhamento diferente',
          icon: Icons.help_outline,
          selecionado: _motivo == MotivoEncaminhamento.outroMotivo,
          onTap: () =>
              setState(() => _motivo = MotivoEncaminhamento.outroMotivo),
        ),
      ],
    );
  }

  // PASSO 2
  Widget _buildPasso2Especialidade() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Selecione a especialidade médica indicada',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        const Text(
          'Confira o nome da especialidade que consta no seu encaminhamento da UBS.',
          style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 14),
        if (_carregandoEspecialidades)
          const Center(child: CircularProgressIndicator())
        else
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFCBD5E1), width: 1.5),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                isExpanded: true,
                value: _especialidadeSelecionadaId,
                items: _especialidades.map((e) {
                  return DropdownMenuItem<int>(
                    value: e.id,
                    child: Text(
                      e.nome,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    final item = _especialidades.firstWhere((e) => e.id == val);
                    setState(() {
                      _especialidadeSelecionadaId = val;
                      _especialidadeSelecionadaNome = item.nome;
                    });
                  }
                },
              ),
            ),
          ),
      ],
    );
  }

  // PASSO 3
  Widget _buildPasso3Queixa() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Motivo principal e sintomas',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        const Text(
          'Conte o motivo principal e os sintomas sentidos (em suas palavras).',
          style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _queixaController,
          maxLines: 4,
          maxLength: _maxCharsQueixa,
          style: const TextStyle(fontSize: 15),
          decoration: const InputDecoration(
            hintText:
                'Ex: Sinto dores fortes no joelho ao caminhar e subir escadas...',
            border: OutlineInputBorder(),
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        // Aviso fixo obrigatório
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFE8F5E9),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFA7E5C3)),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.shield_outlined, color: Color(0xFF007A48), size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Estas informações ajudam a equipe da UBS. O app não faz diagnóstico.',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF004D2D),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // PASSO 4
  Widget _buildPasso4Tempo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Há quanto tempo apresenta o sintoma?',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        const Text(
          'Selecione o período aproximado de evolução:',
          style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 14),
        _buildOptionTile(
          titulo: 'Menos de 1 semana',
          subtitulo: 'Sintomas iniciados recentemente',
          icon: Icons.calendar_view_day,
          selecionado: _tempoEvolucao == TempoEvolucaoOpcao.menosDe1Semana,
          onTap: () => setState(
              () => _tempoEvolucao = TempoEvolucaoOpcao.menosDe1Semana),
        ),
        _buildOptionTile(
          titulo: 'De 1 a 4 semanas',
          subtitulo: 'Sintomas há algumas semanas',
          icon: Icons.calendar_view_week,
          selecionado: _tempoEvolucao == TempoEvolucaoOpcao.de1a4Semanas,
          onTap: () => setState(
              () => _tempoEvolucao = TempoEvolucaoOpcao.de1a4Semanas),
        ),
        _buildOptionTile(
          titulo: 'Mais de 1 mês',
          subtitulo: 'Sintomas crônicos ou persistentes',
          icon: Icons.calendar_month,
          selecionado: _tempoEvolucao == TempoEvolucaoOpcao.maisDe1Mes,
          onTap: () => setState(
              () => _tempoEvolucao = TempoEvolucaoOpcao.maisDe1Mes),
        ),
      ],
    );
  }

  // PASSO 5
  Widget _buildPasso5Medicoes() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.favorite_outline,
                  color: Color(0xFF007A48), size: 20),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Medições feitas em casa',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        const Text(
          'Opcional. Não substitui a aferição da UBS.',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Color(0xFF475569),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _paController,
          inputFormatters: [_paFormatter],
          keyboardType: TextInputType.text,
          decoration: const InputDecoration(
            labelText: 'Pressão Arterial',
            hintText: 'Ex: 120x80',
            prefixIcon: Icon(Icons.speed_outlined),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _tempController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Temperatura (ºC)',
            hintText: 'Ex: 36.5',
            prefixIcon: Icon(Icons.thermostat_outlined),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _glicemiaController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Glicemia (mg/dL)',
            hintText: 'Ex: 95',
            prefixIcon: Icon(Icons.water_drop_outlined),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _satController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Saturação de Oxigênio (%)',
            hintText: 'Ex: 98',
            prefixIcon: Icon(Icons.air_outlined),
          ),
        ),
      ],
    );
  }

  // PASSO 6: RESUMO
  Widget _buildPasso6Resumo() {
    return Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFFCBD5E1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Confira suas informações',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 12),
            _buildResumoRow('Motivo:', _motivoTexto),
            _buildResumoRow('Especialidade:', _especialidadeSelecionadaNome),
            _buildResumoRow('Evolução:', _tempoEvolucaoTexto),
            _buildResumoRow('Sintomas informados:', _queixaController.text),
            if (_paController.text.isNotEmpty ||
                _tempController.text.isNotEmpty ||
                _glicemiaController.text.isNotEmpty ||
                _satController.text.isNotEmpty) ...[
              const Divider(height: 20),
              const Text(
                'Medições em casa:',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
              if (_paController.text.isNotEmpty)
                _buildResumoRow('• Pressão:', _paController.text),
              if (_tempController.text.isNotEmpty)
                _buildResumoRow('• Temperatura:', '${_tempController.text} ºC'),
              if (_glicemiaController.text.isNotEmpty)
                _buildResumoRow('• Glicemia:', '${_glicemiaController.text} mg/dL'),
              if (_satController.text.isNotEmpty)
                _buildResumoRow('• Saturação:', '${_satController.text}%'),
            ],
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Ao avançar, sua solicitação será salva como rascunho e você poderá anexar os documentos exigidos.',
                style: TextStyle(fontSize: 12, color: Color(0xFF334155)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResumoRow(String rotulo, String valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            rotulo,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Color(0xFF475569),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              valor,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF0F172A),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
