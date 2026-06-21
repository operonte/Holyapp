import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

/// Acceso a Firestore (base con nombre **"holyapp"**, no la `(default)`).
///
/// Guarda el progreso del usuario en `users/{uid}` y expone el ranking global.
class FirestoreService {
  FirestoreService(this._db);

  /// Crea el servicio apuntando a la base "holyapp". Lanza si Firebase no está
  /// inicializado (el llamador debe capturarlo para seguir offline).
  factory FirestoreService.holyapp() => FirestoreService(
        FirebaseFirestore.instanceFor(
          app: Firebase.app(),
          databaseId: 'holyapp',
        ),
      );

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection('users');

  /// Colección PÚBLICA del ranking: solo nombre, foto y puntaje (sin datos
  /// privados como el correo). Lectura para usuarios autenticados; escritura
  /// solo del propio usuario.
  CollectionReference<Map<String, dynamic>> get _leaderboard =>
      _db.collection('leaderboard');

  /// Lee el documento de progreso del usuario, o null si no existe.
  Future<Map<String, dynamic>?> loadProgress(String uid) async {
    final doc = await _users.doc(uid).get();
    return doc.data();
  }

  /// Crea/actualiza el progreso del usuario (merge, no borra otros campos).
  Future<void> saveProgress(String uid, Map<String, dynamic> data) {
    return _users.doc(uid).set(data, SetOptions(merge: true));
  }

  /// Publica/actualiza la entrada del usuario en el ranking público.
  Future<void> saveLeaderboard(String uid, Map<String, dynamic> data) {
    return _leaderboard.doc(uid).set(data, SetOptions(merge: true));
  }

  /// Ranking global: top de usuarios por puntaje (en vivo).
  Stream<List<RankEntry>> topScores({int limit = 100}) {
    return _leaderboard
        .orderBy('score', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => RankEntry(
                  uid: d.id,
                  name: (d.data()['displayName'] as String?) ?? 'Anónimo',
                  score: (d.data()['score'] as num?)?.toInt() ?? 0,
                  photoUrl: d.data()['photoUrl'] as String?,
                ))
            .toList());
  }
}

/// Una fila del ranking global.
class RankEntry {
  const RankEntry({
    required this.uid,
    required this.name,
    required this.score,
    this.photoUrl,
  });

  final String uid;
  final String name;
  final int score;
  final String? photoUrl;
}
