import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/app_user.dart';
import '../models/difficulty_level.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';
import 'test_controller.dart';

/// Estado de la sincronización con la nube, para dar feedback visual.
enum SyncStatus {
  /// Sin sesión: solo se guarda localmente (no es un error).
  offline,

  /// Subiendo cambios a la nube.
  syncing,

  /// Último guardado en la nube exitoso.
  synced,

  /// Falló el último intento (se conserva el guardado local).
  error,
}

/// Estado global y persistente: nivel, puntaje ponderado e historiales
/// (correctas / repasar). Es **offline-first**: la fuente local
/// (shared_preferences) siempre funciona; si hay sesión iniciada, sincroniza
/// con Firestore (`users/{uid}`) por "última escritura gana".
///
/// Reglas de puntaje:
///  - Puntaje PONDERADO: cada acierto al PRIMER intento suma los puntos de su
///    nivel; una sola vez por pregunta (sin "farmear").
///  - "Repasar" guarda toda pregunta fallada al menos una vez (marca permanente
///    hasta un reinicio total).
///  - Cambiar de nivel o "Reiniciar todo el puntaje" deja todo en cero.
class AppState extends ChangeNotifier {
  AppState(this._storage);

  final StorageService _storage;

  DifficultyLevel _level = DifficultyLevel.entrada;
  final Set<String> _correctFirstTryIds = {};
  final Set<String> _reviewIds = {};
  int _score = 0;
  int _updatedAt = 0;
  bool _loaded = false;
  final Completer<void> _ready = Completer<void>();

  // Sincronización con la nube (solo si hay sesión).
  FirestoreService? _cloud;
  String? _uid;
  AppUser? _profile;

  SyncStatus _syncStatus = SyncStatus.offline;

  DifficultyLevel get level => _level;
  bool get isLoaded => _loaded;

  /// `true` si hay sesión iniciada (el progreso se replica en la nube).
  bool get isSignedIn => _uid != null;

  /// Estado del último guardado en la nube (para feedback en la UI).
  SyncStatus get syncStatus => _syncStatus;

  /// Puntaje acumulado ponderado por nivel.
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
    _updatedAt = snap.updatedAt;
    _correctFirstTryIds
      ..clear()
      ..addAll(snap.correctFirstTryIds);
    _reviewIds
      ..clear()
      ..addAll(snap.reviewIds);
    _loaded = true;
    if (!_ready.isCompleted) _ready.complete();
    notifyListeners();
  }

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

  Future<void> resetAllScore() async {
    _score = 0;
    _correctFirstTryIds.clear();
    _reviewIds.clear();
    await _persist();
    notifyListeners();
  }

  /// Integra el resultado de un test finalizado.
  Future<void> commitTestResult(TestResult result) async {
    for (final q in result.failed) {
      _reviewIds.add(q.id);
      if (_correctFirstTryIds.remove(q.id)) {
        _score -= q.difficulty.points;
      }
    }
    for (final q in result.firstTryCorrect) {
      if (!_reviewIds.contains(q.id) && _correctFirstTryIds.add(q.id)) {
        _score += q.difficulty.points;
      }
    }
    if (_score < 0) _score = 0;
    await _persist();
    notifyListeners();
  }

  // ---- Sincronización con la nube -----------------------------------------

  /// Reacciona a cambios de sesión (lo invoca el provider). Al iniciar sesión,
  /// reconcilia local↔nube; al cerrar, vuelve a modo solo-local.
  void onAuthChanged(AppUser? user) {
    if (user == null) {
      _cloud = null;
      _uid = null;
      _profile = null;
      _setSync(SyncStatus.offline);
      return;
    }
    if (_uid == user.uid) {
      _profile = user; // misma sesión: nada que reconciliar
      return;
    }
    _reconcile(user); // sesión nueva
  }

  Future<void> _reconcile(AppUser user) async {
    await _ready.future; // asegura que el progreso local ya se cargó
    final previousUid = _uid;
    FirestoreService cloud;
    try {
      cloud = _cloud ?? FirestoreService.holyapp();
    } catch (e) {
      debugPrint('Firestore no disponible: $e');
      return;
    }
    _cloud = cloud;
    _uid = user.uid;
    _profile = user;

    try {
      final remote = await cloud.loadProgress(user.uid);
      final remoteUpdated = (remote?['updatedAt'] as num?)?.toInt() ?? -1;

      if (remote != null && remoteUpdated > _updatedAt) {
        // La nube es más reciente: adoptarla y cachear localmente.
        _adoptRemote(remote);
        await _storage.save(_snapshot());
        notifyListeners();
      } else if (remote == null &&
          previousUid != null &&
          previousUid != user.uid) {
        // Otro usuario distinto sin datos en la nube: no heredar el progreso
        // anterior; empezar limpio.
        _level = DifficultyLevel.entrada;
        _score = 0;
        _correctFirstTryIds.clear();
        _reviewIds.clear();
        _updatedAt = DateTime.now().millisecondsSinceEpoch;
        await _storage.save(_snapshot());
        notifyListeners();
        _pushCloud();
      } else {
        // Invitado que inicia sesión (reclama su progreso) o nube más antigua.
        _pushCloud();
      }
    } catch (e) {
      debugPrint('Error reconciliando con la nube: $e');
    }
  }

  /// Borra los datos del usuario en la nube (progreso + ranking). El llamador
  /// debe estar con sesión iniciada.
  Future<void> deleteCloudData() async {
    final cloud = _cloud;
    final uid = _uid;
    if (cloud == null || uid == null) return;
    await cloud.deleteUserData(uid);
  }

  void _adoptRemote(Map<String, dynamic> r) {
    _level = DifficultyLevel.fromId(r['level'] as String? ?? _level.id);
    _score = (r['score'] as num?)?.toInt() ?? 0;
    _correctFirstTryIds
      ..clear()
      ..addAll(((r['correctFirstTryIds'] as List?) ?? const []).cast<String>());
    _reviewIds
      ..clear()
      ..addAll(((r['reviewIds'] as List?) ?? const []).cast<String>());
    _updatedAt = (r['updatedAt'] as num?)?.toInt() ?? _updatedAt;
  }

  void _pushCloud() {
    final cloud = _cloud;
    final uid = _uid;
    if (cloud == null || uid == null) return;
    _setSync(SyncStatus.syncing);
    // Progreso privado + entrada pública del ranking (nombre, foto y puntaje).
    Future.wait([
      cloud.saveProgress(uid, _cloudData()),
      cloud.saveLeaderboard(uid, {
        'displayName': _profile?.displayName ?? 'Anónimo',
        'photoUrl': _profile?.photoUrl,
        'score': _score,
        'updatedAt': _updatedAt,
      }),
    ]).then((_) => _setSync(SyncStatus.synced)).catchError((e) {
      debugPrint('Error subiendo a la nube: $e');
      _setSync(SyncStatus.error);
    });
  }

  void _setSync(SyncStatus status) {
    if (_syncStatus == status) return;
    _syncStatus = status;
    notifyListeners();
  }

  Map<String, dynamic> _cloudData() => {
        'level': _level.id,
        'score': _score,
        'correctFirstTryIds': _correctFirstTryIds.toList(),
        'reviewIds': _reviewIds.toList(),
        'updatedAt': _updatedAt,
        if (_profile != null) ...{
          'displayName': _profile!.displayName,
          'photoUrl': _profile!.photoUrl,
          'email': _profile!.email,
        },
      };

  ProgressSnapshot _snapshot() => ProgressSnapshot(
        level: _level,
        score: _score,
        correctFirstTryIds: _correctFirstTryIds.toList(),
        reviewIds: _reviewIds.toList(),
        updatedAt: _updatedAt,
      );

  /// Guarda local (siempre) y empuja a la nube si hay sesión.
  Future<void> _persist() async {
    _updatedAt = DateTime.now().millisecondsSinceEpoch;
    await _storage.save(_snapshot());
    _pushCloud();
  }
}
