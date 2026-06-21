# HolyApp · Trivia Bíblica y Teológica (Flutter / Android, offline)

App de aprendizaje bíblico mediante trivia con el método de **fallo y corrección**.
100% offline: las preguntas viven en `assets/` como JSON y el progreso se guarda
con `shared_preferences`.

## Arquitectura (Clean / por capas)

```
lib/
├── main.dart                  # Bootstrap + Provider(AppState) + tema Material 3
├── models/                    # Datos puros e inmutables
│   ├── bible_question.dart    # BibleQuestion (id, texto, 4 opciones, correcta, refs 1–3)
│   ├── difficulty_level.dart  # enum DifficultyLevel (5 niveles) + ruta de su asset
│   └── test_length.dart       # enum TestLength: 10 / 20 / infinito
├── services/                  # Acceso a datos (sin UI)
│   ├── question_service.dart  # Carga + parseo asíncrono del JSON, con caché por nivel
│   └── storage_service.dart   # Persistencia del puntaje e historial (offline)
├── state/                     # Lógica / state management (ChangeNotifier + Provider)
│   ├── app_state.dart         # Puntaje global, nivel, historiales, reglas de reinicio
│   └── test_controller.dart   # COLA DINÁMICA de fallo y corrección de un test activo
├── widgets/
│   ├── feedback_panel.dart    # "¡Acertaste!" / "Lo siento, para la próxima" + citas
│   └── references_list.dart   # Render de las citas bíblicas (1–3)
└── views/                     # Pantallas Material Design
    ├── home_screen.dart       # Nivel + longitud + accesos a historial + reset
    ├── test_screen.dart       # Pregunta, opciones, feedback, progreso
    ├── results_screen.dart    # Resumen del test
    └── history_screen.dart    # "Respuestas correctas" y "Repasar" (reutilizable)

assets/questions/              # Un archivo por nivel (lazy-load: solo se carga el que se juega)
├── entrada.json  basico.json  medio.json  avanzado.json  teologia.json
```

**Por qué las preguntas NO están en Dart:** se leen de JSON externo de forma
asíncrona (`rootBundle.loadString` → `json.decode`). El `QuestionService` cachea
por nivel, así en memoria solo hay ~400 preguntas (el nivel jugado), no las 2000.

## Esquema del JSON

Cada archivo de nivel:

```json
{
  "level": "entrada",
  "questions": [
    {
      "id": "ent-0001",
      "text": "¿Quién construyó el arca para sobrevivir al diluvio?",
      "options": ["Moisés", "Noé", "Abraham", "David"],
      "correctIndex": 1,
      "difficulty": "entrada",
      "references": ["Génesis 6:13-14", "Génesis 7:1"]
    }
  ]
}
```

`difficulty` debe coincidir con el `name` del enum: `entrada`, `basico`, `medio`,
`avanzado`, `teologia`. `options` siempre 4; `references` entre 1 y 3
(validado en `BibleQuestion.fromJson`).

### Escalar a 2000 preguntas (400 por nivel)

Los 5 archivos incluidos traen ejemplos. Rellena cada uno hasta 400 entradas con
IDs únicos (`ent-0001..ent-0400`, `bas-0001..`, etc.). No hay que tocar código:
el `QuestionService` toma todas las del archivo y, en modo 10/20, baraja y
extrae las que pida la longitud.

## Lógica de la cola dinámica (fallo y corrección)

Implementada en `TestController` (`state/test_controller.dart`):

- El frente de la cola es la pregunta actual.
- **Acierto** → la pregunta sale de la cola. Si nunca se había fallado, cuenta
  como acierto de primer intento (candidata a punto).
- **Fallo** → la pregunta se mueve **al final** de la cola y reaparecerá más
  tarde. Pierde la opción de punto en este test.
- El test no termina hasta **vaciar la cola** (modos 10/20). En **modo infinito**
  se mantiene una ventana de 10 preguntas que se rellena desde el banco; el
  usuario finaliza con el botón "Finalizar".

## Reglas de puntaje (desafío estricto)

En `AppState`:

- **Puntaje = nº de preguntas únicas acertadas al primer intento** y nunca
  falladas (no se puede farmear la misma pregunta).
- **"Repasar"** guarda toda pregunta fallada al menos una vez; la marca es
  permanente: no vuelve a dar puntos aunque se acierte después.
- **Cambiar de nivel** (regla de desafío máximo) reinicia puntaje **e** historial
  a cero. Se confirma con diálogo.
- **"Reiniciar todo el puntaje"** (botón manual) es la única forma de recuperar
  los puntos perdidos en "Repasar": vuelve todo a cero conservando el nivel.

## Correr

```bash
flutter pub get
flutter test       # pruebas de la cola dinámica y el puntaje
flutter run        # en un dispositivo/emulador Android
```
