// Teste de fumaça mínimo: garante que a tela de login constrói sem erros.
// (Substitui o teste-modelo de contador gerado pelo Flutter, que não
// correspondia a este app e falhava sempre.)

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:sxdata/providers/auth_provider.dart';
import 'package:sxdata/screens/login_screen.dart';

void main() {
  testWidgets('Tela de login constrói e mostra os campos básicos',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AuthProvider(),
        child: const MaterialApp(home: LoginScreen()),
      ),
    );
    await tester.pump();

    expect(find.text('Bem-vindo ao SXData'), findsOneWidget);
    expect(find.text('Entrar'), findsOneWidget);
  });
}
