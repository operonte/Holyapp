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

  /// Inicia sesión con Google. Devuelve `null` si tuvo éxito, o un mensaje de
  /// error legible (con la causa real) para mostrar al usuario.
  Future<String?> signInWithGoogle() async {
    final auth = _auth;
    if (auth == null) {
      return 'El servicio de cuentas no está disponible en este momento.';
    }
    try {
      final provider = GoogleAuthProvider();
      if (kIsWeb) {
        await auth.signInWithPopup(provider);
      } else {
        await auth.signInWithProvider(provider);
      }
      return auth.currentUser != null ? null : 'No se pudo iniciar sesión.';
    } on FirebaseAuthException catch (e) {
      debugPrint('Error en login con Google: ${e.code} — ${e.message}');
      return _friendlyAuthError(e);
    } catch (e) {
      debugPrint('Error inesperado en login con Google: $e');
      return 'No se pudo iniciar sesión. Revisa tu conexión e inténtalo de nuevo.';
    }
  }

  /// Traduce los códigos de FirebaseAuth a mensajes claros (y accionables).
  String _friendlyAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'popup-closed-by-user':
      case 'cancelled-popup-request':
      case 'user-cancelled':
        return 'Cancelaste el inicio de sesión.';
      case 'popup-blocked':
        return 'El navegador bloqueó la ventana de Google. Permite las '
            'ventanas emergentes e inténtalo de nuevo.';
      case 'unauthorized-domain':
        return 'Este dominio no está autorizado en Firebase '
            '(Authentication → Settings → Dominios autorizados).';
      case 'operation-not-allowed':
        return 'El proveedor de Google no está habilitado en Firebase '
            '(Authentication → Sign-in method).';
      case 'network-request-failed':
        return 'Sin conexión. Revisa tu red e inténtalo de nuevo.';
      case 'account-exists-with-different-credential':
        return 'Ya existe una cuenta con ese correo usando otro método.';
      default:
        return 'No se pudo iniciar sesión (${e.code}).';
    }
  }

  /// Cierra la sesión y vuelve al modo invitado.
  Future<void> signOut() async {
    await _auth?.signOut();
  }

  /// Elimina la cuenta de Firebase Auth del usuario. Devuelve `null` si tuvo
  /// éxito, o un mensaje de error legible. Borra primero los datos en la nube.
  Future<String?> deleteAccount() async {
    final user = _auth?.currentUser;
    if (user == null) return 'No hay una sesión activa.';
    try {
      await user.delete();
      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        return 'Por seguridad, vuelve a iniciar sesión y reinténtalo.';
      }
      return e.message ?? 'No se pudo eliminar la cuenta.';
    } catch (e) {
      return 'No se pudo eliminar la cuenta.';
    }
  }
}
