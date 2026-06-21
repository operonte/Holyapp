import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Preferencias de juego del dispositivo (no son progreso, no se sincronizan).
class SettingsController extends ChangeNotifier {
  static const _kRepeat = 'holy.repeatMastered';
  static const _kOnboarding = 'holy.onboardingSeen';

  /// Si es `true` (por defecto), las preguntas pueden repetirse en futuros
  /// tests. Si es `false`, una pregunta ya acertada (dominada) no vuelve a
  /// aparecer en nuevos tests.
  bool _repeatMastered = true;
  bool get repeatMastered => _repeatMastered;

  /// `true` una vez que el usuario vio el tutorial inicial.
  bool _onboardingSeen = false;
  bool get onboardingSeen => _onboardingSeen;

  bool _loaded = false;
  bool get isLoaded => _loaded;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _repeatMastered = prefs.getBool(_kRepeat) ?? true;
    _onboardingSeen = prefs.getBool(_kOnboarding) ?? false;
    _loaded = true;
    notifyListeners();
  }

  Future<void> markOnboardingSeen() async {
    if (_onboardingSeen) return;
    _onboardingSeen = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kOnboarding, true);
  }

  Future<void> setRepeatMastered(bool value) async {
    if (value == _repeatMastered) return;
    _repeatMastered = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kRepeat, value);
  }
}
