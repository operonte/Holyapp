import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/difficulty_level.dart';
import '../models/test_length.dart';
import '../services/question_service.dart';
import '../state/app_state.dart';
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

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();

    if (!app.isLoaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('HolyApp · Trivia Bíblica'),
        actions: [
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

  Future<void> _startTest(BuildContext context) async {
    setState(() => _starting = true);
    final app = context.read<AppState>();
    try {
      // Mezcla las preguntas de todos los niveles desbloqueados (1..N).
      final bank = await QuestionService.instance.loadUpTo(app.level);
      if (!context.mounted) return;
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
