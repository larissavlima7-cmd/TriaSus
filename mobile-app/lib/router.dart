import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'core/storage.dart';
import 'screens/acompanhamento/acompanhamento_screen.dart';
import 'screens/checklist/checklist_screen.dart';
import 'screens/inicio/inicio_screen.dart';
import 'screens/login/login_screen.dart';
import 'screens/pre_triagem/pre_triagem_screen.dart';
import 'screens/solicitacoes/solicitacoes_screen.dart';

/// Configuração central de rotas com GoRouter e guarda de autenticação
final GoRouter appRouter = GoRouter(
  initialLocation: '/login',
  redirect: (BuildContext context, GoRouterState state) async {
    final token = await AppStorage.getToken();
    final bool loggedIn = token != null && token.isNotEmpty;
    final bool isLoggingIn = state.matchedLocation == '/login';

    if (!loggedIn && !isLoggingIn) {
      return '/login';
    }

    if (loggedIn && isLoggingIn) {
      return '/inicio';
    }

    return null;
  },
  routes: <RouteBase>[
    GoRoute(
      path: '/login',
      builder: (BuildContext context, GoRouterState state) {
        return const LoginScreen();
      },
    ),
    GoRoute(
      path: '/inicio',
      builder: (BuildContext context, GoRouterState state) {
        return const InicioScreen();
      },
    ),
    GoRoute(
      path: '/pre-triagem',
      builder: (BuildContext context, GoRouterState state) {
        return const PreTriagemScreen();
      },
    ),
    GoRoute(
      path: '/checklist/:id',
      builder: (BuildContext context, GoRouterState state) {
        final id = int.tryParse(state.pathParameters['id'] ?? '0') ?? 0;
        return ChecklistScreen(solicitacaoId: id);
      },
    ),
    GoRoute(
      path: '/acompanhamento/:id',
      builder: (BuildContext context, GoRouterState state) {
        final id = int.tryParse(state.pathParameters['id'] ?? '0') ?? 0;
        return AcompanhamentoScreen(solicitacaoId: id);
      },
    ),
    GoRoute(
      path: '/solicitacoes',
      builder: (BuildContext context, GoRouterState state) {
        return const SolicitacoesScreen();
      },
    ),
  ],
);
