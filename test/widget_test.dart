// Pruebas de la lógica de la cola dinámica (fallo y corrección) y del puntaje.
import 'package:flutter_test/flutter_test.dart';

import 'package:holyapp/models/bible_question.dart';
import 'package:holyapp/models/difficulty_level.dart';
import 'package:holyapp/models/test_length.dart';
import 'package:holyapp/state/test_controller.dart';

BibleQuestion q(String id, {int correct = 0}) => BibleQuestion(
      id: id,
      text: 'Pregunta $id',
      options: const ['A', 'B', 'C', 'D'],
      correctIndex: correct,
      difficulty: DifficultyLevel.entrada,
      references: const ['Ref 1'],
    );

/// Responde la pregunta actual (correcto/incorrecto) y avanza el feedback.
void _respond(TestController c, {required bool right}) {
  final current = c.current!;
  c.answer(right ? current.correctIndex : (current.correctIndex + 1) % 4);
  c.next();
}

void main() {
  group('Cola dinámica', () {
    test('una pregunta fallada vuelve al final y el test no acaba hasta '
        'contestarla bien', () {
      final bank = [q('a'), q('b')];
      final c = TestController(
        level: DifficultyLevel.entrada,
        length: TestLength.twenty, // tope mayor que el banco -> usa 2
        bank: bank,
      );

      // Solo hay 2 preguntas (el banco) en la cola.
      expect(c.remaining, 2);

      final first = c.current!.id;
      _respond(c, right: false); // falla la primera -> va al final
      expect(c.phase, TestPhase.answering);
      expect(c.remaining, 2); // sigue en cola, no se elimina

      // La pregunta actual ahora es la otra.
      expect(c.current!.id, isNot(first));
      _respond(c, right: true); // acierta la segunda -> sale de la cola
      expect(c.remaining, 1);

      // Reaparece la fallada; al acertarla, la cola queda vacía y termina.
      expect(c.current!.id, first);
      _respond(c, right: true);
      expect(c.phase, TestPhase.finished);
      expect(c.remaining, 0);
    });

    test('acierto al primer intento suma; si se falla aunque luego se corrija '
        'no cuenta como acierto limpio', () {
      final c = TestController(
        level: DifficultyLevel.entrada,
        length: TestLength.twenty,
        bank: [q('a'), q('b')],
      );

      // El banco se baraja, así que se leen los IDs en el orden real.
      final firstId = c.current!.id;
      _respond(c, right: true); // primera: limpia
      final secondId = c.current!.id;
      _respond(c, right: false); // segunda: fallada
      _respond(c, right: true); // segunda: corregida al final

      expect(c.phase, TestPhase.finished);
      final result = c.buildResult();
      expect(result.firstTryCorrectIds, {firstId});
      expect(result.failedIds, {secondId});
    });
  });

  group('Modo infinito', () {
    test('mantiene una ventana de preguntas y permite finalizar manualmente',
        () {
      final bank = List.generate(25, (i) => q('q$i'));
      final c = TestController(
        level: DifficultyLevel.entrada,
        length: TestLength.infinite,
        bank: bank,
      );

      expect(c.isInfinite, true);
      expect(c.remaining, 10); // ventana inicial

      // Tras acertar varias, la ventana se rellena desde el pool.
      for (var i = 0; i < 5; i++) {
        _respond(c, right: true);
      }
      expect(c.remaining, 10);
      expect(c.canFinishEarly, true);

      c.finishNow();
      expect(c.phase, TestPhase.finished);
    });
  });

  group('Puntaje ponderado por nivel', () {
    BibleQuestion lvl(String id, DifficultyLevel d) => BibleQuestion(
          id: id,
          text: 'Pregunta $id',
          options: const ['A', 'B', 'C', 'D'],
          correctIndex: 0,
          difficulty: d,
          references: const ['Ref'],
        );

    test('cada acierto al primer intento vale los puntos de su nivel', () {
      final c = TestController(
        level: DifficultyLevel.teologia,
        length: TestLength.twenty,
        bank: [
          lvl('e', DifficultyLevel.entrada), // 1
          lvl('m', DifficultyLevel.medio), // 2
          lvl('t', DifficultyLevel.teologia), // 4
        ],
      );

      // Acierta todo al primer intento.
      while (c.phase != TestPhase.finished) {
        _respond(c, right: true);
      }

      expect(c.buildResult().pointsEarned, 1 + 2 + 4);
    });

    test('una pregunta fallada no aporta puntos aunque se corrija al final', () {
      final c = TestController(
        level: DifficultyLevel.teologia,
        length: TestLength.twenty,
        bank: [lvl('t', DifficultyLevel.teologia)], // vale 4 si fuera limpia
      );

      _respond(c, right: false); // falla
      _respond(c, right: true); // corrige al final
      expect(c.phase, TestPhase.finished);

      final r = c.buildResult();
      expect(r.pointsEarned, 0);
      expect(r.failedIds, {'t'});
    });
  });
}
