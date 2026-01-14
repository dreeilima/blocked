import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppThemeMode { light, dark, system }

class ThemeProvider extends ChangeNotifier {
  AppThemeMode _themeMode = AppThemeMode.system;

  AppThemeMode get themeMode => _themeMode;

  ThemeProvider() {
    _loadThemeMode();
  }

  Future<void> _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final savedMode = prefs.getString('theme_mode') ?? 'system';
    _themeMode = AppThemeMode.values.firstWhere(
      (e) => e.toString() == 'AppThemeMode.$savedMode',
      orElse: () => AppThemeMode.system,
    );
    notifyListeners();
  }

  Future<void> setThemeMode(AppThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_mode', mode.toString().split('.').last);
  }

  ThemeMode get effectiveThemeMode {
    switch (_themeMode) {
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
      case AppThemeMode.system:
        return ThemeMode.system;
    }
  }

  // Light Theme - Baseado no design extraído de blocked.jeffsieu.com
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(
        0xFFEDF1F1,
      ), // #EDF1F1 - Background extraído
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF1B5E20), // #1B5E20 - Primary Dark (Green 900)
        secondary: Color(0xFFA5D6A7), // #A5D6A7 - Primary Light (Green 200)
        surface: Color(0xFFFFFFFF),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFFFFFFFF),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12), // 12px border radius
          side: const BorderSide(color: Color(0xFFB0BEC5), width: 2),
        ),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 48, // Heading size extraído
          fontWeight: FontWeight.w400,
          letterSpacing: 2,
          color: Color(0xFF2E3436), // #2E3436 - Text Primary
        ),
        displayMedium: TextStyle(
          fontSize: 32, // Subheading size extraído
          fontWeight: FontWeight.w400,
          letterSpacing: 1.5,
          color: Color(0xFF2E3436),
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: Color(0xFF2E3436),
        ),
      ),
    );
  }

  // Dark Theme - Baseado no modo escuro do blocked.jeffsieu.com
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(
        0xFF121514,
      ), // #121514 - Background escuro com tom verde
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFFA8F0BA), // #A8F0BA - Verde neon
        secondary: Color(0xFF80CBC4), // #80CBC4 - Teal 200
        surface: Color(0xFF1A1D1C), // #1A1D1C - Surface escuro
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF1A1D1C),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFF424242), width: 2),
        ),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 48,
          fontWeight: FontWeight.w400,
          letterSpacing: 2,
          color: Color(0xFFFFFFFF),
        ),
        displayMedium: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w400,
          letterSpacing: 1.5,
          color: Color(0xFFFFFFFF),
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: Color(0xFFFFFFFF),
        ),
      ),
    );
  }

  // Game-specific colors
  static GameColors getGameColors(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? GameColors.dark : GameColors.light;
  }
}

class GameColors {
  final Color boardBackground;
  final Color boardBorder;
  final Color blockFill;
  final Color blockBorder;
  final Color secondaryBlockFill; // New for non-primary blocks
  final Color secondaryBlockBorder; // New for non-primary blocks
  final Color activeBlockBorder;
  final Color primaryCircle;
  final Color exitIndicator;
  final Color textColor;
  final Color wallFill;
  final Color wallBorder;

  const GameColors({
    required this.boardBackground,
    required this.boardBorder,
    required this.blockFill,
    required this.blockBorder,
    required this.secondaryBlockFill,
    required this.secondaryBlockBorder,
    required this.activeBlockBorder,
    required this.primaryCircle,
    required this.exitIndicator,
    required this.textColor,
    required this.wallFill,
    required this.wallBorder,
  });

  static const light = GameColors(
    // Cores extraídas do site original blocked.jeffsieu.com
    boardBackground: Color(0xFFD1D9D9), // #D1D9D9 - Board Background
    boardBorder: Color(0xFF546E7A), // #546E7A - Board Border
    blockFill: Color(0xFFA5D6A7), // #A5D6A7 - Primary Light (Green 200)
    blockBorder: Color(0xFF1B5E20), // #1B5E20 - Primary Dark (Green 900)
    secondaryBlockFill: Color(0xFFB0BEC5), // #B0BEC5 - Shadows/Secondary Blocks
    secondaryBlockBorder: Color(0xFF546E7A), // #546E7A - Secondary Border
    activeBlockBorder: Color(0xFF1B5E20), // #1B5E20 - Active highlight
    primaryCircle: Color(0xFF1B5E20), // #1B5E20 - Circle icon
    exitIndicator: Color(0xFF1B5E20), // #1B5E20 - Exit marker
    textColor: Color(0xFF2E3436), // #2E3436 - Text Primary
    wallFill: Color(0xFFB0BEC5), // #B0BEC5 - Wall fill
    wallBorder: Color(0xFF546E7A), // #546E7A - Wall border
  );

  // Dark Theme - Cores extraídas do modo escuro original
  static const dark = GameColors(
    boardBackground: Color(0xFF1A1D1C), // #1A1D1C - Board background escuro
    boardBorder: Color(0xFF80CBC4), // #80CBC4 - Teal 200 (borda do tabuleiro)
    blockFill: Color(
      0xFF2D3230,
    ), // #2D3230 - Cinza escuro translúcido (bloco primário)
    blockBorder: Color(0xFFA8F0BA), // #A8F0BA - Verde neon brilhante
    secondaryBlockFill: Color(
      0xFF3A4340,
    ), // Cinza mais claro para blocos secundários
    secondaryBlockBorder: Color(0xFF80CBC4), // Teal para bordas secundárias
    activeBlockBorder: Color(0xFFA8F0BA), // #A8F0BA - Verde neon (highlight)
    primaryCircle: Color(0xFF80CBC4), // #80CBC4 - Teal para círculo
    exitIndicator: Color(0xFF80CBC4), // #80CBC4 - Teal para exit
    textColor: Color(0xFFFFFFFF), // #FFFFFF - Texto branco
    wallFill: Color(0xFF212121), // #212121 - Quase preto para paredes
    wallBorder: Color(0xFF424242), // #424242 - Cinza escuro para borda
  );
}
