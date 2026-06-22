// Pruebas de los modelos: jerarquía/puntos/cascada de niveles y validación
// dura del JSON de preguntas.
import 'package:flutter_test/flutter_test.dart';

import 'package:holyapp/models/bible_question.dart';
import 'package:holyapp/models/difficulty_level.dart';

void main() {
  group('DifficultyLevel', () {
    test('puntos ponderados por nivel', () {
      expect(DifficultyLevel.entrada.points, 1);
      expect(DifficultyLevel.basico.points, 1);
      expect(DifficultyLevel.medio.points, 2);
      expect(DifficultyLevel.avanzado.points, 2);
      expect(DifficultyLevel.pastorado.points, 3);
      expect(DifficultyLevel.teologia.points, 4);
      expect(DifficultyLevel.evangelista.points, 5);
    });

    test('acceso en cascada: el nivel N desbloquea 1..N', () {
      expect(DifficultyLevel.entrada.unlockedLevels, [DifficultyLevel.entrada]);
      expect(
        DifficultyLevel.avanzado.unlockedLevels,
        [
          DifficultyLevel.entrada,
          DifficultyLevel.basico,
          DifficultyLevel.medio,
          DifficultyLevel.avanzado,
        ],
      );
      // El nivel más alto desbloquea los 7.
      expect(
        DifficultyLevel.evangelista.unlockedLevels.length,
        DifficultyLevel.values.length,
      );
    });

    test('fromId hace round-trip y cae en entrada ante un id inválido', () {
      for (final level in DifficultyLevel.values) {
        expect(DifficultyLevel.fromId(level.id), level);
      }
      expect(DifficultyLevel.fromId('inexistente'), DifficultyLevel.entrada);
    });
  });

  group('BibleQuestion.fromJson', () {
    Map<String, dynamic> base() => {
          'id': 'x1',
          'text': '¿Pregunta?',
          'options': ['A', 'B', 'C', 'D'],
          'correctIndex': 2,
          'difficulty': 'medio',
          'references': ['Juan 3:16'],
        };

    test('parsea una pregunta válida (con y sin explicación)', () {
      final q = BibleQuestion.fromJson(base());
      expect(q.id, 'x1');
      expect(q.correctIndex, 2);
      expect(q.difficulty, DifficultyLevel.medio);
      expect(q.explanation, isNull);

      final withExpl = BibleQuestion.fromJson(base()..['explanation'] = 'Porque...');
      expect(withExpl.explanation, 'Porque...');
    });

    test('rechaza un número de opciones distinto de 4', () {
      final bad = base()..['options'] = ['A', 'B', 'C'];
      expect(() => BibleQuestion.fromJson(bad), throwsFormatException);
    });

    test('rechaza correctIndex fuera de rango', () {
      expect(() => BibleQuestion.fromJson(base()..['correctIndex'] = 4),
          throwsFormatException);
      expect(() => BibleQuestion.fromJson(base()..['correctIndex'] = -1),
          throwsFormatException);
    });

    test('rechaza 0 o más de 3 citas', () {
      expect(() => BibleQuestion.fromJson(base()..['references'] = <String>[]),
          throwsFormatException);
      expect(
          () => BibleQuestion.fromJson(
              base()..['references'] = ['a', 'b', 'c', 'd']),
          throwsFormatException);
    });

    test('toJson omite explanation cuando es null y la incluye si existe', () {
      expect(BibleQuestion.fromJson(base()).toJson().containsKey('explanation'),
          false);
      expect(
        BibleQuestion.fromJson(base()..['explanation'] = 'E')
            .toJson()['explanation'],
        'E',
      );
    });
  });
}
