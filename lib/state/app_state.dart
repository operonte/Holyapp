import 'package:flutter/foundation.dart';

import '../models/difficulty_level.dart';
import '../services/storage_service.dart';
import 'test_controller.dart';

/// Estado global y persistente de la app: nivel actual, puntaje acumulado y
/// las dos pantallas de historial (correctas / repasar).
///
/// Reglas de puntaje implementadas aquí:
///  - El puntaje es PONDERADO: cada acierto al PRIMER intento suma los puntos
///    de su nivel (entrada/básico=1, medio/avanzado=2, pastorado=3, teología=4).
///    Se cuenta una sola vez por pregunta, así no se puede "farmear".
///  - "Repasar" guarda toda pregunta fallada al menos una vez. Esa marca es
///    permanente: una pregunta en Repasar ya no otorga puntos aunque se acierte
///    después, hasta que se reinicie todo (regla de desafío).
///  - Cambiar de nivel O pulsar "Reiniciar todo el puntaje" borra puntaje e
///    historial y deja todo en cero.
class AppState extends ChangeNotifier {
  AppState(this._storage);

  final StorageService _storage;

  DifficultyLevel _level = DifficultyLevel.entrada;
  final Set<String> _correctFirstTryIds = {};
  final Set<String> _reviewIds = {};
  int _score = 0;
  bool _loaded = false;

  DifficultyLevel get level => _level;
  bool get isLoaded => _loaded;

  /// Puntaje acumulado ponderado por nivel. Se mantiene incrementalmente y se
  /// persiste; sube/baja al integrar cada test.
  int get score => _score;

  /// Pantalla "Respuestas correctas" (acertadas al primer intento).
  List<String> get correctFirstTryIds => _correctFirstTryIds.toList();

  /// Pantalla "Repasar" (falladas al menos una vez).
  List<String> get reviewIds => _reviewIds.toList();

  /// Carga el progreso persistido al iniciar la app.
  Future<void> init() async {
    final snap = await _storage.load();
    _level = snap.level;
    _score = snap.score;
    _correctFirstTryIds
      ..clear()
      ..addAll(snap.correctFirstTryIds);
    _reviewIds
      ..clear()
      ..addAll(snap.reviewIds);
    _loaded = true;
    notifyListeners();
  }

  /// Cambia de nivel. Si el nivel es distinto, REINICIA puntaje e historial
  /// (regla de desafío máximo: subir de dificultad cuesta empezar de cero).
  /// Devuelve true si hubo reinicio.
  Future<bool> changeLevel(DifficultyLevel newLevel) async {
    if (newLevel == _level) return false;
    _level = newLevel;
    _score = 0;
    _correctFirstTryIds.clear();
    _reviewIds.clear();
    await _persist();
    notifyListeners();
    return true;
  }

  /// Botón manual "Reiniciar todo el puntaje": vuelve todo a cero conservando
  /// el nivel actual. Única forma de recuperar los puntos perdidos en Repasar.
  Future<void> resetAllScore() async {
    _score = 0;
    _correctFirstTryIds.clear();
    _reviewIds.clear();
    await _persist();
    notifyListeners();
  }

  /// Integra el resultado de un test finalizado en el estado global.
  Future<void> commitTestResult(TestResult result) async {
    // 1) Las falladas entran a Repasar de forma permanente. Si tenían punto,
    //    lo pierden (se resta el valor de su nivel).
    for (final q in result.failed) {
      _reviewIds.add(q.id);
      if (_correctFirstTryIds.remove(q.id)) {
        _score -= q.difficulty.points;
      }
    }
    // 2) Los aciertos al primer intento suman los puntos de su nivel, solo si
    //    no están marcados para repasar y no se habían contado antes.
    for (final q in result.firstTryCorrect) {
      if (!_reviewIds.contains(q.id) && _correctFirstTryIds.add(q.id)) {
        _score += q.difficulty.points;
      }
    }
    if (_score < 0) _score = 0;
    await _persist();
    notifyListeners();
  }

  Future<void> _persist() {
    return _storage.save(
      ProgressSnapshot(
        level: _level,
        score: _score,
        correctFirstTryIds: _correctFirstTryIds.toList(),
        reviewIds: _reviewIds.toList(),
      ),
    );
  }
}
