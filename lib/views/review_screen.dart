import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/bible_question.dart';
import '../services/question_service.dart';
import '../state/app_state.dart';
import '../widgets/question_history_view.dart';

/// Pantalla "Repasar": preguntas falladas al menos una vez (aunque se hayan
/// corregido después). Su punto queda perdido hasta un reinicio total.
class ReviewScreen extends StatelessWidget {
  const ReviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(
        title: Text('Repasar (${app.reviewIds.length})'),
      ),
      body: FutureBuilder<List<BibleQuestion>>(
        future: QuestionService.instance.loadUpTo(app.level),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final byId = {for (final q in snapshot.data!) q.id: q};
          final items = app.reviewIds
              .map((id) => byId[id])
              .whereType<BibleQuestion>()
              .toList();

          return QuestionHistoryView(
            questions: items,
            icon: Icons.menu_book,
            iconColor: Theme.of(context).colorScheme.error,
            emptyMessage: '¡Sin preguntas para repasar!\n'
                'Aquí aparecerán las que falles al menos una vez.',
          );
        },
      ),
    );
  }
}
