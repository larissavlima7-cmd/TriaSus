import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/font_scale.dart';
import '../../models/models.dart';
import '../../services/solicitacao_service.dart';

class SolicitacoesScreen extends StatefulWidget {
  const SolicitacoesScreen({super.key});

  @override
  State<SolicitacoesScreen> createState() => _SolicitacoesScreenState();
}

class _SolicitacoesScreenState extends State<SolicitacoesScreen> {
  late Future<List<SolicitacaoModel>> _solicitacoesFuture;

  @override
  void initState() {
    super.initState();
    _recarregar();
  }

  void _recarregar() {
    setState(() {
      _solicitacoesFuture =
          context.read<ISolicitacaoService>().getMinhasSolicitacoes();
    });
  }

  Widget _buildStatusBadge(String status, String descricao) {
    Color bgColor;
    Color textColor;
    IconData iconData;

    switch (status) {
      case 'RASCUNHO':
        bgColor = const Color(0xFFF1F5F9);
        textColor = const Color(0xFF475569);
        iconData = Icons.edit_note_rounded;
        break;
      case 'EM_CONFERENCIA_UBS':
        bgColor = const Color(0xFFFFEDD5);
        textColor = const Color(0xFFC2410C);
        iconData = Icons.hourglass_top_rounded;
        break;
      case 'PENDENCIA_DOCUMENTAL':
        bgColor = const Color(0xFFFFDAD6);
        textColor = const Color(0xFFBA1A1A);
        iconData = Icons.error_outline_rounded;
        break;
      case 'APTO_REGULACAO':
        bgColor = const Color(0xFFDCFCE7);
        textColor = const Color(0xFF15803D);
        iconData = Icons.check_circle_outline_rounded;
        break;
      default:
        bgColor = const Color(0xFFF1F5F9);
        textColor = const Color(0xFF334155);
        iconData = Icons.info_outline_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(iconData, size: 14, color: textColor),
          const SizedBox(width: 4),
          Text(
            descricao,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),
        elevation: 0,
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
              'Solicitações',
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
        child: RefreshIndicator(
          onRefresh: () async => _recarregar(),
          child: FutureBuilder<List<SolicitacaoModel>>(
            future: _solicitacoesFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.cloud_off_rounded,
                            size: 48, color: Color(0xFFBA1A1A)),
                        const SizedBox(height: 12),
                        Text(
                          'Erro ao carregar solicitações: ${snapshot.error}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Color(0xFFBA1A1A)),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _recarregar,
                          child: const Text('Tentar de novo'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final lista = snapshot.data ?? [];
              if (lista.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.folder_open_rounded,
                            size: 64, color: Color(0xFF94A3B8)),
                        const SizedBox(height: 14),
                        const Text(
                          'Você ainda não tem solicitações',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF334155),
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Inicie sua primeira pré-triagem de especialidade para acompanhar o andamento aqui.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: () => context.push('/pre-triagem'),
                          icon: const Icon(Icons.add),
                          label: const Text('Iniciar pré-triagem'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: lista.length,
                itemBuilder: (context, index) {
                  final item = lista[index];
                  return Card(
                    elevation: 1,
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      title: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              item.especialidadeNome ?? 'Especialidade',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ),
                          _buildStatusBadge(item.status, item.statusDescricao),
                        ],
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 6),
                          Text('Protocolo: ${item.protocolo}'),
                          Text('Unidade: ${item.unidadeNome ?? "UBS Centro"}'),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Text(
                                'Etapa ${item.etapaAtualNumero} de 3',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF007A48),
                                ),
                              ),
                              const Spacer(),
                              const Text(
                                'Toque para detalhes →',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      onTap: () {
                        context.push('/acompanhamento/${item.id}');
                      },
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
