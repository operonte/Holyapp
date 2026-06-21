import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/difficulty_level.dart';

/// Foto persistida del progreso global de la app.
class ProgressSnapshot {
  const ProgressSnapshot({
    required this.level,
    required this.score,
    required this.correctFirstTryIds,
    required this.reviewIds,
  });

  final DifficultyLevel level;
  final int score;

  /// IDs acertadas al primer intento (pantalla "Respuestas correctas").
  final List<String> correctFirstTryIds;

  /// IDs falladas al menos una vez (pantalla "Repasar").
  final List<String> reviewIds;

  static const empty = ProgressSnapshot(
    level: DifficultyLevel.entrada,
    score: 0,
    correctFirstTryIds: [],
    reviewIds: [],
  );
}

/// Persiste el progreso global usando shared_preferences (todo offline).
class StorageService {
  StorageService._();
  static final StorageService instance = StorageService._();

  static const _kLevel = 'holy.level';
  static const _kScore = 'holy.score';
  static const _kCorrect = 'holy.correctFirstTry';
  static const _kReview = 'holy.review';

  Future<ProgressSnapshot> load() async {
    final prefs = await SharedPreferences.getInstance();
    return ProgressSnapshot(
      level: DifficultyLevel.fromId(
        prefs.getString(_kLevel) ?? DifficultyLevel.entrada.id,
      ),
      score: prefs.getInt(_kScore) ?? 0,
      correctFirstTryIds: _decodeList(prefs.getString(_kCorrect)),
      reviewIds: _decodeList(prefs.getString(_kReview)),
    );
  }

  Future<void> save(ProgressSnapshot snapshot) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLevel, snapshot.level.id);
    await prefs.setInt(_kScore, snapshot.score);
    await prefs.setString(_kCorrect, json.encode(snapshot.correctFirstTryIds));
    await prefs.setString(_kReview, json.encode(snapshot.reviewIds));
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kScore);
    await prefs.remove(_kCorrect);
    await prefs.remove(_kReview);
  }

  List<String> _decodeList(String? raw) {
    if (raw == null || raw.isEmpty) return [];
    return (json.decode(raw) as List).cast<String>();
  }
}
