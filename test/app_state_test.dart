// Pruebas del estado global: puntaje ponderado entre tests, anti-"farmeo",
// permanencia de la pérdida de puntos, reinicio por cambio de nivel y por
// reinicio manual. Usa shared_preferences mockeado (todo offline, sin nube).
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:holyapp/models/bible_question.dart';
import 'package:holyapp/models/difficulty_level.dart';
import 'package:holyapp/services/storage_service.dart';
import 'package:holyapp/state/app_state.dart';
import 'package:holyapp/state/test_controller.dart';

BibleQuestion q(String id, DifficultyLevel d) => BibleQuestion(
      id: id,
      text: 'Pregunta $id',
      options: const ['A', 'B', 'C', 'D'],
      correctIndex: 0,
      difficulty: d,
      references: const ['Ref'],
    );

TestResult result({
  List<BibleQuestion> correct = const [],
  List<BibleQuestion> failed = const [],
}) =>
    TestResult(firstTryCorrect: correct, failed: failed);

void main() {
  late AppState app;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    app = AppState(StorageService.instance);
    await app.init();
  });

  group('Puntaje acumulado entre tests', () {
    test('suma los puntos ponderados de los aciertos limpios', () async {
      await app.commitTestResult(result(correct: [
        q('e', DifficultyLevel.entrada), // 1
        q('m', DifficultyLevel.medio), // 2
        q('t', DifficultyLevel.teologia), // 4
      ]));

      expect(app.score, 1 + 2 + 4);
      expect(app.correctFirstTryIds.toSet(), {'e', 'm', 't'});
      expect(app.reviewIds, isEmpty);
    });

    test('no "farmea": reacertar una pregunta ya contada no vuelve a sumar',
        () async {
      await app.commitTestResult(result(correct: [q('e', DifficultyLevel.entrada)]));
      await app.commitTestResult(result(correct: [q('e', DifficultyLevel.entrada)]));

      expect(app.score, 1);
      expect(app.correctFirstTryIds, ['e']);
    });
  });

  group('Pérdida de puntos y "Repasar"', () {
    test('fallar una pregunta ya acertada le resta su puntaje y la manda a '
        'repasar', () async {
      await app.commitTestResult(result(correct: [q('t', DifficultyLevel.teologia)]));
      expect(app.score, 4);

      await app.commitTestResult(result(failed: [q('t', DifficultyLevel.teologia)]));
      expect(app.score, 0);
      expect(app.correctFirstTryIds, isEmpty);
      expect(app.reviewIds, ['t']);
    });

    test('la pérdida es permanente: una pregunta ya fallada no vuelve a sumar '
        'aunque se acierte limpio luego', () async {
      await app.commitTestResult(result(failed: [q('t', DifficultyLevel.teologia)]));
      await app.commitTestResult(result(correct: [q('t', DifficultyLevel.teologia)]));

      expect(app.score, 0);
      expect(app.reviewIds, ['t']);
      expect(app.correctFirstTryIds, isEmpty);
    });

    test('el puntaje nunca baja de cero', () async {
      await app.commitTestResult(result(failed: [q('e', DifficultyLevel.entrada)]));
      expect(app.score, 0);
    });
  });

  group('Reinicios', () {
    test('cambiar de nivel deja puntaje e historiales en cero', () async {
      await app.commitTestResult(result(correct: [q('e', DifficultyLevel.entrada)]));
      final changed = await app.changeLevel(DifficultyLevel.teologia);

      expect(changed, true);
      expect(app.level, DifficultyLevel.teologia);
      expect(app.score, 0);
      expect(app.correctFirstTryIds, isEmpty);
      expect(app.reviewIds, isEmpty);
    });

    test('cambiar al mismo nivel no reinicia nada', () async {
      await app.commitTestResult(result(correct: [q('e', DifficultyLevel.entrada)]));
      final changed = await app.changeLevel(DifficultyLevel.entrada);

      expect(changed, false);
      expect(app.score, 1);
    });

    test('reiniciar todo el puntaje vacía puntaje e historiales', () async {
      await app.commitTestResult(result(
        correct: [q('e', DifficultyLevel.entrada)],
        failed: [q('m', DifficultyLevel.medio)],
      ));
      await app.resetAllScore();

      expect(app.score, 0);
      expect(app.correctFirstTryIds, isEmpty);
      expect(app.reviewIds, isEmpty);
    });
  });

  test('el progreso persiste y se recarga en una nueva instancia', () async {
    await app.commitTestResult(result(correct: [q('t', DifficultyLevel.teologia)]));
    await app.changeLevel(DifficultyLevel.teologia);
    await app.commitTestResult(result(correct: [q('t', DifficultyLevel.teologia)]));

    final reloaded = AppState(StorageService.instance);
    await reloaded.init();

    expect(reloaded.level, DifficultyLevel.teologia);
    expect(reloaded.score, 4);
    expect(reloaded.correctFirstTryIds, ['t']);
  });
}
