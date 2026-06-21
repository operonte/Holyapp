import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'services/storage_service.dart';
import 'state/app_state.dart';
import 'views/home_screen.dart';

void main() {
  // Asegura los bindings antes de cargar progreso desde almacenamiento.
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    ChangeNotifierProvider(
      // init() carga el progreso persistido de forma asíncrona; la UI muestra
      // un loader hasta que isLoaded sea true.
      create: (_) => AppState(StorageService.instance)..init(),
      child: const HolyApp(),
    ),
  );
}

class HolyApp extends StatelessWidget {
  const HolyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF6A4FB6),
      brightness: Brightness.light,
    );
    return MaterialApp(
      title: 'HolyApp',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: scheme,
        useMaterial3: true,
        appBarTheme: AppBarTheme(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
