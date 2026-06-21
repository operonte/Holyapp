import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../models/bible_question.dart';
import '../models/difficulty_level.dart';

/// Carga y parsea el banco de preguntas desde los assets JSON.
///
/// - Es asíncrono: nunca bloquea el hilo de UI.
/// - Cachea por nivel: el JSON de un nivel se lee y parsea una sola vez por
///   sesión. Como solo se necesita el nivel que se está jugando, la memoria
///   usada es ~400 preguntas, no las 2000.
class QuestionService {
  QuestionService._();
  static final QuestionService instance = QuestionService._();

  final Map<DifficultyLevel, List<BibleQuestion>> _cache = {};

  /// Devuelve las preguntas de un nivel. Lee del asset solo la primera vez.
  Future<List<BibleQuestion>> loadLevel(DifficultyLevel level) async {
    final cached = _cache[level];
    if (cached != null) return cached;

    final raw = await rootBundle.loadString(level.asset);
    final decoded = json.decode(raw) as Map<String, dynamic>;
    final items = decoded['questions'] as List;

    final questions = items
        .map((item) => BibleQuestion.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);

    _cache[level] = questions;
    return questions;
  }

  /// Devuelve la unión de preguntas de todos los niveles desbloqueados por
  /// [tier] (acceso en cascada: niveles 1..N). Cada nivel se lee/cachea una
  /// sola vez. El test mezcla todas estas preguntas; cada una conserva su
  /// nivel (y por tanto su valor en puntos).
  Future<List<BibleQuestion>> loadUpTo(DifficultyLevel tier) async {
    final all = <BibleQuestion>[];
    for (final level in tier.unlockedLevels) {
      all.addAll(await loadLevel(level));
    }
    return all;
  }

  /// Libera la caché (útil si la memoria es crítica al cambiar de nivel).
  void evict([DifficultyLevel? level]) {
    if (level == null) {
      _cache.clear();
    } else {
      _cache.remove(level);
    }
  }
}
