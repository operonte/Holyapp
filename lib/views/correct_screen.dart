import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/bible_question.dart';
import '../services/question_service.dart';
import '../state/app_state.dart';
import '../widgets/question_history_view.dart';

/// Pantalla "Respuestas correctas": preguntas acertadas al primer intento.
///
/// Carga el banco del nivel actual (cacheado) y lo cruza con los IDs guardados
/// en [AppState]. Como cambiar de nivel limpia el historial, todos los IDs
/// pertenecen siempre al nivel cargado.
class CorrectScreen extends StatelessWidget {
  const CorrectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(
        title: Text('Respuestas correctas (${app.correctFirstTryIds.length})'),
      ),
      body: FutureBuilder<List<BibleQuestion>>(
        future: QuestionService.instance.loadUpTo(app.level),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final byId = {for (final q in snapshot.data!) q.id: q};
          final items = app.correctFirstTryIds
              .map((id) => byId[id])
              .whereType<BibleQuestion>()
              .toList();

          return QuestionHistoryView(
            questions: items,
            icon: Icons.check_circle,
            iconColor: Colors.green,
            emptyMessage: 'Aún no tienes respuestas correctas.\n'
                'Acierta preguntas al primer intento para verlas aquí.',
          );
        },
      ),
    );
  }
}
