import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/app_user.dart';

/// Controla la sesión del usuario. El login es **opcional**: por defecto se
/// juega como invitado y el progreso se guarda localmente. Iniciar sesión con
/// Google permite sincronizar el progreso en la nube.
///
/// Usa solo `firebase_auth`: en web abre un popup de Google; en móvil usa el
/// flujo OAuth del proveedor. La sesión se refleja escuchando
/// [FirebaseAuth.authStateChanges].
class AuthController extends ChangeNotifier {
  AuthController() {
    try {
      _auth = FirebaseAuth.instance;
      _auth!.authStateChanges().listen(_onAuthChanged);
      _onAuthChanged(_auth!.currentUser);
    } catch (_) {
      // Firebase no inicializado: queda en modo invitado.
      _auth = null;
    }
  }

  FirebaseAuth? _auth;
  AppUser? _user;

  AppUser? get currentUser => _user;
  bool get isSignedIn => _user != null;

  /// `true` si Firebase está disponible (la app puede ofrecer login).
  bool get isAvailable => _auth != null;

  void _onAuthChanged(User? user) {
    _user = user == null
        ? null
        : AppUser(
            uid: user.uid,
            displayName:
                (user.displayName?.isNotEmpty ?? false) ? user.displayName! : 'Usuario',
            email: user.email,
            photoUrl: user.photoURL,
          );
    notifyListeners();
  }

  /// Inicia sesión con Google. Devuelve `true` si tuvo éxito.
  Future<bool> signInWithGoogle() async {
    final auth = _auth;
    if (auth == null) return false;
    try {
      final provider = GoogleAuthProvider();
      if (kIsWeb) {
        await auth.signInWithPopup(provider);
      } else {
        await auth.signInWithProvider(provider);
      }
      return auth.currentUser != null;
    } catch (e) {
      debugPrint('Error en login con Google: $e');
      return false;
    }
  }

  /// Cierra la sesión y vuelve al modo invitado.
  Future<void> signOut() async {
    await _auth?.signOut();
  }
}
