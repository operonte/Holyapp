import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'services/storage_service.dart';
import 'state/app_state.dart';
import 'state/auth_controller.dart';
import 'state/settings_controller.dart';
import 'views/home_screen.dart';

Future<void> main() async {
  // Asegura los bindings antes de cargar progreso desde almacenamiento.
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa Firebase (login opcional + sync). Si falla (p. ej. sin red en
  // el primer arranque), la app sigue funcionando offline como invitado.
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase no se pudo inicializar: $e');
  }

  runApp(
    MultiProvider(
      providers: [
        // Preferencias de juego (p. ej. repetir o no las preguntas dominadas).
        ChangeNotifierProvider(create: (_) => SettingsController()..init()),
        // Sesión del usuario (login opcional con Google).
        ChangeNotifierProvider(create: (_) => AuthController()),
        // Progreso global. init() carga lo persistido (la UI muestra un loader
        // hasta isLoaded). Al cambiar la sesión, onAuthChanged reconcilia con
        // la nube (offline-first).
        ChangeNotifierProxyProvider<AuthController, AppState>(
          create: (_) => AppState(StorageService.instance)..init(),
          update: (_, auth, appState) =>
              appState!..onAuthChanged(auth.currentUser),
        ),
      ],
      child: const HolyApp(),
    ),
  );
}

class HolyApp extends StatelessWidget {
  const HolyApp({super.key});

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xFF6A4FB6);
    return MaterialApp(
      title: 'HolyApp',
      debugShowCheckedModeBanner: false,
      theme: _themeFor(Brightness.light, seed),
      darkTheme: _themeFor(Brightness.dark, seed),
      // Sigue el tema del sistema (claro/oscuro) automáticamente.
      themeMode: ThemeMode.system,
      home: const HomeScreen(),
    );
  }

  ThemeData _themeFor(Brightness brightness, Color seed) {
    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: brightness,
    );
    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
      ),
    );
  }
}
