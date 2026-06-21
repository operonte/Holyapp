import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/difficulty_level.dart';
import '../state/app_state.dart';

/// Pantalla de Configuración: contiene lo propio de la configuración del
/// jugador, principalmente el NIVEL actual (con la regla de desafío) y el
/// reinicio total del puntaje.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Configuración')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SectionTitle('Nivel actual'),
          const SizedBox(height: 8),
          Card(
            color: scheme.primaryContainer,
            child: ListTile(
              leading: Icon(Icons.school, color: scheme.onPrimaryContainer),
              title: Text('Nivel: ${app.level.label}',
                  style: TextStyle(color: scheme.onPrimaryContainer)),
              subtitle: Text('Puntaje acumulado: ${app.score}',
                  style: TextStyle(color: scheme.onPrimaryContainer)),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tu nivel desbloquea en cascada todos los inferiores: cada test '
            'mezcla preguntas de los niveles incluidos, y cada acierto al primer '
            'intento vale según su nivel '
            '(entrada/básico = 1, medio/avanzado = 2, pastorado = 3, '
            'teología = 4 pts).',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 4),
          Text(
            'Incluye: ${app.level.unlockedLevels.map((l) => l.label).join(' · ')}',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            'Cambiar de nivel reinicia tu puntaje a 0 y limpia tu historial '
            '(regla de desafío máximo).',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final level in DifficultyLevel.values)
                ChoiceChip(
                  label: Text('${level.label} · ${level.points} pts'),
                  selected: level == app.level,
                  onSelected: (_) => _onPickLevel(context, level),
                ),
            ],
          ),
          const Divider(height: 48),
          _SectionTitle('Puntaje'),
          const SizedBox(height: 8),
          Text(
            'Reiniciar todo el puntaje vuelve a 0 y limpia "Respuestas '
            'correctas" y "Repasar". Es la única forma de recuperar los puntos '
            'perdidos al fallar.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => _confirmResetAll(context),
            icon: const Icon(Icons.restart_alt),
            label: const Text('Reiniciar todo el puntaje'),
            style: OutlinedButton.styleFrom(
              foregroundColor: scheme.error,
              minimumSize: const Size.fromHeight(48),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onPickLevel(BuildContext context, DifficultyLevel level) async {
    final app = context.read<AppState>();
    if (level == app.level) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cambiar de nivel'),
        content: Text(
          'Pasar a "${level.label}" reiniciará tu puntaje global a 0 y '
          'limpiará tus pantallas de historial. ¿Continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sí, cambiar'),
          ),
        ],
      ),
    );

    if (ok == true) {
      await app.changeLevel(level);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Nivel: ${level.label} · puntaje reiniciado')),
        );
      }
    }
  }

  Future<void> _confirmResetAll(BuildContext context) async {
    final app = context.read<AppState>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reiniciar todo el puntaje'),
        content: const Text(
          'Volverás a 0 puntos y se limpiarán "Respuestas correctas" y '
          '"Repasar". ¿Continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Reiniciar'),
          ),
        ],
      ),
    );
    if (ok == true) await app.resetAllScore();
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Text(
        text,
        style: Theme.of(context)
            .textTheme
            .titleMedium
            ?.copyWith(fontWeight: FontWeight.bold),
      );
}
