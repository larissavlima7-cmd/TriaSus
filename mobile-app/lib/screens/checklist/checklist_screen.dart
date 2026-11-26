import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../services/especialidade_service.dart';
import '../../services/solicitacao_service.dart';
import '../../widgets/base_screen_layout.dart';

class ChecklistScreen extends StatefulWidget {
  final int solicitacaoId;

  const ChecklistScreen({super.key, required this.solicitacaoId});

  @override
  State<ChecklistScreen> createState() => _ChecklistScreenState();
}

class _ChecklistScreenState extends State<ChecklistScreen> {
  SolicitacaoModel? _solicitacao;
  List<ChecklistItemModel> _checklist = [];
  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    try {
      final solicitacaoService = context.read<ISolicitacaoService>();
      final especialidadeService = context.read<IEspecialidadeService>();
      final s = await solicitacaoService.getSolicitacaoById(widget.solicitacaoId);
      final c = await especialidadeService.getChecklistByEspecialidade(s.especialidadeId);
      if (mounted) {
        setState(() {
          _solicitacao = s;
          _checklist = c;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _concluirEnvio() async {
    setState(() => _isSubmitting = true);
    try {
      await context
          .read<ISolicitacaoService>()
          .submeterSolicitacao(widget.solicitacaoId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pré-triagem enviada para conferência da UBS com sucesso!'),
            backgroundColor: Color(0xFF007A48),
          ),
        );
        context.go('/inicio');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BaseScreenLayout(
      title: 'Checklist de Documentos',
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    color: const Color(0xFFE8F5E9),
                    child: Padding(
                      padding: const EdgeInsets.all(14.0),
                      child: Text(
                        'Protocolo: ${_solicitacao?.protocolo}\nEspecialidade: ${_solicitacao?.especialidadeNome ?? "Geral"}',
                        style: const TextStyle(
                          color: Color(0xFF004D2D),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Documentos Exigidos',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _checklist.length,
                    itemBuilder: (context, index) {
                      final item = _checklist[index];
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(14.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    item.obrigatorio
                                        ? Icons.error_outline
                                        : Icons.info_outline,
                                    color: item.obrigatorio
                                        ? const Color(0xFFBA1A1A)
                                        : const Color(0xFF007A48),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      item.nomeDocumento,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  if (item.obrigatorio)
                                    const Text(
                                      'Obrigatório',
                                      style: TextStyle(
                                        color: Color(0xFFBA1A1A),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                item.descricaoOrientacao,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF475569),
                                ),
                              ),
                              const SizedBox(height: 12),
                              OutlinedButton.icon(
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                          'Anexar documento: ${item.nomeDocumento}'),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.attach_file),
                                label: const Text('Tirar foto ou anexar PDF'),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _isSubmitting ? null : _concluirEnvio,
                    child: _isSubmitting
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Enviar para Conferência na UBS'),
                  ),
                ],
              ),
            ),
    );
  }
}
