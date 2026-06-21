import 'difficulty_level.dart';

/// Una pregunta de trivia bíblica/teológica.
///
/// Es un modelo inmutable: se construye una vez al parsear el JSON y nunca
/// muta. El estado del test (acertada, fallada, etc.) vive en el controlador,
/// no aquí, para mantener la separación entre datos y lógica.
class BibleQuestion {
  const BibleQuestion({
    required this.id,
    required this.text,
    required this.options,
    required this.correctIndex,
    required this.difficulty,
    required this.references,
    this.explanation,
  });

  /// Identificador único y estable (sirve para historial y persistencia).
  final String id;

  /// Enunciado de la pregunta.
  final String text;

  /// Exactamente 4 alternativas.
  final List<String> options;

  /// Índice (0..3) de la opción correcta dentro de [options].
  final int correctIndex;

  /// Nivel al que pertenece la pregunta.
  final DifficultyLevel difficulty;

  /// Citas bíblicas de respaldo: mínimo 1, máximo 3.
  final List<String> references;

  /// Explicación didáctica opcional (el "porqué" de la respuesta), que se
  /// muestra en el feedback y en el historial. Puede ser null.
  final String? explanation;

  String get correctOption => options[correctIndex];

  bool isCorrect(int selectedIndex) => selectedIndex == correctIndex;

  /// Construye desde un mapa JSON, validando las invariantes del banco.
  factory BibleQuestion.fromJson(Map<String, dynamic> json) {
    final options = (json['options'] as List).cast<String>();
    final references = (json['references'] as List).cast<String>();
    final correctIndex = json['correctIndex'] as int;
    final id = json['id'];

    // Validación dura (los assert se eliminan en release; esto no).
    if (options.length != 4) {
      throw FormatException('La pregunta $id debe tener 4 opciones');
    }
    if (correctIndex < 0 || correctIndex >= 4) {
      throw FormatException('correctIndex fuera de rango en $id');
    }
    if (references.isEmpty || references.length > 3) {
      throw FormatException('Las citas de $id deben ser entre 1 y 3');
    }

    return BibleQuestion(
      id: json['id'] as String,
      text: json['text'] as String,
      options: options,
      correctIndex: correctIndex,
      difficulty: DifficultyLevel.fromId(json['difficulty'] as String),
      references: references,
      explanation: json['explanation'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'options': options,
        'correctIndex': correctIndex,
        'difficulty': difficulty.id,
        'references': references,
        if (explanation != null) 'explanation': explanation,
      };
}
