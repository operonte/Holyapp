# HolyApp · Trivia Bíblica y Teológica (Flutter)

App de aprendizaje bíblico/teológico mediante trivia con el método de **fallo y
corrección**. **Offline-first**: las preguntas viven en `assets/` como JSON y el
progreso se guarda local; con login opcional se sincroniza en la nube.

## Funcionalidades

- **7 niveles** (Entrada → Básico → Medio → Avanzado → Pastorado → Teología →
  Evangelista) con **acceso en cascada**: tu nivel desbloquea y mezcla todos los
  inferiores.
- **Puntaje ponderado** por nivel (1 a 5 pts por acierto al primer intento).
- **Cola dinámica**: una pregunta fallada vuelve al final hasta acertarse.
- **Explicación + citas** tras cada respuesta (las 287 preguntas tienen
  explicación didáctica).
- **Historial**: "Respuestas correctas" y "Repasar".
- **Opción**: repetir preguntas o verlas una sola vez (desde que se aciertan).
- **Login con Google opcional** (Firebase Auth) → sincroniza progreso, perfil y
  **ranking global**. Se puede jugar como invitado.
- Tema claro/oscuro, splash, onboarding, vibración háptica.

## Arquitectura (por capas, `provider`)

```
lib/
├── main.dart                 # Bootstrap, Firebase.initializeApp, MultiProvider, tema
├── firebase_options.dart     # Config de cliente Firebase (generado por flutterfire)
├── models/                   # Datos puros (BibleQuestion, DifficultyLevel, TestLength, AppUser)
├── services/                 # question_service (JSON+caché), storage_service (prefs),
│                             #   firestore_service (progreso + leaderboard)
├── state/                    # app_state (puntaje/sync), test_controller (cola dinámica),
│                             #   auth_controller (Google), settings_controller (prefs)
├── widgets/                  # feedback_panel, references_list, question_history_view
└── views/                    # home, test, results, correct, review, settings, ranking
assets/questions/<nivel>.json # Un archivo por nivel (lazy-load + caché)
docs/guia_niveles.md          # Guía de autoría de preguntas (temas y reglas por nivel)
```

## Datos en la nube (Firebase)

- **Offline-first**: `shared_preferences` es la fuente local; al iniciar sesión se
  reconcilia con Firestore (`users/{uid}`) por *última escritura gana*.
- **Ranking** en colección pública `leaderboard/{uid}` (solo nombre, foto y
  puntaje — sin datos privados).
- **Reglas de seguridad** en [`firestore.rules`](firestore.rules): cada usuario
  solo lee/escribe su documento; el ranking es de solo lectura para autenticados.

### Nota de seguridad

Las claves de `firebase_options.dart` y `android/app/google-services.json` son
**config de cliente, no secretos** (Google las diseña para ir embebidas). La
protección de los datos son las **reglas de Firestore** + Auth. Endurecimiento
recomendado en producción:

- Restringir la API key en Google Cloud (referrers HTTP para web, firma de app
  para Android).
- Para login con Google en **Android**, añadir la huella **SHA-1** del keystore
  en la consola de Firebase.

## Correr

```bash
flutter pub get
flutter test            # pruebas de la cola dinámica y el puntaje
flutter run -d chrome   # web; o un emulador/dispositivo Android
```

## Build de producción (Android)

```bash
flutter build apk --release            # APK universal
flutter build apk --release --split-per-abi   # APKs más livianos por arquitectura
```
> El APK release se firma con la clave de depuración salvo que configures un
> keystore propio (`android/key.properties`). Para Google Play, usa un keystore
> de publicación.

## Licencia

El **código** de este proyecto se publica bajo licencia [MIT](LICENSE).

El **contenido del banco de preguntas** (textos en `assets/questions/`, citas
bíblicas y explicaciones) es material educativo del autor; reutilízalo solo con
fines no comerciales y verificando la exactitud bíblica antes de redistribuir.

## Generado parcialmente con [Claude Code](https://claude.com/claude-code).
