import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/game_controller.dart';
import '../widgets/board_widget.dart';
import '../widgets/completion_dialog.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  bool _dialogShown = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Cores baseadas no tema
    final textColor = theme.textTheme.displayLarge?.color ?? Colors.white;
    final subtextColor = textColor.withValues(alpha: 0.7);

    // Controller
    final controller = Provider.of<GameController>(context);

    // Win Logic
    if (controller.isLevelCompleted && !_dialogShown) {
      _dialogShown = true;
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _showWinDialog(context),
      );
    }
    if (!controller.isLevelCompleted) _dialogShown = false;

    // Font styles
    final titleStyle =
        theme.textTheme.displayLarge?.copyWith(
          fontSize: 64, // Bem grande como na referência
          fontWeight: FontWeight.w300,
          height: 1.0,
        ) ??
        const TextStyle(fontSize: 64, fontWeight: FontWeight.w300);

    final tutorialStyle = theme.textTheme.bodyLarge?.copyWith(
      fontSize: 18,
      color: subtextColor,
      fontWeight: FontWeight.w400,
    );

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Menu Button (Top Left)
              IconButton(
                icon: const Icon(Icons.menu), // Icone hamburger
                padding: EdgeInsets.zero,
                alignment: Alignment.centerLeft,
                iconSize: 28,
                color: textColor,
                onPressed: () => Navigator.pop(context),
              ),

              const SizedBox(height: 24),

              // 2. Level Title "1-1"
              Text(
                '${controller.currentLevel.chapterIndex + 1}-${controller.currentLevel.levelInChapter}',
                style: titleStyle,
              ),

              const SizedBox(height: 8),

              // 3. Tutorial Text (se houver)
              if (controller.currentLevel.tutorialText != null)
                Text(
                  controller.currentLevel.tutorialText!,
                  style: tutorialStyle,
                )
              else
                // Placeholder invisible para manter espaçamento se quiser, ou nada.
                const SizedBox(height: 0),

              const Spacer(), // Empurra o board para o centro/baixo relativo
              // 4. Board
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: const AspectRatio(
                    aspectRatio: 1,
                    child: BoardWidget(),
                  ),
                ),
              ),

              const Spacer(),

              // 5. Footer Controls (Hint | Reset)
              Padding(
                padding: const EdgeInsets.only(bottom: 24.0),
                child: Row(
                  children: [
                    // Hint Button (Icon only style based on mock)
                    InkWell(
                      onTap: () => _handleHint(context, controller),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Icon(
                          Icons.lightbulb_outline,
                          color: controller.availableHints > 0
                              ? textColor
                              : textColor.withValues(alpha: 0.3),
                          size: 28,
                        ),
                      ),
                    ),

                    // Vertical Divider
                    Container(
                      height: 24,
                      width: 1,
                      color: subtextColor.withValues(alpha: 0.3),
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                    ),

                    // Reset Button (Icon + Text)
                    InkWell(
                      onTap: () {
                        _dialogShown = false;
                        controller.reset();
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          children: [
                            Icon(
                              Icons.refresh,
                              color: theme.colorScheme.primary,
                              size: 24,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "Reset",
                              style: TextStyle(
                                color: theme.colorScheme.primary,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleHint(BuildContext context, GameController controller) {
    if (controller.availableHints > 0) {
      controller.useHint();
    } else {
      // Show dialog standard
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Need a Hint?'),
          content: Text('Buy for 50 coins? (You have ${controller.coins})'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (controller.buyHint()) {
                  Navigator.pop(context);
                  controller.useHint();
                } else {
                  Navigator.pop(context);
                }
              },
              child: const Text('Buy'),
            ),
          ],
        ),
      );
    }
  }

  void _showWinDialog(BuildContext context) {
    final controller = Provider.of<GameController>(context, listen: false);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => CompletionDialog(
        moveCount: controller.moveCount,
        stars: controller.calculateStars(
          controller.moveCount,
          controller.currentLevel.optimalMoves,
        ),
        onReplay: () {
          Navigator.pop(context);
          controller.reset();
        },
        onMenu: () {
          Navigator.pop(context);
          Navigator.pop(context);
        },
        onNextLevel: () {
          Navigator.pop(context);
          controller.nextLevel();
        },
      ),
    );
  }
}
