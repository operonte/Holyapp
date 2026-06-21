import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../models/bible_question.dart';
import '../models/difficulty_level.dart';
import '../models/test_length.dart';

/// Fase del test, para que la UI sepa qué mostrar.
enum TestPhase { answering, feedback, finished }

/// Resultado de un test, listo para integrarse en [AppState].
///
/// Lleva las PREGUNTAS (no solo sus IDs) porque el puntaje es ponderado: cada
/// acierto vale según el nivel de su pregunta, así que [AppState] necesita el
/// nivel para sumar/restar los puntos correctos.
class TestResult {
  const TestResult({
    required this.firstTryCorrect,
    required this.failed,
  });

  /// Preguntas acertadas al primer intento (suman los puntos de su nivel).
  final List<BibleQuestion> firstTryCorrect;

  /// Preguntas falladas al menos una vez (van a "Repasar").
  final List<BibleQuestion> failed;

  Set<String> get firstTryCorrectIds =>
      firstTryCorrect.map((q) => q.id).toSet();

  Set<String> get failedIds => failed.map((q) => q.id).toSet();

  /// Puntos ganados en este test (suma ponderada por nivel).
  int get pointsEarned =>
      firstTryCorrect.fold(0, (sum, q) => sum + q.difficulty.points);
}

/// Controla un único test activo, incluida la COLA DINÁMICA de fallo y
/// corrección.
///
/// Regla central: una pregunta solo abandona la cola cuando se responde bien.
/// Si se falla, se mueve al final de la cola y reaparecerá más adelante. El
/// test no termina hasta vaciar la cola (modos 10/20) o hasta que el usuario
/// lo finaliza (modo infinito).
class TestController extends ChangeNotifier {
  TestController({
    required this.level,
    required this.length,
    required List<BibleQuestion> bank,
  }) {
    _start(bank);
  }

  final DifficultyLevel level;
  final TestLength length;

  /// Cola activa de preguntas pendientes (el frente es la pregunta actual).
  final Queue<BibleQuestion> _queue = Queue<BibleQuestion>();

  /// Preguntas aún no extraídas del banco (relevante en modo infinito).
  final List<BibleQuestion> _pool = [];

  // Se rastrean las PREGUNTAS (mapeadas por id) para conocer su nivel y
  // calcular el puntaje ponderado.
  final Map<String, BibleQuestion> _failed = {};
  final Map<String, BibleQuestion> _firstTryCorrect = {};

  /// Tamaño de la ventana activa en modo infinito.
  static const int _infiniteWindow = 10;

  TestPhase _phase = TestPhase.answering;
  int? _selectedIndex;
  bool _lastWasCorrect = false;

  /// Pregunta recién respondida. Se conserva durante la fase de feedback
  /// porque para entonces ya salió del frente de la cola (acierto: removida;
  /// fallo: enviada al final). La UI del feedback debe mostrar ESTA pregunta,
  /// no la que quedó al frente.
  BibleQuestion? _answered;

  // ---- Getters de UI -------------------------------------------------------

  TestPhase get phase => _phase;
  int? get selectedIndex => _selectedIndex;
  bool get lastWasCorrect => _lastWasCorrect;

  /// Pregunta que la UI debe mostrar ahora mismo:
  ///  - en fase de feedback, la recién respondida ([_answered]);
  ///  - al responder, la del frente de la cola.
  BibleQuestion? get current => _phase == TestPhase.feedback
      ? _answered
      : (_queue.isEmpty ? null : _queue.first);

  /// Citas de respaldo de la pregunta recién respondida (para el feedback).
  List<String> get currentReferences => _answered?.references ?? const [];

  /// Preguntas pendientes en la cola.
  int get remaining => _queue.length;

  /// Aciertos limpios (primer intento) acumulados en este test.
  int get firstTryCorrectCount => _firstTryCorrect.length;

  /// Cuántas preguntas distintas se han fallado en este test.
  int get failedCount => _failed.length;

  /// Puntos ganados hasta ahora en este test (ponderados por nivel).
  int get pointsEarned =>
      _firstTryCorrect.values.fold(0, (sum, q) => sum + q.difficulty.points);

  bool get isInfinite => length.isInfinite;

  /// En modo infinito el usuario puede finalizar en cualquier momento.
  bool get canFinishEarly => isInfinite && _phase != TestPhase.finished;

  // ---- Ciclo de vida -------------------------------------------------------

  void _start(List<BibleQuestion> bank) {
    final shuffled = List<BibleQuestion>.of(bank)..shuffle();

    if (length.isInfinite) {
      _pool.addAll(shuffled);
      _drawUpTo(_infiniteWindow);
    } else {
      final take = length.count!.clamp(0, shuffled.length);
      _queue.addAll(shuffled.take(take));
      _pool.addAll(shuffled.skip(take)); // reserva por si acaso
    }

    if (_queue.isEmpty) _phase = TestPhase.finished;
  }

  void _drawUpTo(int windowSize) {
    while (_queue.length < windowSize && _pool.isNotEmpty) {
      _queue.addLast(_pool.removeAt(0));
    }
  }

  // ---- Interacción ---------------------------------------------------------

  /// Responde la pregunta actual con la opción [index] (0..3).
  void answer(int index) {
    if (_phase != TestPhase.answering || _queue.isEmpty) return;

    final question = _queue.removeFirst();
    _answered = question;
    _selectedIndex = index;
    _lastWasCorrect = question.isCorrect(index);

    if (_lastWasCorrect) {
      // Solo cuenta como acierto de primer intento si nunca se falló antes.
      if (!_failed.containsKey(question.id)) {
        _firstTryCorrect[question.id] = question;
      }
      // Modo infinito: rellena la ventana al retirar una pregunta resuelta.
      if (length.isInfinite) _drawUpTo(_infiniteWindow);
    } else {
      // Fallo: pierde el punto y vuelve al final de la cola.
      _failed[question.id] = question;
      _firstTryCorrect.remove(question.id);
      _queue.addLast(question);
    }

    _phase = TestPhase.feedback;
    notifyListeners();
  }

  /// Avanza tras leer el feedback (las citas bíblicas).
  void next() {
    if (_phase != TestPhase.feedback) return;
    _selectedIndex = null;
    _answered = null;
    _phase = _queue.isEmpty ? TestPhase.finished : TestPhase.answering;
    notifyListeners();
  }

  /// Finaliza anticipadamente (solo modo infinito).
  void finishNow() {
    if (!canFinishEarly) return;
    _phase = TestPhase.finished;
    notifyListeners();
  }

  /// Resultado para integrar en el estado global al terminar.
  TestResult buildResult() => TestResult(
        firstTryCorrect: _firstTryCorrect.values.toList(),
        failed: _failed.values.toList(),
      );
}
