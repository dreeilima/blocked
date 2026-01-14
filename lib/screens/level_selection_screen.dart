import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/game_controller.dart';
import '../providers/theme_provider.dart';
import '../widgets/unlock_dialog.dart';
import '../widgets/staggered_grid_animation.dart';
import '../widgets/level_preview_widget.dart';

class LevelSelectionScreen extends StatefulWidget {
  const LevelSelectionScreen({super.key});

  @override
  State<LevelSelectionScreen> createState() => _LevelSelectionScreenState();
}

class _LevelSelectionScreenState extends State<LevelSelectionScreen>
    with TickerProviderStateMixin {
  TabController? _tabController;

  @override
  void initState() {
    super.initState();
    // Tab controller intialization deferred to didChangeDependencies
    // to access provider data safely.
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final controller = Provider.of<GameController>(context, listen: false);

    // Only initialize if not already done (or if chapters changed significantly?)
    // For now assuming chapters are static after load.
    if (_tabController == null) {
      final totalChapters = controller.totalChapters;
      // Validar indice inicial
      int initialIndex = controller.currentLevel.chapterIndex;
      if (initialIndex >= totalChapters) initialIndex = 0;

      _tabController = TabController(
        length: totalChapters,
        vsync: this,
        initialIndex: initialIndex,
      );
    }
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Re-accessing provider with listen: true to rebuild on updates
    final controller = Provider.of<GameController>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final gameColors = ThemeProvider.getGameColors(context);
    final isDark = themeProvider.effectiveThemeMode == ThemeMode.dark;

    // Safety check if controller changes totalChapters significantly
    if (_tabController != null &&
        _tabController!.length != controller.totalChapters) {
      _tabController!.dispose();
      _tabController = TabController(
        length: controller.totalChapters,
        vsync: this,
        initialIndex: 0,
      );
    }

    // Se ainda nulo por algum motivo
    if (_tabController == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Select Level"),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: gameColors.activeBlockBorder,
          labelColor: gameColors.textColor,
          unselectedLabelColor: Colors.grey,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
          indicatorSize: TabBarIndicatorSize.label,
          tabs: List.generate(controller.totalChapters, (index) {
            final names = [
              "Chapter 1",
              "Chapter 2",
              "Chapter 3",
              "Chapter 4",
              "Misc 1",
              "Misc 2",
              "Misc 3",
              "Misc 4",
            ];
            final name = index < names.length
                ? names[index]
                : "Chapter ${index + 1}";
            return Tab(text: name);
          }),
        ),
        actions: [
          // Coin Counter
          Container(
            margin: const EdgeInsets.only(right: 16.0),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: gameColors.blockFill,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: gameColors.activeBlockBorder,
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.monetization_on,
                  color: Colors.amber,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  "${controller.coins}",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: gameColors.textColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: List.generate(controller.totalChapters, (chapterIndex) {
          final chapterLevels = controller.getLevelsForChapter(chapterIndex);

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

              // Current Level Indicator
              // É o nível atual selecionado no controller E é o nível mais alto desbloqueado?
              // Ou apenas o nível onde o "cursor" do jogo está?
              // O usuário pediu "manter na qual o jogador está jogando".
              final isCurrent =
                  controller.currentLevelIndex ==
                  controller.allLevels.indexOf(level);

              return StaggeredGridAnimation(
                index: index,
                columnCount: 3,
                child: GestureDetector(
                  onTap: () {
                    if (isUnlocked) {
                      final globalIndex = controller.allLevels.indexOf(level);
                      if (globalIndex != -1) {
                        controller.loadLevelIndex(globalIndex);
                      }

                      // Consumir vida se modo desafio
                      if (controller.currentGameMode == GameMode.challenge) {
                        if (!controller.consumeLife()) {
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
                      child: LevelPreviewWidget(
                        level: level,
                        size: 100,
                        isCompleted: isCompleted,
                        isLocked: !isUnlocked,
                        isCurrent: isCurrent,
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        }),
      ),
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
