import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/config.dart';
import 'core/font_scale.dart';
import 'core/theme.dart';
import 'router.dart';
import 'services/auth_service.dart';
import 'services/auth_service_impl.dart';
import 'services/especialidade_service.dart';
import 'services/especialidade_service_impl.dart';
import 'services/solicitacao_service.dart';
import 'services/solicitacao_service_impl.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const TriaSusApp());
}

class TriaSusApp extends StatelessWidget {
  const TriaSusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => FontScaleNotifier()),
        Provider<IAuthService>(
          create: (_) =>
              AppConfig.useMock ? MockAuthService() : RealAuthService(),
        ),
        Provider<IEspecialidadeService>(
          create: (_) => AppConfig.useMock
              ? MockEspecialidadeService()
              : RealEspecialidadeService(),
        ),
        Provider<ISolicitacaoService>(
          create: (_) => AppConfig.useMock
              ? MockSolicitacaoService()
              : RealSolicitacaoService(),
        ),
      ],
      child: Consumer<FontScaleNotifier>(
        builder: (context, fontNotifier, child) {
          return MaterialApp.router(
            title: AppConfig.appTitle,
            theme: AppTheme.lightTheme,
            routerConfig: appRouter,
            debugShowCheckedModeBanner: false,
            // Aplicação global do textScaler conforme RNF03 (controle funcional A+ Fonte)
            builder: (context, childWidget) {
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.linear(fontNotifier.scale),
                ),
                child: childWidget!,
              );
            },
          );
        },
      ),
    );
  }
}
