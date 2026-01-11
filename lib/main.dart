import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'controllers/game_controller.dart';
import 'controllers/audio_controller.dart';
import 'providers/theme_provider.dart';
import 'screens/main_menu_screen.dart';
import 'screens/game_screen.dart';
import 'screens/level_selection_screen.dart';
import 'screens/settings_screen.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AudioController()),
        // Usar ProxyProvider para injetar AudioController no GameController se necessário,
        // ou apenas passar via setter na inicialização da UI.
        ChangeNotifierProxyProvider<AudioController, GameController>(
          create: (_) => GameController(),
          update: (_, audio, game) {
            game?.audioController = audio;
            return game!;
          },
        ),
      ],
      child: const BlockedApp(),
    ),
  );
}

class BlockedApp extends StatelessWidget {
  const BlockedApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return MaterialApp(
          title: 'Blocked',
          debugShowCheckedModeBanner: false,
          theme: ThemeProvider.lightTheme,
          darkTheme: ThemeProvider.darkTheme,
          themeMode: themeProvider.effectiveThemeMode,
          home: const MainMenuScreen(),
          routes: {
            '/levels': (context) => const LevelSelectionScreen(),
            '/game': (context) => const GameScreen(),
            '/settings': (context) => const SettingsScreen(),
          },
        );
      },
    );
  }
}
