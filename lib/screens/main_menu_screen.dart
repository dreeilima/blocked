import 'package:flutter/material.dart';
import '../widgets/main_menu_background.dart';

class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Usar tema escuro forçado ou adaptar? O design pede dark mode premium.
    // Vamos garantir textos claros.

    return Scaffold(
      body: Stack(
        children: [
          // 1. Background Animado (Auto-play)
          const MainMenuBackground(),

          // 2. Scrim (Degradê para garantir leitura)
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  Colors.black.withValues(alpha: 0.4),
                  Colors.black.withValues(alpha: 0.8),
                ],
                radius: 1.0,
              ),
            ),
          ),

          // 3. Conteúdo Central
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 3),

                // Título
                Text(
                  "blocked",
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    fontSize: 64,
                    fontWeight: FontWeight.w300, // Light/Thin weight
                    letterSpacing: -2.0,
                    color: Colors.white,
                  ),
                ),

                const Spacer(flex: 2),

                // Botões
                SizedBox(
                  width: 220,
                  child: Column(
                    children: [
                      _buildMenuButton(
                        context,
                        icon: Icons.play_arrow,
                        label: "Start",
                        onTap: () => Navigator.pushNamed(context, '/game'),
                        isPrimary: true,
                      ),
                      const SizedBox(height: 16),
                      _buildMenuButton(
                        context,
                        icon: Icons.grid_view,
                        label: "Chapters",
                        onTap: () {
                          // Navegar para seleção de níveis e RESETAR o estado da seleção (opcional)
                          Navigator.of(context).pushNamed('/levels');
                        },
                      ),
                      const SizedBox(height: 16),
                      // Editor button removed as requested
                      _buildMenuButton(
                        context,
                        icon: Icons.settings_outlined,
                        label: "Settings",
                        onTap: () => Navigator.pushNamed(context, '/settings'),
                      ),
                    ],
                  ),
                ),

                const Spacer(flex: 3),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isPrimary = false,
    bool isDisabled = false,
  }) {
    final color = isPrimary
        ? const Color(0xFF4ADE80) // Green-400 (cor da referência)
        : Colors.white;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isDisabled ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDisabled
                  ? Colors.white24
                  : color.withValues(alpha: isPrimary ? 0.8 : 0.5),
              width: 1.5,
            ),
            color: isPrimary
                ? color.withValues(alpha: 0.1)
                : Colors.transparent,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: isDisabled ? Colors.white24 : color, size: 20),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  color: isDisabled ? Colors.white24 : color,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
