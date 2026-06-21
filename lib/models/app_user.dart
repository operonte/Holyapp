/// Usuario autenticado (vía Google). Modelo agnóstico de Firebase para que la
/// UI y el estado no dependan del backend de autenticación.
class AppUser {
  const AppUser({
    required this.uid,
    required this.displayName,
    this.email,
    this.photoUrl,
  });

  final String uid;
  final String displayName;
  final String? email;
  final String? photoUrl;
}
