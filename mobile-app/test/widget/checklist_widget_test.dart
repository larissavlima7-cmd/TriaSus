import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:triasus_app/core/theme.dart';
import 'package:triasus_app/screens/checklist/checklist_screen.dart';
import 'package:triasus_app/services/especialidade_service.dart';
import 'package:triasus_app/services/especialidade_service_impl.dart';
import 'package:triasus_app/services/solicitacao_service.dart';
import 'package:triasus_app/services/solicitacao_service_impl.dart';

void main() {
  Widget createTestWidget() {
    return MultiProvider(
      providers: [
        Provider<ISolicitacaoService>(
          create: (_) => MockSolicitacaoService(),
        ),
        Provider<IEspecialidadeService>(
          create: (_) => MockEspecialidadeService(),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: const ChecklistScreen(solicitacaoId: 1),
      ),
    );
  }

  group('Widget Tests: Checklist Documental (RF02 / RF03)', () {
    testWidgets('Deve renderizar os itens do protocolo e dica rápida', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Checklist de documentos'), findsOneWidget);
      expect(find.textContaining('Dica rápida:'), findsOneWidget);
      expect(find.text('Revisar e enviar para UBS'), findsOneWidget);
    });

    testWidgets('Botão Revisar e enviar deve estar DESABILITADO quando falta item obrigatório', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      final buttonFinder = find.widgetWithText(ElevatedButton, 'Revisar e enviar para UBS');
      expect(buttonFinder, findsOneWidget);

      final ElevatedButton button = tester.widget(buttonFinder);
      // Faltam itens obrigatórios na solicitação 1 do mock -> botão desabilitado (onPressed == null)
      expect(button.onPressed, isNull);

      expect(find.textContaining('Falta 1 documento para continuar'), findsOneWidget);
    });
  });
}
