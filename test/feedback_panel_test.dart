// Widget test del panel de retroalimentación: muestra el mensaje correcto,
// la explicación y las citas, y notifica al continuar.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:holyapp/widgets/feedback_panel.dart';

Widget _host(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('acierto: muestra "¡Acertaste!", explicación y citas', (t) async {
    await t.pumpWidget(_host(FeedbackPanel(
      correct: true,
      references: const ['Juan 3:16', 'Romanos 5:8'],
      explanation: 'Dios amó al mundo.',
      onContinue: () {},
    )));

    expect(find.text('¡Acertaste!'), findsOneWidget);
    expect(find.text('Dios amó al mundo.'), findsOneWidget);
    expect(find.text('Juan 3:16'), findsOneWidget);
    expect(find.text('Romanos 5:8'), findsOneWidget);
    expect(find.text('Continuar'), findsOneWidget);
  });

  testWidgets('fallo: muestra el mensaje de corrección', (t) async {
    await t.pumpWidget(_host(FeedbackPanel(
      correct: false,
      references: const ['Génesis 1:1'],
      onContinue: () {},
    )));

    expect(find.text('Lo siento, para la próxima'), findsOneWidget);
    expect(find.text('Génesis 1:1'), findsOneWidget);
  });

  testWidgets('sin explicación no rompe el render', (t) async {
    await t.pumpWidget(_host(FeedbackPanel(
      correct: true,
      references: const ['Salmo 23'],
      onContinue: () {},
    )));

    expect(find.text('¡Acertaste!'), findsOneWidget);
    expect(find.text('Salmo 23'), findsOneWidget);
  });

  testWidgets('el botón Continuar dispara onContinue', (t) async {
    var tapped = false;
    await t.pumpWidget(_host(FeedbackPanel(
      correct: true,
      references: const ['Juan 1:1'],
      onContinue: () => tapped = true,
    )));

    await t.tap(find.text('Continuar'));
    expect(tapped, true);
  });
}
