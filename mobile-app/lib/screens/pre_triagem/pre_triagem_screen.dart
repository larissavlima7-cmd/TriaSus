import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../services/especialidade_service.dart';
import '../../services/solicitacao_service.dart';
import '../../widgets/base_screen_layout.dart';

class PreTriagemScreen extends StatefulWidget {
  const PreTriagemScreen({super.key});

  @override
  State<PreTriagemScreen> createState() => _PreTriagemScreenState();
}

class _PreTriagemScreenState extends State<PreTriagemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _queixaController = TextEditingController();
  final _tempoEvolucaoController = TextEditingController();
  final _telefoneController = TextEditingController();
  
  int? _especialidadeSelecionadaId;
  List<EspecialidadeModel> _especialidades = [];
  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _carregarEspecialidades();
  }

  Future<void> _carregarEspecialidades() async {
    try {
      final lista = await context.read<IEspecialidadeService>().getEspecialidades();
      if (mounted) {
        setState(() {
          _especialidades = lista;
          if (lista.isNotEmpty) {
            _especialidadeSelecionadaId = lista.first.id;
          }
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _queixaController.dispose();
    _tempoEvolucaoController.dispose();
    _telefoneController.dispose();
    super.dispose();
  }

  Future<void> _salvarAvancar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_especialidadeSelecionadaId == null) return;

    setState(() => _isSubmitting = true);

    try {
      final nova = await context.read<ISolicitacaoService>().criarSolicitacao(
            especialidadeId: _especialidadeSelecionadaId!,
            queixaRelatada: _queixaController.text,
            tempoEvolucao: _tempoEvolucaoController.text,
            telefoneContato: _telefoneController.text,
          );
      if (mounted) {
        context.pushReplacement('/checklist/${nova.id}');
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
      title: 'Nova Pré-Triagem',
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      '1. Especialidade Solicitada',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<int>(
                      initialValue: _especialidadeSelecionadaId,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.medical_services_outlined),
                      ),
                      items: _especialidades.map((e) {
                        return DropdownMenuItem<int>(
                          value: e.id,
                          child: Text(e.nome),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() => _especialidadeSelecionadaId = val);
                      },
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      '2. Informações Clínicas',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _queixaController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Qual é o motivo do encaminhamento / sintomas?',
                        hintText: 'Descreva resumidamente o que você está sentindo',
                      ),
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Preencha este campo.' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _tempoEvolucaoController,
                      decoration: const InputDecoration(
                        labelText: 'Há quanto tempo sente esses sintomas?',
                        hintText: 'Ex: 2 semanas, 3 meses',
                        prefixIcon: Icon(Icons.access_time),
                      ),
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Preencha este campo.' : null,
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      '3. Contato e Confirmação',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _telefoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Telefone / WhatsApp para contato',
                        hintText: '(19) 99999-9999',
                        prefixIcon: Icon(Icons.phone_outlined),
                      ),
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Informe um telefone.' : null,
                    ),
                    const SizedBox(height: 28),
                    ElevatedButton(
                      onPressed: _isSubmitting ? null : _salvarAvancar,
                      child: _isSubmitting
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Avançar para Anexo de Documentos'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
