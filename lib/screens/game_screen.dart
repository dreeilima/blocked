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
  late GameController _controller;
  bool _dialogShown = false;

  @override
  void initState() {
    super.initState();
    _controller = GameController();
  }

  @override
  Widget build(BuildContext context) {
    // Dark theme colors
    const Color bgColor = Color(0xFF1E1E1E);
    const Color textColor = Color(0xFFE0E0E0);
    const Color accentColor = Color(0xFF8FBC8F);

    return ChangeNotifierProvider.value(
      value: _controller,
      child: Scaffold(
        backgroundColor: bgColor,
        body: SafeArea(
          child: Consumer<GameController>(
            builder: (context, controller, _) {
              // Check win condition
              if (controller.isLevelCompleted && !_dialogShown) {
                _dialogShown = true;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _showWinDialog(context);
                });
              }

              return Column(
                children: [
                  const SizedBox(height: 24),

                  // Menu Icon
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Icon(Icons.menu, color: textColor, size: 28),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Level Number
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '1-${controller.currentLevel.levelNumber}',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 32,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ),

                  // Game Board (centered)
                  Expanded(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: controller.allLevels.isEmpty
                            ? const CircularProgressIndicator(
                                color: accentColor,
                              )
                            : const AspectRatio(
                                aspectRatio: 1,
                                child: BoardWidget(),
                              ),
                      ),
                    ),
                  ),

                  // Bottom Controls
                  Padding(
                    padding: const EdgeInsets.only(
                      bottom: 48.0,
                      left: 32.0,
                      right: 32.0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        // Hint Button
                        Icon(
                          Icons.lightbulb_outline,
                          color: accentColor,
                          size: 22,
                        ),

                        const SizedBox(width: 16),

                        Container(
                          width: 1,
                          height: 20,
                          color: Colors.grey[700],
                        ),

                        const SizedBox(width: 16),

                        // Reset Button
                        InkWell(
                          onTap: () => _controller.reset(),
                          child: Row(
                            children: [
                              Icon(Icons.refresh, color: accentColor, size: 20),
                              const SizedBox(width: 6),
                              Text(
                                'Reset',
                                style: TextStyle(
                                  color: accentColor,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  void _showWinDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.8),
      builder: (ctx) => CompletionDialog(
        onNextLevel: () {
          Navigator.pop(ctx);
          _dialogShown = false;
          _controller.nextLevel();
        },
      ),
    );
  }
}
