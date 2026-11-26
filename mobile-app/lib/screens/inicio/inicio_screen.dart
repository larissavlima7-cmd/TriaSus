import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../services/auth_service.dart';
import '../../services/solicitacao_service.dart';
import '../../widgets/base_screen_layout.dart';

class InicioScreen extends StatefulWidget {
  const InicioScreen({super.key});

  @override
  State<InicioScreen> createState() => _InicioScreenState();
}

class _InicioScreenState extends State<InicioScreen> {
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

  @override
  Widget build(BuildContext context) {
    return BaseScreenLayout(
      title: 'Minhas Solicitações',
      showBackButton: false,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/pre-triagem'),
        backgroundColor: const Color(0xFF007A48),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Nova Pré-Triagem',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async => _recarregar(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                color: const Color(0xFFE8F5E9),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: Color(0xFF007A48)),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Acompanhe aqui o andamento e o checklist de documentos dos seus encaminhamentos.',
                          style: TextStyle(
                            color: Color(0xFF004D2D),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Sair da conta',
                        icon: const Icon(Icons.logout, color: Color(0xFFBA1A1A)),
                        onPressed: () async {
                          await context.read<IAuthService>().logout();
                          if (context.mounted) {
                            context.go('/login');
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Solicitações em andamento',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 12),
              FutureBuilder<List<SolicitacaoModel>>(
                future: _solicitacoesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Text(
                          'Erro ao carregar solicitações: ${snapshot.error}',
                          style: const TextStyle(color: Color(0xFFBA1A1A)),
                        ),
                      ),
                    );
                  }

                  final lista = snapshot.data ?? [];
                  if (lista.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: Text(
                          'Nenhuma solicitação encontrada.\nClique abaixo para iniciar uma nova pré-triagem.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Color(0xFF64748B), fontSize: 16),
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: lista.length,
                    itemBuilder: (context, index) {
                      final item = lista[index];
                      return Card(
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          title: Text(
                            item.especialidadeNome ?? 'Especialidade',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text('Protocolo: ${item.protocolo}'),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: item.status == 'PENDENCIA_DOCUMENTAL'
                                      ? const Color(0xFFFFDAD6)
                                      : const Color(0xFFE8F5E9),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  item.statusDescricao,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                    color: item.status == 'PENDENCIA_DOCUMENTAL'
                                        ? const Color(0xFFBA1A1A)
                                        : const Color(0xFF007A48),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: () {
                            context.push('/acompanhamento/${item.id}');
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
