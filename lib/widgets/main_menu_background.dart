import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/game_controller.dart';
import '../logic/solver.dart';
import '../models/level.dart';
import '../widgets/board_widget.dart';

class MainMenuBackground extends StatefulWidget {
  const MainMenuBackground({super.key});

  @override
  State<MainMenuBackground> createState() => _MainMenuBackgroundState();
}

class _MainMenuBackgroundState extends State<MainMenuBackground>
    with SingleTickerProviderStateMixin {
  late GameController _demoController;
  late AnimationController _rotationController;
  Timer? _gameLoopTimer;
  bool _isDisposed = false;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _demoController = GameController();

    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 120), // Rotação bem lenta
    )..repeat();

    _initDemo();
  }

  Future<void> _initDemo() async {
    await _demoController.loadLevels();
    if (_isDisposed) return;
    _loadRandomLevel();
    _startGameLoop();
  }

  void _loadRandomLevel() {
    if (_demoController.allLevels.isEmpty) return;
    int index = _random.nextInt(_demoController.allLevels.length);
    _demoController.loadLevelIndex(index);
  }

  void _startGameLoop() {
    _gameLoopTimer = Timer.periodic(const Duration(milliseconds: 700), (timer) {
      if (_isDisposed || !mounted) {
        timer.cancel();
        return;
      }
      _performAutoMove();
    });
  }

  Future<void> _performAutoMove() async {
    final level = _demoController.currentLevel;
    // Checar vitória
    try {
      final primary = _demoController.blocks.firstWhere((b) => b.isPrimary);
      if (primary.x + primary.width == level.columns) {
        _gameLoopTimer?.cancel();
        // Espera um pouco e troca
        await Future.delayed(const Duration(seconds: 2));
        if (_isDisposed) return;
        _loadRandomLevel();
        _startGameLoop();
        return;
      }
    } catch (_) {}

    // Solver
    final tempLevel = Level(
      levelNumber: level.levelNumber,
      blocks: List.of(_demoController.blocks),
      rows: level.rows,
      columns: level.columns,
      exitRow: level.exitRow,
      chapterIndex: level.chapterIndex,
      levelInChapter: level.levelInChapter,
    );

    final solver = Solver(tempLevel);
    // Timeout para não travar
    final solution = solver.solve(maxIterations: 1000);

    if (solution != null && solution.isNotEmpty) {
      final move = solution.first;
      _demoController.move(move.blockId, move.endX, move.endY);
    } else {
      // Se travou, troca nivel
      _loadRandomLevel();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _gameLoopTimer?.cancel();
    _rotationController.dispose();
    _demoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _demoController,
      child: Stack(
        children: [
          // Cor de fundo base
          Container(color: const Color(0xFF18181B)), // Cinza escuro premium
          // Tabuleiro
          Center(
            child: AnimatedBuilder(
              animation: _rotationController,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _rotationController.value * 2 * pi,
                  child: Transform.scale(
                    scale: 0.9,
                    child: Opacity(
                      opacity: 0.25, // Translucido
                      child: IgnorePointer(child: const BoardWidget()),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
