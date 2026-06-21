import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/firestore_service.dart';
import '../state/auth_controller.dart';

/// Ranking global (leaderboard) en vivo. Requiere sesión iniciada: si el
/// usuario es invitado, invita a iniciar sesión.
class RankingScreen extends StatelessWidget {
  const RankingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();

    return Scaffold(
      appBar: AppBar(title: const Text('Ranking global')),
      body: !auth.isSignedIn
          ? const _NeedSignIn()
          : _RankingList(currentUid: auth.currentUser!.uid),
    );
  }
}

class _RankingList extends StatelessWidget {
  const _RankingList({required this.currentUid});
  final String currentUid;

  @override
  Widget build(BuildContext context) {
    final FirestoreService cloud;
    try {
      cloud = FirestoreService.holyapp();
    } catch (_) {
      return const Center(child: Text('Ranking no disponible sin conexión.'));
    }

    return StreamBuilder<List<RankEntry>>(
      stream: cloud.topScores(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('No se pudo cargar el ranking.'));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final entries = snapshot.data!;
        if (entries.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Text(
                'Aún no hay puntajes. ¡Sé el primero en aparecer!',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: entries.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, i) {
            final e = entries[i];
            final isMe = e.uid == currentUid;
            return ListTile(
              tileColor: isMe
                  ? Theme.of(context).colorScheme.primaryContainer
                  : null,
              leading: _RankBadge(position: i + 1),
              title: Text(
                e.name + (isMe ? '  (tú)' : ''),
                style: TextStyle(
                  fontWeight: isMe ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              trailing: Text(
                '${e.score} pts',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            );
          },
        );
      },
    );
  }
}

class _RankBadge extends StatelessWidget {
  const _RankBadge({required this.position});
  final int position;

  @override
  Widget build(BuildContext context) {
    final medal = switch (position) {
      1 => '🥇',
      2 => '🥈',
      3 => '🥉',
      _ => null,
    };
    if (medal != null) {
      return Text(medal, style: const TextStyle(fontSize: 24));
    }
    return CircleAvatar(
      radius: 16,
      child: Text('$position', style: const TextStyle(fontSize: 13)),
    );
  }
}

class _NeedSignIn extends StatelessWidget {
  const _NeedSignIn();
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Text(
          'Inicia sesión con Google (en Configuración) para ver el ranking y '
          'aparecer en él con tu puntaje.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
