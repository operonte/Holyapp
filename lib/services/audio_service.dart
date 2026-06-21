import 'package:audioplayers/audioplayers.dart';

/// Reproduce efectos de sonido cortos del test. Tolerante a fallos: si el audio
/// no está disponible (p. ej. política del navegador), no interrumpe el juego.
class AudioService {
  AudioService._();
  static final AudioService instance = AudioService._();

  final AudioPlayer _player = AudioPlayer();

  Future<void> correct() => _play('sounds/correct.wav');
  Future<void> wrong() => _play('sounds/wrong.wav');

  Future<void> _play(String asset) async {
    try {
      await _player.stop();
      await _player.play(AssetSource(asset));
    } catch (_) {
      // Silencioso: el sonido es secundario.
    }
  }
}
