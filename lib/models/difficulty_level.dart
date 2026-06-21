/// Los niveles del banco de preguntas.
///
/// El orden del enum ES la jerarquía de dificultad (de menor a mayor).
/// Cada nivel tiene su propio archivo JSON en assets, de modo que solo se
/// carga en memoria el nivel que se está jugando.
enum DifficultyLevel {
  entrada(
    label: 'Nivel de entrada',
    asset: 'assets/questions/entrada.json',
  ),
  basico(
    label: 'Básico',
    asset: 'assets/questions/basico.json',
  ),
  medio(
    label: 'Medio',
    asset: 'assets/questions/medio.json',
  ),
  avanzado(
    label: 'Avanzado',
    asset: 'assets/questions/avanzado.json',
  ),
  pastorado(
    label: 'Pastorado',
    asset: 'assets/questions/pastorado.json',
  ),
  teologia(
    label: 'Teología',
    asset: 'assets/questions/teologia.json',
  ),
  evangelista(
    label: 'Evangelista',
    asset: 'assets/questions/evangelista.json',
  );

  const DifficultyLevel({required this.label, required this.asset});

  /// Nombre legible para la UI.
  final String label;

  /// Ruta del archivo JSON en assets que contiene las 400 preguntas.
  final String asset;

  /// Índice de jerarquía (0 = más fácil, mayor = más difícil).
  int get rank => index;

  /// Puntos que otorga acertar AL PRIMER INTENTO una pregunta de este nivel.
  /// A mayor dificultad, más vale cada acierto.
  int get points => switch (this) {
        DifficultyLevel.entrada => 1,
        DifficultyLevel.basico => 1,
        DifficultyLevel.medio => 2,
        DifficultyLevel.avanzado => 2,
        DifficultyLevel.pastorado => 3,
        DifficultyLevel.teologia => 4,
        DifficultyLevel.evangelista => 5,
      };

  /// Serialización estable para persistencia (no depende del orden del enum).
  String get id => name;

  /// Niveles desbloqueados al estar en este nivel: todos los de igual o menor
  /// jerarquía (acceso en cascada). Estar en evangelista habilita los 7; en
  /// teología habilita 6; en avanzado habilita 1..4; etc.
  List<DifficultyLevel> get unlockedLevels =>
      DifficultyLevel.values.where((l) => l.rank <= rank).toList();

  static DifficultyLevel fromId(String id) =>
      DifficultyLevel.values.firstWhere(
        (level) => level.name == id,
        orElse: () => DifficultyLevel.entrada,
      );
}
