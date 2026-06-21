import 'package:flutter/material.dart';

import 'references_list.dart';

/// Panel de retroalimentación que aparece tras responder.
///
///  - Acierto: "¡Acertaste!" + citas de respaldo.
///  - Fallo:   "Lo siento, para la próxima" + citas para corregir de inmediato.
class FeedbackPanel extends StatelessWidget {
  const FeedbackPanel({
    super.key,
    required this.correct,
    required this.references,
    required this.onContinue,
    this.explanation,
  });

  final bool correct;
  final List<String> references;
  final VoidCallback onContinue;

  /// Explicación didáctica opcional de la respuesta.
  final String? explanation;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = correct
        ? (isDark ? Colors.green.shade900 : Colors.green.shade50)
        : scheme.errorContainer;
    final accent = correct
        ? (isDark ? Colors.green.shade200 : Colors.green.shade700)
        : scheme.error;
    // Texto del botón "Continuar" con contraste sobre el color de acento.
    final onAccent = correct
        ? (isDark ? Colors.black : Colors.white)
        : scheme.onError;

    return Material(
      elevation: 12,
      color: bg,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    correct ? Icons.celebration : Icons.favorite,
                    color: accent,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    correct ? '¡Acertaste!' : 'Lo siento, para la próxima',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: accent,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              if (explanation != null && explanation!.isNotEmpty) ...[
                Text(
                  explanation!,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
              ],
              Text(
                correct
                    ? 'Refuerza con estas citas:'
                    : 'Corrige con estas citas bíblicas:',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              ReferencesList(references: references),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: onContinue,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  backgroundColor: accent,
                  foregroundColor: onAccent,
                ),
                child: const Text('Continuar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
