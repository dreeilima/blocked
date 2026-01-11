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

  // Light Theme
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFF5F5F5),
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF66BB6A),
        secondary: Color(0xFF81C784),
        surface: Color(0xFFFFFFFF),
      ),
      cardTheme: const CardThemeData(color: Color(0xFFFFFFFF), elevation: 2),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w400,
          color: Color(0xFF212121),
        ),
        bodyLarge: TextStyle(fontSize: 16, color: Color(0xFF212121)),
      ),
    );
  }

  // Dark Theme
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF1E1E1E),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF8FBC8F),
        secondary: Color(0xFF5A6A6A),
        surface: Color(0xFF2A2A2A),
      ),
      cardTheme: const CardThemeData(color: Color(0xFF2A2A2A), elevation: 2),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w400,
          color: Color(0xFFE0E0E0),
        ),
        bodyLarge: TextStyle(fontSize: 16, color: Color(0xFFE0E0E0)),
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
  });

  static const light = GameColors(
    boardBackground: Color(0xFFFFFFFF),
    boardBorder: Color(0xFFBDBDBD),
    blockFill: Color(0xFFE8F5E9), // Greenish for primary
    blockBorder: Color(0xFFA5D6A7),
    secondaryBlockFill: Color(0xFFE0E0E0), // Grey for others
    secondaryBlockBorder: Color(0xFFBDBDBD),
    activeBlockBorder: Color(0xFF66BB6A),
    primaryCircle: Color(0xFF66BB6A),
    exitIndicator: Color(0xFF81C784),
    textColor: Color(0xFF212121),
  );

  static const dark = GameColors(
    boardBackground: Color(0xFF2A3A3A),
    boardBorder: Color(0xFF5A6A6A),
    blockFill: Color(0xFF3A4A4A), // Teal/Green for primary
    blockBorder: Color(0xFF5A6A6A),
    secondaryBlockFill: Color(0xFF4A5A5A), // Cinza médio mais claro
    secondaryBlockBorder: Color(0xFF5A6A6A),
    activeBlockBorder: Color(0xFF8FBC8F),
    primaryCircle: Color(0xFF8FBC8F),
    exitIndicator: Color(0xFF8FBC8F),
    textColor: Color(0xFFE0E0E0),
  );
}
