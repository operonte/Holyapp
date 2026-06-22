import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/difficulty_level.dart';
import '../models/test_length.dart';
import '../services/question_service.dart';
import '../state/app_state.dart';
import '../state/settings_controller.dart';
import '../state/test_controller.dart';
import 'correct_screen.dart';
import 'review_screen.dart';
import 'settings_screen.dart';
import 'test_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  TestLength _selectedLength = TestLength.ten;
  bool _starting = false;
  bool _onboardingChecked = false;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final settings = context.watch<SettingsController>();

    if (!app.isLoaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Tutorial la primera vez (una sola vez por dispositivo).
    if (settings.isLoaded && !settings.onboardingSeen && !_onboardingChecked) {
      _onboardingChecked = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showOnboarding(context);
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('HolyApp · Trivia Bíblica'),
        actions: [
          if (app.isSignedIn) _SyncIndicator(status: app.syncStatus),
          IconButton(
            tooltip: 'Configuración',
            icon: const Icon(Icons.settings),
            onPressed: () => _open(context, const SettingsScreen()),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _ScoreCard(score: app.score, level: app.level),
          const SizedBox(height: 24),
          _SectionTitle('Longitud del test'),
          const SizedBox(height: 8),
          _LengthSelector(
            selected: _selectedLength,
            onChanged: (l) => setState(() => _selectedLength = l),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _starting ? null : () => _startTest(context),
            icon: _starting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.play_arrow),
            label: Text('Comenzar test · ${app.level.label}'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
            ),
          ),
          const Divider(height: 48),
          _SectionTitle('Historial'),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => _open(context, const CorrectScreen()),
            icon: const Icon(Icons.check_circle_outline),
            label: Text(
                'Respuestas correctas (${app.correctFirstTryIds.length})'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => _open(context, const ReviewScreen()),
            icon: const Icon(Icons.menu_book_outlined),
            label: Text('Repasar (${app.reviewIds.length})'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () => _open(context, const SettingsScreen()),
            icon: const Icon(Icons.tune),
            label: const Text('Configuración (nivel y puntaje)'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
          ),
        ],
      ),
    );
  }

  void _open(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  Future<void> _showOnboarding(BuildContext context) async {
    final settings = context.read<SettingsController>();
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('¡Bienvenido a HolyApp!'),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _OnboardPoint(
                icon: Icons.layers,
                text: 'Aprende por niveles (de Entrada a Evangelista). Tu nivel '
                    'desbloquea en cascada todos los inferiores.',
              ),
              _OnboardPoint(
                icon: Icons.replay,
                text: 'Método de fallo y corrección: si te equivocas, la '
                    'pregunta vuelve al final hasta que la aciertes.',
              ),
              _OnboardPoint(
                icon: Icons.star,
                text: 'Cada acierto al primer intento suma puntos según el '
                    'nivel de la pregunta.',
              ),
              _OnboardPoint(
                icon: Icons.menu_book,
                text: 'Tras responder verás una explicación y las citas '
                    'bíblicas para aprender el porqué.',
              ),
              _OnboardPoint(
                icon: Icons.cloud_done,
                text: 'Opcional: inicia sesión con Google (en Configuración) '
                    'para guardar tu progreso y entrar al ranking.',
              ),
            ],
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('¡Entendido!'),
          ),
        ],
      ),
    );
    await settings.markOnboardingSeen();
  }

  Future<void> _startTest(BuildContext context) async {
    setState(() => _starting = true);
    final app = context.read<AppState>();
    final settings = context.read<SettingsController>();
    try {
      // Mezcla las preguntas de todos los niveles desbloqueados (1..N).
      var bank = await QuestionService.instance.loadUpTo(app.level);
      // Si el usuario eligió "ver una sola vez", excluye las ya dominadas.
      if (!settings.repeatMastered) {
        final mastered = app.correctFirstTryIds.toSet();
        bank = bank.where((q) => !mastered.contains(q.id)).toList();
      }
      if (!context.mounted) return;
      if (bank.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '¡Ya dominaste todas las preguntas disponibles! Activa "repetir '
              'preguntas" en Configuración o reinicia el puntaje.',
            ),
          ),
        );
        return;
      }
      final controller = TestController(
        level: app.level,
        length: _selectedLength,
        bank: bank,
      );
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => TestScreen(controller: controller)),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo cargar el banco: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }
}

class _ScoreCard extends StatelessWidget {
  const _ScoreCard({required this.score, required this.level});
  final int score;
  final DifficultyLevel level;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: scheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Icon(Icons.workspace_premium,
                size: 48, color: scheme.onPrimaryContainer),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Puntaje acumulado',
                    style: TextStyle(color: scheme.onPrimaryContainer)),
                Text('$score',
                    style: Theme.of(context)
                        .textTheme
                        .displaySmall
                        ?.copyWith(color: scheme.onPrimaryContainer)),
                Text('Nivel: ${level.label}',
                    style: TextStyle(color: scheme.onPrimaryContainer)),
              ],
            ),
          ],
        ),
      ),
    );
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

class _LengthSelector extends StatelessWidget {
  const _LengthSelector({required this.selected, required this.onChanged});
  final TestLength selected;
  final ValueChanged<TestLength> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<TestLength>(
      segments: [
        for (final l in TestLength.values)
          ButtonSegment(value: l, label: Text(l.label)),
      ],
      selected: {selected},
      onSelectionChanged: (s) => onChanged(s.first),
    );
  }
}

/// Indicador discreto del estado de guardado en la nube (solo con sesión).
class _SyncIndicator extends StatelessWidget {
  const _SyncIndicator({required this.status});
  final SyncStatus status;

  @override
  Widget build(BuildContext context) {
    final onPrimary = Theme.of(context).colorScheme.onPrimary;
    switch (status) {
      case SyncStatus.syncing:
        return Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: onPrimary),
            ),
          ),
        );
      case SyncStatus.synced:
        return IconButton(
          tooltip: 'Progreso guardado en la nube',
          icon: const Icon(Icons.cloud_done_outlined),
          onPressed: () => _toast(context, 'Tu progreso está guardado en la nube.'),
        );
      case SyncStatus.error:
        return IconButton(
          tooltip: 'No se pudo sincronizar (guardado local OK)',
          icon: Icon(Icons.cloud_off_outlined, color: Colors.amber.shade200),
          onPressed: () => _toast(
            context,
            'No se pudo sincronizar con la nube. Tu progreso está a salvo en '
            'el dispositivo y se reintentará.',
          ),
        );
      case SyncStatus.offline:
        return const SizedBox.shrink();
    }
  }

  void _toast(BuildContext context, String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }
}

/// Un punto del tutorial inicial (ícono + texto).
class _OnboardPoint extends StatelessWidget {
  const _OnboardPoint({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
