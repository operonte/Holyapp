import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../state/test_controller.dart';

/// Resumen al terminar un test. El resultado ya fue integrado al estado global.
class ResultsScreen extends StatelessWidget {
  const ResultsScreen({super.key, required this.result});
  final TestResult result;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final correct = result.firstTryCorrect.length;
    final points = result.pointsEarned;
    final failed = result.failed.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Resultado'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              Icon(Icons.emoji_events,
                  size: 96, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 16),
              Text('¡Test completado!',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 24),
              _Stat(
                icon: Icons.check_circle,
                color: Colors.green,
                label: 'Aciertos al primer intento',
                value: '$correct',
              ),
              _Stat(
                icon: Icons.star,
                color: Colors.amber.shade700,
                label: 'Puntos ganados (ponderados)',
                value: '+$points',
              ),
              _Stat(
                icon: Icons.menu_book,
                color: Theme.of(context).colorScheme.error,
                label: 'Para repasar (falladas)',
                value: '$failed',
              ),
              _Stat(
                icon: Icons.workspace_premium,
                color: Theme.of(context).colorScheme.primary,
                label: 'Puntaje global ahora',
                value: '${app.score}',
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: () =>
                    Navigator.of(context).popUntil((r) => r.isFirst),
                icon: const Icon(Icons.home),
                label: const Text('Volver al inicio'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(label),
        trailing: Text(value,
            style: Theme.of(context).textTheme.titleLarge),
      ),
    );
  }
}
