import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:triasus_app/core/theme.dart';
import 'package:triasus_app/screens/login/login_screen.dart';
import 'package:triasus_app/services/auth_service.dart';
import 'package:triasus_app/services/auth_service_impl.dart';

void main() {
  Widget createTestWidget() {
    return MultiProvider(
      providers: [
        Provider<IAuthService>(
          create: (_) => MockAuthService(),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: const LoginScreen(),
      ),
    );
  }

  group('Widget Tests: Tela de Login do Cidadão', () {
    testWidgets('Deve renderizar os componentes de identificação e cabeçalho', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Entrar na sua conta'), findsOneWidget);
      expect(find.text('CPF'), findsOneWidget);
      expect(find.text('Cartão SUS'), findsOneWidget);
      expect(find.text('Número do CPF'), findsOneWidget);
      expect(find.text('Data de Nascimento'), findsOneWidget);
      expect(find.text('Entrar'), findsOneWidget);
      expect(find.text('Entrar com gov.br'), findsOneWidget);
      expect(find.text('em breve'), findsOneWidget);
    });

    testWidgets('Deve alternar entre CPF e Cartão SUS mudando os textos', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Clica na aba Cartão SUS
      await tester.tap(find.text('Cartão SUS'));
      await tester.pumpAndSettle();

      expect(find.text('Número do Cartão SUS (15 dígitos)'), findsOneWidget);
    });

    testWidgets('Deve bloquear envio e exibir validação com campos vazios', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Tenta clicar em entrar com campos em branco
      await tester.tap(find.text('Entrar'));
      await tester.pumpAndSettle();

      expect(find.text('Informe o seu CPF.'), findsOneWidget);
      expect(find.text('Informe sua data de nascimento.'), findsOneWidget);
    });
  });
}
