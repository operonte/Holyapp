import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/difficulty_level.dart';
import '../state/app_state.dart';
import '../state/auth_controller.dart';
import '../state/settings_controller.dart';
import 'ranking_screen.dart';

/// Pantalla de Configuración: contiene lo propio de la configuración del
/// jugador: la cuenta (login opcional), el NIVEL actual (con la regla de
/// desafío) y el reinicio total del puntaje.
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
          _SectionTitle('Cuenta'),
          const SizedBox(height: 8),
          const _AccountSection(),
          const Divider(height: 48),
          _SectionTitle('Preguntas'),
          const SizedBox(height: 8),
          const _RepeatSetting(),
          const SizedBox(height: 8),
          const _SoundSetting(),
          const Divider(height: 48),
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
          const Divider(height: 48),
          _SectionTitle('Legal'),
          const SizedBox(height: 8),
          const _LegalSection(),
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

/// Sección de cuenta: login OPCIONAL con Google. Si hay sesión, muestra el
/// perfil y "Cerrar sesión"; si no, invita a iniciar sesión para guardar el
/// progreso en la nube.
class _AccountSection extends StatelessWidget {
  const _AccountSection();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final app = context.watch<AppState>();
    final scheme = Theme.of(context).colorScheme;
    final user = auth.currentUser;

    if (user != null) {
      return Card(
        child: Column(
          children: [
            ListTile(
              leading: CircleAvatar(
                backgroundImage: user.photoUrl != null
                    ? NetworkImage(user.photoUrl!)
                    : null,
                child:
                    user.photoUrl == null ? const Icon(Icons.person) : null,
              ),
              title: Text(user.displayName),
              subtitle: Text(user.email ?? 'Sesión iniciada'),
              trailing: TextButton.icon(
                onPressed: auth.signOut,
                icon: const Icon(Icons.logout),
                label: const Text('Salir'),
              ),
            ),
            const Divider(height: 1),
            // Estadísticas rápidas del perfil.
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _Stat(label: 'Puntaje', value: '${app.score}'),
                  _Stat(
                      label: 'Dominadas',
                      value: '${app.correctFirstTryIds.length}'),
                  _Stat(
                      label: 'Por repasar',
                      value: '${app.reviewIds.length}'),
                ],
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.leaderboard),
              title: const Text('Ranking global'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const RankingScreen()),
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: Icon(Icons.delete_forever, color: scheme.error),
              title: Text('Eliminar mi cuenta y datos',
                  style: TextStyle(color: scheme.error)),
              onTap: () => _confirmDelete(context),
            ),
          ],
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.person_outline, color: scheme.primary),
                const SizedBox(width: 8),
                const Text('Estás jugando como invitado'),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Inicia sesión con Google para guardar tu progreso en la nube, '
              'recuperarlo en cualquier dispositivo y competir en el ranking. '
              'El inicio de sesión es opcional: puedes seguir jugando sin él.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () => _onSignIn(context),
              icon: const Icon(Icons.login),
              label: const Text('Iniciar sesión con Google'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onSignIn(BuildContext context) async {
    final auth = context.read<AuthController>();
    final error = await auth.signInWithGoogle();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error ??
            '¡Sesión iniciada! Tu progreso se guardará en la nube.'),
        duration: Duration(seconds: error == null ? 3 : 6),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final app = context.read<AppState>();
    final auth = context.read<AuthController>();
    final messenger = ScaffoldMessenger.of(context);
    final scheme = Theme.of(context).colorScheme;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar cuenta'),
        content: const Text(
          'Se borrarán de forma permanente tu progreso en la nube y tu entrada '
          'del ranking, y se eliminará tu cuenta. Tu progreso local en este '
          'dispositivo se conserva. ¿Continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: scheme.error),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    // Primero los datos en la nube (mientras hay sesión), luego la cuenta.
    try {
      await app.deleteCloudData();
    } catch (_) {}
    final error = await auth.deleteAccount();
    messenger.showSnackBar(
      SnackBar(content: Text(error ?? 'Tu cuenta y datos fueron eliminados.')),
    );
  }
}

/// Enlaces legales exigidos por las tiendas (privacidad, términos) y contacto.
class _LegalSection extends StatelessWidget {
  const _LegalSection();

  static const _base = 'https://holyapp-8b41f.web.app';
  static const _privacy = '$_base/privacidad';
  static const _terms = '$_base/terminos';
  static const _contact = 'mailto:cristian.bravo.droguett@gmail.com';

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Política de privacidad'),
            trailing: const Icon(Icons.open_in_new, size: 18),
            onTap: () => _open(context, _privacy),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: const Text('Términos de uso'),
            trailing: const Icon(Icons.open_in_new, size: 18),
            onTap: () => _open(context, _terms),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.mail_outline),
            title: const Text('Contacto'),
            subtitle: const Text('cristian.bravo.droguett@gmail.com'),
            onTap: () => _open(context, _contact),
          ),
        ],
      ),
    );
  }

  Future<void> _open(BuildContext context, String url) async {
    final ok = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo abrir: $url')),
      );
    }
  }
}

/// Estadística compacta (valor grande + etiqueta) para el perfil.
class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: Theme.of(context).textTheme.titleLarge),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

/// Interruptor: repetir preguntas o verlas una sola vez (desde que se aciertan).
class _RepeatSetting extends StatelessWidget {
  const _RepeatSetting();

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();
    return Card(
      child: SwitchListTile(
        value: settings.repeatMastered,
        onChanged: settings.setRepeatMastered,
        title: const Text('Repetir preguntas'),
        subtitle: Text(
          settings.repeatMastered
              ? 'Las preguntas pueden volver a aparecer en futuros tests.'
              : 'Cada pregunta que aciertes no volverá a aparecer en nuevos '
                  'tests (la verás una sola vez).',
        ),
        secondary: const Icon(Icons.repeat),
      ),
    );
  }
}

/// Interruptor: efectos de sonido en el test.
class _SoundSetting extends StatelessWidget {
  const _SoundSetting();

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();
    return Card(
      child: SwitchListTile(
        value: settings.soundEnabled,
        onChanged: settings.setSoundEnabled,
        title: const Text('Sonido'),
        subtitle: const Text('Efectos de sonido al acertar o fallar.'),
        secondary: Icon(
          settings.soundEnabled ? Icons.volume_up : Icons.volume_off,
        ),
      ),
    );
  }
}
