/// Longitud que el usuario elige antes de comenzar un test.
enum TestLength {
  ten(label: '10 preguntas', count: 10),
  twenty(label: '20 preguntas', count: 20),

  /// Modo infinito: el test sigue extrayendo preguntas del banco hasta que
  /// el usuario decide salir. [count] = null significa "sin tope".
  infinite(label: 'Modo infinito', count: null);

  const TestLength({required this.label, required this.count});

  final String label;

  /// Cantidad de preguntas distintas a extraer del banco, o null si infinito.
  final int? count;

  bool get isInfinite => count == null;
}
