import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/game_controller.dart';
import '../providers/theme_provider.dart';
import '../widgets/unlock_dialog.dart';
import '../widgets/staggered_grid_animation.dart';

class LevelSelectionScreen extends StatelessWidget {
  const LevelSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final gameColors = ThemeProvider.getGameColors(context);
    final isDark = themeProvider.effectiveThemeMode == ThemeMode.dark;

    return Consumer<GameController>(
      builder: (context, controller, child) {
        final totalChapters = controller.totalChapters;

        return DefaultTabController(
          length: totalChapters,
          child: Scaffold(
            appBar: AppBar(
              title: const Text("Select Level"),
              bottom: TabBar(
                isScrollable: true,
                indicatorColor: gameColors.activeBlockBorder,
                labelColor: gameColors.textColor,
                unselectedLabelColor: Colors.grey,
                tabs: List.generate(totalChapters, (index) {
                  // Nomes temáticos poderiam vir de um mapa/array no Controller
                  final names = ["Tutorial", "Advanced", "Master", "Insane"];
                  final name = index < names.length
                      ? names[index]
                      : "World ${index + 1}";
                  return Tab(text: name);
                }),
              ),
              actions: [
                // Coin Counter
                Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: Row(
                    children: [
                      const Icon(Icons.monetization_on, color: Colors.amber),
                      const SizedBox(width: 4),
                      Text(
                        "${controller.coins}",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            body: TabBarView(
              children: List.generate(totalChapters, (chapterIndex) {
                final chapterLevels = controller.getLevelsForChapter(
                  chapterIndex,
                );

                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1,
                  ),
                  itemCount: chapterLevels.length,
                  itemBuilder: (context, index) {
                    final level = chapterLevels[index];
                    final levelNum = level.levelNumber; // ID global
                    final displayNum = level.levelInChapter;

                    // Locked logic (usando ID global)
                    final isUnlocked = levelNum <= controller.maxUnlockedLevel;
                    final isCompleted = levelNum < controller.maxUnlockedLevel;

                    return StaggeredGridAnimation(
                      index: index,
                      columnCount: 3,
                      child: GestureDetector(
                        onTap: () {
                          if (isUnlocked) {
                            // Encontrar o índice global correto na lista allLevels
                            // ou criar um método loadLevelById no controller
                            // Como loadLevelIndex usa indice da lista allLevels, precisamos achar o indice desse level
                            final globalIndex = controller.allLevels.indexOf(
                              level,
                            );
                            if (globalIndex != -1) {
                              controller.loadLevelIndex(globalIndex);
                            }

                            // Consumir vida se modo desafio
                            if (controller.currentGameMode ==
                                GameMode.challenge) {
                              if (!controller.consumeLife()) {
                                // Sem vidas!
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'No lives left! Come back tomorrow or switch to Free Mode.',
                                    ),
                                    duration: Duration(seconds: 3),
                                  ),
                                );
                                return;
                              }
                            }

                            Navigator.pushNamed(context, '/game');
                          } else {
                            _showUnlockDialog(context, controller, levelNum);
                          }
                        },
                        child: Hero(
                          tag: 'board_hero_$levelNum',
                          child: Material(
                            color: Colors.transparent,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              decoration: BoxDecoration(
                                color: isUnlocked
                                    ? gameColors.blockFill
                                    : (isDark
                                          ? Colors.grey[800]
                                          : Colors.grey[300]),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isUnlocked
                                      ? gameColors.activeBlockBorder
                                      : Colors.grey,
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: isUnlocked
                                    ? (isCompleted
                                          ? Stack(
                                              alignment: Alignment.center,
                                              children: [
                                                Text(
                                                  "$displayNum",
                                                  style: TextStyle(
                                                    fontSize: 24,
                                                    fontWeight: FontWeight.bold,
                                                    color: gameColors.textColor
                                                        .withValues(alpha: 0.3),
                                                  ),
                                                ),
                                                Icon(
                                                  Icons.check_circle,
                                                  color: gameColors
                                                      .activeBlockBorder,
                                                  size: 32,
                                                ),
                                              ],
                                            )
                                          : Text(
                                              "$displayNum",
                                              style: TextStyle(
                                                fontSize: 24,
                                                fontWeight: FontWeight.bold,
                                                color: gameColors.textColor,
                                              ),
                                            ))
                                    : const Icon(
                                        Icons.lock,
                                        size: 32,
                                        color: Colors.grey,
                                      ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              }),
            ),
          ),
        );
      },
    );
  }

  void _showUnlockDialog(
    BuildContext context,
    GameController controller,
    int levelNum,
  ) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) =>
          UnlockDialog(levelNum: levelNum, controller: controller),
    );
  }
}
