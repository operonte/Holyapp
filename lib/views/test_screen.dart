import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/bible_question.dart';
import '../services/audio_service.dart';
import '../state/app_state.dart';
import '../state/settings_controller.dart';
import '../state/test_controller.dart';
import '../widgets/feedback_panel.dart';
import 'results_screen.dart';

/// Pantalla del test activo. Posee el [TestController] y lo libera al salir.
class TestScreen extends StatefulWidget {
  const TestScreen({super.key, required this.controller});
  final TestController controller;

  @override
  State<TestScreen> createState() => _TestScreenState();
}

class _TestScreenState extends State<TestScreen> {
  @override
  void dispose() {
    widget.controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: widget.controller,
      child: Consumer<TestController>(
        builder: (context, ctrl, _) {
          final finished = ctrl.phase == TestPhase.finished;
          // Si el test sigue en curso, intercepta el "atrás" para no perder el
          // progreso ya logrado (los puntos se confirman solo al terminar).
          return PopScope(
            canPop: finished,
            onPopInvokedWithResult: (didPop, _) async {
              if (didPop) return;
              final leave = await _confirmExit(context);
              if (leave && context.mounted) Navigator.of(context).pop();
            },
            child: finished
                ? _FinishedView(controller: ctrl)
                : _ActiveView(controller: ctrl),
          );
        },
      ),
    );
  }

  Future<bool> _confirmExit(BuildContext context) async {
    final leave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Salir del test?'),
        content: const Text(
          'Si sales ahora perderás el progreso de este test (los puntos se '
          'guardan solo al terminarlo). ¿Seguro que quieres salir?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Seguir jugando'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Salir'),
          ),
        ],
      ),
    );
    return leave ?? false;
  }
}

class _ActiveView extends StatelessWidget {
  const _ActiveView({required this.controller});
  final TestController controller;

  @override
  Widget build(BuildContext context) {
    final question = controller.current!;
    final isFeedback = controller.phase == TestPhase.feedback;

    return Scaffold(
      appBar: AppBar(
        title: Text(controller.level.label),
        actions: [
          if (controller.canFinishEarly)
            TextButton(
              onPressed: controller.finishNow,
              child: const Text('Finalizar',
                  style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (!controller.isInfinite)
              LinearProgressIndicator(value: controller.progress),
            _ProgressBar(controller: controller),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Chip(
                      avatar: const Icon(Icons.star, size: 16),
                      label: Text(
                        '${question.difficulty.label} · '
                        '${question.difficulty.points} pts',
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    question.text,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 24),
                  ...List.generate(question.options.length, (i) {
                    return _OptionTile(
                      question: question,
                      index: i,
                      selectedIndex: controller.selectedIndex,
                      locked: isFeedback,
                      onTap: () {
                        controller.answer(i);
                        final soundOn =
                            context.read<SettingsController>().soundEnabled;
                        // Vibración + sonido: distinto si acierta o falla.
                        if (controller.lastWasCorrect) {
                          HapticFeedback.lightImpact();
                          if (soundOn) AudioService.instance.correct();
                        } else {
                          HapticFeedback.heavyImpact();
                          if (soundOn) AudioService.instance.wrong();
                        }
                      },
                    );
                  }),
                ],
              ),
            ),
            if (isFeedback)
              FeedbackPanel(
                correct: controller.lastWasCorrect,
                references: controller.currentReferences,
                explanation: controller.current?.explanation,
                onContinue: controller.next,
              ),
          ],
        ),
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.controller});
  final TestController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _chip(context, Icons.timelapse,
              controller.isInfinite ? '∞' : 'En cola: ${controller.remaining}'),
          _chip(context, Icons.star, 'Puntos: ${controller.pointsEarned}'),
          _chip(context, Icons.replay, 'Fallos: ${controller.failedCount}'),
        ],
      ),
    );
  }

  Widget _chip(BuildContext context, IconData icon, String text) => Chip(
        avatar: Icon(icon, size: 18),
        label: Text(text),
      );
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.question,
    required this.index,
    required this.selectedIndex,
    required this.locked,
    required this.onTap,
  });

  final BibleQuestion question;
  final int index;
  final int? selectedIndex;
  final bool locked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isCorrect = index == question.correctIndex;
    final isPicked = index == selectedIndex;

    Color? bg;
    Color? border;
    if (locked) {
      // Tras responder: resalta la correcta en verde y el error elegido en rojo.
      if (isCorrect) {
        bg = Colors.green.withValues(alpha: 0.15);
        border = Colors.green;
      } else if (isPicked) {
        bg = scheme.errorContainer;
        border = scheme.error;
      }
    }

    final letter = String.fromCharCode(65 + index);
    final semanticLabel = locked && isCorrect
        ? 'Opción $letter, correcta: ${question.options[index]}'
        : locked && isPicked
            ? 'Opción $letter, incorrecta: ${question.options[index]}'
            : 'Opción $letter: ${question.options[index]}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Semantics(
        button: !locked,
        selected: isPicked,
        label: semanticLabel,
        child: Material(
        color: bg ?? scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: locked ? null : onTap,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: border ?? Colors.transparent,
                width: 2,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  child: Text(String.fromCharCode(65 + index)),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(question.options[index])),
                if (locked && isCorrect)
                  const Icon(Icons.check_circle, color: Colors.green),
                if (locked && isPicked && !isCorrect)
                  Icon(Icons.cancel, color: scheme.error),
              ],
            ),
          ),
        ),
      ),
      ),
    );
  }
}

/// Vista de cierre: integra el resultado en el estado global una sola vez y
/// reutiliza [ResultsScreen] para mostrar el resumen.
class _FinishedView extends StatefulWidget {
  const _FinishedView({required this.controller});
  final TestController controller;

  @override
  State<_FinishedView> createState() => _FinishedViewState();
}

class _FinishedViewState extends State<_FinishedView> {
  bool _committed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_committed) return;
      _committed = true;
      context.read<AppState>().commitTestResult(widget.controller.buildResult());
    });
  }

  @override
  Widget build(BuildContext context) {
    return ResultsScreen(result: widget.controller.buildResult());
  }
}
