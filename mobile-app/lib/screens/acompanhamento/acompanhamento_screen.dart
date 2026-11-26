import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../services/solicitacao_service.dart';
import '../../widgets/base_screen_layout.dart';

class AcompanhamentoScreen extends StatefulWidget {
  final int solicitacaoId;

  const AcompanhamentoScreen({super.key, required this.solicitacaoId});

  @override
  State<AcompanhamentoScreen> createState() => _AcompanhamentoScreenState();
}

class _AcompanhamentoScreenState extends State<AcompanhamentoScreen> {
  late Future<SolicitacaoModel> _solicitacaoFuture;

  @override
  void initState() {
    super.initState();
    _solicitacaoFuture = context
        .read<ISolicitacaoService>()
        .getSolicitacaoById(widget.solicitacaoId);
  }

  @override
  Widget build(BuildContext context) {
    return BaseScreenLayout(
      title: 'Acompanhamento',
      body: FutureBuilder<SolicitacaoModel>(
        future: _solicitacaoFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erro: ${snapshot.error}'));
          }

          final s = snapshot.data!;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.especialidadeNome ?? 'Especialidade',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text('Protocolo: ${s.protocolo}'),
                        Text('Unidade: ${s.unidadeNome ?? "UBS Central"}'),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: s.status == 'PENDENCIA_DOCUMENTAL'
                                ? const Color(0xFFFFDAD6)
                                : const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Status atual: ${s.statusDescricao}',
                            style: TextStyle(
                              color: s.status == 'PENDENCIA_DOCUMENTAL'
                                  ? const Color(0xFFBA1A1A)
                                  : const Color(0xFF007A48),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (s.observacaoProfissional != null &&
                    s.observacaoProfissional!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Card(
                    color: const Color(0xFFFFF4E5),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.warning_amber_rounded, color: Colors.orange),
                              SizedBox(width: 8),
                              Text(
                                'Orientações da UBS',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Color(0xFF8A3B00),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(s.observacaoProfissional!),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                const Text(
                  'Linha do Tempo',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                _TimelineStep(
                  title: 'Pré-triagem Enviada',
                  isDone: true,
                  subtitle: 'Dados e sintomas preenchidos pelo cidadão',
                ),
                _TimelineStep(
                  title: 'Conferência na UBS',
                  isDone: s.status != 'RASCUNHO',
                  subtitle: 'Validação documental pela equipe de saúde da unidade',
                ),
                _TimelineStep(
                  title: 'Apto para Regulação',
                  isDone: s.status == 'APTO_REGULACAO',
                  subtitle: 'Encaminhamento enviado ao SISREG/Conecta Saúde',
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _TimelineStep extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isDone;

  const _TimelineStep({
    required this.title,
    required this.subtitle,
    required this.isDone,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isDone ? Icons.check_circle : Icons.radio_button_unchecked,
            color: isDone ? const Color(0xFF007A48) : const Color(0xFF94A3B8),
            size: 26,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: isDone ? const Color(0xFF1E293B) : const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
