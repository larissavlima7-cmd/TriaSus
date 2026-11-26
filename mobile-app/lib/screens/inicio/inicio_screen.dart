import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/font_scale.dart';
import '../../core/storage.dart';
import '../../models/models.dart';
import '../../services/auth_service.dart';
import '../../services/solicitacao_service.dart';

class InicioScreen extends StatefulWidget {
  const InicioScreen({super.key});

  @override
  State<InicioScreen> createState() => _InicioScreenState();
}

class _InicioScreenState extends State<InicioScreen> {
  late Future<List<SolicitacaoModel>> _solicitacoesFuture;
  String _nomeCidadao = 'Mariana';
  final String _ubsReferencia = 'UBS Centro • Americana';
  int _currentBottomIndex = 0;

  @override
  void initState() {
    super.initState();
    _carregarPerfil();
    _recarregarSolicitacoes();
  }

  Future<void> _carregarPerfil() async {
    final raw = await AppStorage.getUserData();
    if (raw != null) {
      try {
        final Map<String, dynamic> data = jsonDecode(raw);
        if (data['nome'] != null && data['nome'].toString().isNotEmpty) {
          final completo = data['nome'].toString().trim();
          final primeiroNome = completo.split(' ').first;
          setState(() {
            _nomeCidadao = primeiroNome;
          });
        }
      } catch (_) {}
    }
  }

  void _recarregarSolicitacoes() {
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
        bgColor = const Color(0xFFFFEDD5); // Pêssego suave
        textColor = const Color(0xFFC2410C); // Laranja queimado acessível
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

  Widget _buildCardAcompanhamento(SolicitacaoModel item) {
    final protocoloCurto = item.protocolo.length > 15
        ? '${item.protocolo.substring(0, 12)}...'
        : item.protocolo;

    return InkWell(
      onTap: () => context.push('/acompanhamento/${item.id}'),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(8),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Barra vertical lateral verde de destaque
              Container(
                width: 5,
                color: const Color(0xFF007A48),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Cabeçalho do card: Especialidade + Status badge
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              '${item.especialidadeNome ?? "Especialidade"} • $protocoloCurto',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _buildStatusBadge(item.status, item.statusDescricao),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Encaminhado pela ${item.unidadeNome ?? "UBS Centro"}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Barra de progresso e etapa
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Etapa ${item.etapaAtualNumero} de 3',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF334155),
                            ),
                          ),
                          Text(
                            '${(item.porcentagemProgresso * 100).toInt()}%',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF007A48),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: item.porcentagemProgresso,
                          minHeight: 6,
                          backgroundColor: const Color(0xFFE2E8F0),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFF007A48),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Rodapé do card: Badge WhatsApp + Atualizado hoje
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F5E9),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.check_circle,
                                    size: 14, color: Color(0xFF007A48)),
                                SizedBox(width: 4),
                                Text(
                                  'WhatsApp confirmado ✔',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF007A48),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Text(
                            'Atualizado hoje',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardAcessoRapido({
    required IconData icon,
    required String titulo,
    required String subtitulo,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 0.8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFFE8F5E9),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: const Color(0xFF007A48), size: 24),
        ),
        title: Text(
          titulo,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
        subtitle: Text(
          subtitulo,
          style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
        ),
        trailing: const Icon(Icons.chevron_right, color: Color(0xFF94A3B8)),
        onTap: onTap,
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
        titleSpacing: 16,
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
                size: 22,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Início',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Notificações',
            icon: const Icon(Icons.notifications_none_rounded, size: 26),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Nenhuma nova notificação no momento.')),
              );
            },
          ),
          IconButton(
            tooltip: 'Meu Perfil',
            icon: const CircleAvatar(
              radius: 16,
              backgroundColor: Color(0xFF005A32),
              child: Icon(Icons.person, color: Colors.white, size: 20),
            ),
            onPressed: () {
              _showPerfilDialog();
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => _recarregarSolicitacoes(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Linha de localização (UBS) e botão A+ Fonte
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Chip UBS Referência
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.location_on_rounded,
                              size: 15, color: Color(0xFF475569)),
                          const SizedBox(width: 4),
                          Text(
                            _ubsReferencia,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF334155),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Botão A+ Fonte com borda e alvo de toque
                    Consumer<FontScaleNotifier>(
                      builder: (context, fontNotifier, _) {
                        return InkWell(
                          onTap: () => fontNotifier.cycleNextScale(),
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: const Color(0xFFE2E8F0), width: 1.2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withAlpha(5),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  'A+',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: Color(0xFF007A48),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Text(
                                  'Fonte',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '(${fontNotifier.scale.toStringAsFixed(2)}x)',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Saudação
                Text(
                  'Olá, $_nomeCidadao!',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Acompanhe seus encaminhamentos e documentos na UBS.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 20),

                // Card de Destaque: Atendimento Ágil
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD1F2DF),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFA7E5C3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.local_hospital_rounded,
                                  size: 15, color: Color(0xFF005A32)),
                              SizedBox(width: 6),
                              Text(
                                'ATENDIMENTO ÁGIL',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                  color: Color(0xFF005A32),
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.medical_services_outlined,
                              color: Color(0xFF007A48),
                              size: 24,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Precisa agendar um\nespecialista?',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0A331E),
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Organize sua pré-triagem e envie seus exames antes de ir à regulação',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF1E4D36),
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => context.push('/pre-triagem'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF005A32),
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Iniciar pré-triagem',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(Icons.arrow_forward_rounded, size: 18),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Seção: Acompanhe sua solicitação
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Acompanhe sua solicitação',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        // Navega para aba de solicitações
                        setState(() => _currentBottomIndex = 2);
                      },
                      child: const Text(
                        'Ver todas',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF007A48),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Conteúdo da solicitação com tratamento de loading, vazio e erro
                FutureBuilder<List<SolicitacaoModel>>(
                  future: _solicitacoesFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 36),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }

                    if (snapshot.hasError) {
                      return Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFDAD6),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFBA1A1A)),
                        ),
                        child: Column(
                          children: [
                            const Icon(Icons.cloud_off_rounded,
                                size: 36, color: Color(0xFFBA1A1A)),
                            const SizedBox(height: 8),
                            const Text(
                              'Não foi possível carregar suas solicitações.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFBA1A1A),
                              ),
                            ),
                            const SizedBox(height: 12),
                            OutlinedButton.icon(
                              onPressed: _recarregarSolicitacoes,
                              icon: const Icon(Icons.refresh,
                                  color: Color(0xFFBA1A1A)),
                              label: const Text(
                                'Tentar de novo',
                                style: TextStyle(color: Color(0xFFBA1A1A)),
                              ),
                              style: OutlinedButton.styleFrom(
                                side:
                                    const BorderSide(color: Color(0xFFBA1A1A)),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    final lista = snapshot.data ?? [];
                    if (lista.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          children: [
                            const Icon(Icons.folder_open_rounded,
                                size: 48, color: Color(0xFF94A3B8)),
                            const SizedBox(height: 10),
                            const Text(
                              'Você ainda não tem solicitações',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF334155),
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Quando você solicitar uma pré-triagem, ela aparecerá aqui para você acompanhar.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF64748B),
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () => context.push('/pre-triagem'),
                              icon: const Icon(Icons.add),
                              label: const Text('Iniciar agora'),
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(180, 44),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    // Exibe a solicitação mais recente em destaque conforme protótipo
                    return _buildCardAcompanhamento(lista.first);
                  },
                ),
                const SizedBox(height: 24),

                // Seção: Acesso rápido
                const Text(
                  'Acesso rápido',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 10),
                _buildCardAcessoRapido(
                  icon: Icons.folder_shared_rounded,
                  titulo: 'Meus documentos e exames',
                  subtitulo: 'Laudos, receitas e pedidos médicos',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                            'Seção de documentos anexados nas solicitações.'),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 6),
                _buildCardAcessoRapido(
                  icon: Icons.history_rounded,
                  titulo: 'Histórico de encaminhamentos',
                  subtitulo: 'Consultas anteriores e protocolos',
                  onTap: () {
                    // Alterna para aba de solicitações
                    setState(() => _currentBottomIndex = 2);
                  },
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentBottomIndex,
        onDestinationSelected: (index) {
          setState(() => _currentBottomIndex = index);
          if (index == 1) {
            context.push('/pre-triagem');
          } else if (index == 3) {
            _showPerfilDialog();
          }
        },
        backgroundColor: Colors.white,
        elevation: 4,
        indicatorColor: const Color(0xFFD1F2DF),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home, color: Color(0xFF007A48)),
            label: 'Início',
          ),
          NavigationDestination(
            icon: Icon(Icons.medical_services_outlined),
            selectedIcon:
                Icon(Icons.medical_services, color: Color(0xFF007A48)),
            label: 'Pré-triagem',
          ),
          NavigationDestination(
            icon: Icon(Icons.assignment_outlined),
            selectedIcon: Icon(Icons.assignment, color: Color(0xFF007A48)),
            label: 'Solicitações',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: Color(0xFF007A48)),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }

  void _showPerfilDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Perfil do Cidadão'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nome: $_nomeCidadao'),
            const SizedBox(height: 6),
            Text('Unidade: $_ubsReferencia'),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 6),
            const Text(
              'Para alteração de dados cadastrais ou endereço de referência, procure sua UBS.',
              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await context.read<IAuthService>().logout();
              if (mounted) context.go('/login');
            },
            child: const Text('Sair da Conta',
                style: TextStyle(color: Color(0xFFBA1A1A))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }
}
