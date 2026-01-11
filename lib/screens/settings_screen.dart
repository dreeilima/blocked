import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../controllers/game_controller.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final gameColors = ThemeProvider.getGameColors(context);
    final isDark = themeProvider.effectiveThemeMode == ThemeMode.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings'), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Game Mode Section
          _buildSectionHeader('Game Mode', gameColors),
          const SizedBox(height: 12),
          Consumer<GameController>(
            builder: (context, controller, _) {
              return _buildGameModeCard(
                context,
                controller,
                gameColors,
                isDark,
              );
            },
          ),

          const SizedBox(height: 32),

          // Theme Section
          _buildSectionHeader('Appearance', gameColors),
          const SizedBox(height: 12),
          _buildThemeCard(context, themeProvider, gameColors, isDark),

          const SizedBox(height: 32),

          // About Section
          _buildSectionHeader('About', gameColors),
          const SizedBox(height: 12),
          _buildAboutCard(gameColors, isDark),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, GameColors gameColors) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: gameColors.textColor.withValues(alpha: 0.6),
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildGameModeCard(
    BuildContext context,
    GameController controller,
    GameColors gameColors,
    bool isDark,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        children: [
          _buildGameModeOption(
            context,
            'Free Mode',
            '∞ Unlimited play • 💰 10 coins/win',
            Icons.all_inclusive,
            GameMode.free,
            controller,
            gameColors,
          ),
          Divider(
            height: 1,
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.1),
          ),
          _buildGameModeOption(
            context,
            'Challenge Mode',
            '❤️ ${controller.challengeLives} lives/day • 💎 30 coins/win',
            Icons.flash_on,
            GameMode.challenge,
            controller,
            gameColors,
          ),
        ],
      ),
    );
  }

  Widget _buildGameModeOption(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    GameMode mode,
    GameController controller,
    GameColors gameColors,
  ) {
    final isSelected = controller.currentGameMode == mode;
    final modeColor = mode == GameMode.challenge
        ? const Color(0xFFFF9800)
        : const Color(0xFF4CAF50);

    return InkWell(
      onTap: () => controller.setGameMode(mode),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected
                    ? modeColor.withValues(alpha: 0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? modeColor
                      : gameColors.textColor.withValues(alpha: 0.2),
                  width: 2,
                ),
              ),
              child: Icon(
                icon,
                color: isSelected
                    ? modeColor
                    : gameColors.textColor.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: gameColors.textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: gameColors.textColor.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: modeColor, size: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeCard(
    BuildContext context,
    ThemeProvider themeProvider,
    GameColors gameColors,
    bool isDark,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        children: [
          _buildThemeOption(
            context,
            'System Default',
            'Follow device settings',
            Icons.brightness_auto,
            AppThemeMode.system,
            themeProvider,
            gameColors,
          ),
          Divider(
            height: 1,
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.1),
          ),
          _buildThemeOption(
            context,
            'Light Mode',
            'Always use light theme',
            Icons.light_mode,
            AppThemeMode.light,
            themeProvider,
            gameColors,
          ),
          Divider(
            height: 1,
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.1),
          ),
          _buildThemeOption(
            context,
            'Dark Mode',
            'Always use dark theme',
            Icons.dark_mode,
            AppThemeMode.dark,
            themeProvider,
            gameColors,
          ),
        ],
      ),
    );
  }

  Widget _buildThemeOption(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    AppThemeMode mode,
    ThemeProvider themeProvider,
    GameColors gameColors,
  ) {
    final isSelected = themeProvider.themeMode == mode;

    return InkWell(
      onTap: () => themeProvider.setThemeMode(mode),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected
                    ? gameColors.activeBlockBorder.withValues(alpha: 0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? gameColors.activeBlockBorder
                      : gameColors.textColor.withValues(alpha: 0.2),
                  width: 2,
                ),
              ),
              child: Icon(
                icon,
                color: isSelected
                    ? gameColors.activeBlockBorder
                    : gameColors.textColor.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: gameColors.textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: gameColors.textColor.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: gameColors.activeBlockBorder,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutCard(GameColors gameColors, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        children: [
          Icon(Icons.games, size: 48, color: gameColors.activeBlockBorder),
          const SizedBox(height: 16),
          Text(
            'Blocked',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: gameColors.textColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Version 1.0.0',
            style: TextStyle(
              fontSize: 14,
              color: gameColors.textColor.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'A minimalist puzzle game where you slide blocks to escape the room.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: gameColors.textColor.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}
