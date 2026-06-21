import 'package:flutter/material.dart';

import '../models/bible_question.dart';
import 'references_list.dart';

/// Lista reutilizable de preguntas con su respuesta y citas de respaldo.
///
/// La usan tanto la pantalla de "Respuestas correctas" como la de "Repasar";
/// cada una le pasa su propio ícono, color y mensaje de estado vacío.
class QuestionHistoryView extends StatelessWidget {
  const QuestionHistoryView({
    super.key,
    required this.questions,
    required this.icon,
    required this.iconColor,
    required this.emptyMessage,
  });

  final List<BibleQuestion> questions;
  final IconData icon;
  final Color iconColor;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    if (questions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(emptyMessage, textAlign: TextAlign.center),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: questions.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final q = questions[i];
        return Card(
          child: ExpansionTile(
            leading: Icon(icon, color: iconColor),
            title: Text(q.text),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            expandedCrossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Respuesta: ${q.correctOption}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              if (q.explanation != null && q.explanation!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(q.explanation!),
              ],
              const SizedBox(height: 8),
              ReferencesList(references: q.references),
            ],
          ),
        );
      },
    );
  }
}
