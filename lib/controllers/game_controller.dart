import 'dart:convert';
import 'package:flutter/material.dart' hide Orientation;
import 'package:flutter/services.dart'; // For rootBundle
import 'package:shared_preferences/shared_preferences.dart';
import '../logic/solver.dart'; // Importar Solver
import '../models/block.dart';
import '../models/level.dart';
import 'audio_controller.dart'; // Import AudioController

// Modo de jogo
enum GameMode { free, challenge }

class GameController extends ChangeNotifier {
  Level currentLevel = Level(
    levelNumber: 1,
    blocks: [],
    rows: 6,
    columns: 6,
    exitRow: 2,
    chapterIndex: 0,
    levelInChapter: 1,
  );
  List<Level> allLevels = [];

  // Getters para Capítulos
  int get totalChapters {
    if (allLevels.isEmpty) return 1;
    // Assume que os níveis estão ordenados ou scaneia o maior chapterIndex
    int maxChap = 0;
    for (var l in allLevels) {
      if (l.chapterIndex > maxChap) maxChap = l.chapterIndex;
    }
    return maxChap + 1;
  }

  List<Level> getLevelsForChapter(int chapterIndex) {
    return allLevels.where((l) => l.chapterIndex == chapterIndex).toList();
  }

  List<Block> blocks = [];
  int moves = 0;
  bool isLevelCompleted = false;
  int currentLevelIndex = 0;
  int maxUnlockedLevel = 1;
  int coins = 0;
  static const int unlockCost = 50;
  static const int freeModeReward = 10; // Modo Livre
  static const int challengeModeReward = 30; // Modo Desafio (3x)

  // Sistema de Hints
  int availableHints = 3;
  static const int maxDailyHints = 3;
  static const int hintCost = 50; // Custa 50 moedas para comprar 1 hint
  DateTime? lastHintReset;

  // Contador de movimentos do jogador
  int moveCount = 0;

  /// Calcula número de estrelas (1-3) baseado em movimentos vs ótimo
  int calculateStars(int moves, int optimalMoves) {
    if (moves <= optimalMoves) return 3; // Perfeito!
    if (moves <= (optimalMoves * 1.5).round()) return 2; // Bom
    return 1; // Completou
  }

  // Sistema de vidas (Modo Desafio)
  int challengeLives = 5;
  DateTime? lastLivesReset;
  static const int maxLives = 5;

  // Modo de jogo atual
  GameMode currentGameMode = GameMode.free;

  // Track which block is currently active (can be moved)
  String? activeBlockId;
  // Track which block is currently shaking due to collision
  String? shakingBlockId;

  // Dica Atual
  Move? currentHintMove;
  bool isCalculatingHint = false;

  // Dependência de Áudio
  AudioController? audioController;

  final bool isDemo;

  GameController({this.isDemo = false}) {
    _init();
  }

  Future<void> _init() async {
    await loadLevels();
    if (!isDemo) {
      await _loadProgress();
    } else {
      // Demo carrega niveis, mas não lê progresso do user
    }

    // Se não for demo e tivermos um nível salvo, carregar ele
    if (!isDemo && _savedLevelIndex != -1) {
      loadLevelIndex(_savedLevelIndex);
    } else {
      loadLevelIndex(0);
    }
  }

  Future<void> loadLevels() async {
    try {
      final jsonString = await rootBundle.loadString('assets/levels.json');
      final dynamic jsonData = json.decode(jsonString);
      List<dynamic> jsonList;

      if (jsonData is Map<String, dynamic> && jsonData.containsKey('levels')) {
        jsonList = jsonData['levels'];
      } else if (jsonData is List) {
        jsonList = jsonData;
      } else {
        jsonList = [];
      }

      allLevels = jsonList.map((j) => Level.fromJson(j)).toList();
      notifyListeners();
    } catch (e) {
      debugPrint("Error loading levels: $e");
    }
  }

  int _savedLevelIndex = -1;

  Future<void> _loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    maxUnlockedLevel = prefs.getInt('maxUnlockedLevel') ?? 1;
    coins = prefs.getInt('coins') ?? 0;
    _savedLevelIndex = prefs.getInt('lastPlayedLevelIndex') ?? 0;

    // Carregar vidas e verificar reset diário
    challengeLives = prefs.getInt('challengeLives') ?? maxLives;
    final lastResetString = prefs.getString('lastLivesReset');
    if (lastResetString != null) {
      lastLivesReset = DateTime.parse(lastResetString);
      _checkDailyReset();
    }

    // Carregar hints e verificar reset diário
    availableHints = prefs.getInt('availableHints') ?? maxDailyHints;
    final lastHintResetString = prefs.getString('lastHintReset');
    if (lastHintResetString != null) {
      lastHintReset = DateTime.parse(lastHintResetString);
      _checkDailyHintReset();
    } else {
      // Primeira vez ou novo sistema: garantir reset inicial
      _checkDailyHintReset();
    }

    notifyListeners();
  }

  Future<void> _saveProgress() async {
    if (isDemo) return; // Não salvar nada se for demo

    if (currentLevel.levelNumber >= maxUnlockedLevel) {
      // If we just beat the latest level, unlock the next one
      int nextLevelId = currentLevel.levelNumber + 1;
      if (nextLevelId > maxUnlockedLevel) {
        maxUnlockedLevel = nextLevelId;
      }
    }
    // Save everything
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('maxUnlockedLevel', maxUnlockedLevel);
    await prefs.setInt('lastPlayedLevelIndex', currentLevelIndex);
    await prefs.setInt('coins', coins);
    await prefs.setInt('challengeLives', challengeLives);
    if (lastLivesReset != null) {
      await prefs.setString(
        'lastLivesReset',
        lastLivesReset!.toIso8601String(),
      );
    }

    await prefs.setInt('availableHints', availableHints);
    if (lastHintReset != null) {
      await prefs.setString('lastHintReset', lastHintReset!.toIso8601String());
    }
  }

  void loadLevelIndex(int index) {
    if (index < 0 || index >= allLevels.length) return;
    currentLevelIndex = index;
    loadLevel(allLevels[index]);
    // Salvar que carregamos este nível (se não for demo)
    if (!isDemo) {
      _saveProgress();
    }
  }

  void nextLevel() {
    if (currentLevelIndex + 1 < allLevels.length) {
      loadLevelIndex(currentLevelIndex + 1);
    }
  }

  void loadLevel(Level level) {
    currentLevel = level;
    // Deep copy blocks so we don't mutate the level definition
    blocks = level.blocks.map((b) => b.copyWith()).toList();
    moves = 0;
    moveCount = 0; // Reset contador de movimentos
    isLevelCompleted = false;
    // Set the primary block as active initially
    activeBlockId = blocks
        .firstWhere((b) => b.isPrimary, orElse: () => blocks.first)
        .id;
    notifyListeners();
  }

  bool canMove(Block block, int newX, int newY) {
    // 1. Check boundaries
    if (newX < 0 || newY < 0) return false;

    // Special case: Primary block can exit to the right
    if (block.isPrimary && block.y == currentLevel.exitRow && newX >= block.x) {
      // Movendo para direita
      // Permite sair completamente do tabuleiro
      // Limite: pode ir até columns + width (para sair totalmente)
      if (newX > currentLevel.columns + block.width) return false;
    } else {
      // Normal boundary check
      if (newX + block.width > currentLevel.columns) return false;
    }

    if (newY + block.height > currentLevel.rows) return false;

    // 2. Check collisions with other blocks
    for (var other in blocks) {
      if (other.id == block.id) continue; // Don't check against self

      // Check overlap using 2D AABB collision
      if (_checkOverlap(newX, newY, block.width, block.height, other)) {
        return false;
      }
    }

    return true;
  }

  bool _checkOverlap(int x1, int y1, int w1, int h1, Block other) {
    // AABB Collision Detection
    // Rect 1: x1, y1, w1, h1
    // Rect 2: other.x, other.y, other.width, other.height

    return x1 < other.x + other.width &&
        x1 + w1 > other.x &&
        y1 < other.y + other.height &&
        y1 + h1 > other.y;
  }

  /// Attempts to move the block to the new position.
  /// Returns check if the move was successful.
  bool move(String blockId, int newX, int newY) {
    // Only allow moving the active block
    if (blockId != activeBlockId) return false;

    final index = blocks.indexWhere((b) => b.id == blockId);
    if (index == -1) return false;

    final block = blocks[index];

    // Optimization: if position hasn't changed, do nothing
    if (block.x == newX && block.y == newY) return true;

    // Check for collision-based transfer even if move is blocked

    if (canMove(block, newX, newY)) {
      blocks[index] = block.copyWith(x: newX, y: newY);
      moves++;
      moveCount++; // Incrementar contador de movimentos

      _checkWin();

      // Se moveu, limpar a dica
      if (currentHintMove != null && blockId == currentHintMove!.blockId) {
        currentHintMove = null;
      }

      // Feedback Sensorial
      HapticFeedback.lightImpact();
      audioController?.playMove();

      notifyListeners();
      return true;
    } else {
      // Move failed (likely collision). Check if we hit a block directly.
      // We simulate the moved rect to see what we WOULD have hit.
      // Actually, we can just use _findTouchedBlock with the current block
      // but projecting intention? No, _findTouchedBlock looks at adjacent.

      // Better: Check what block is occupying the target space (newX, newY)
      // Since we know we can't move there.

      for (var other in blocks) {
        if (other.id == blockId) continue;
        // If the target position overlaps with 'other', we hit it
        if (_checkOverlap(newX, newY, block.width, block.height, other)) {
          _triggerShake(blockId); // Shake the one that hit (always)

          // Só transfere controle se NÃO for parede
          if (!other.isWall) {
            // We hit a movable block. Transfer control!
            activeBlockId = other.id;
          } else {
            // Hit a wall. Just sound effect maybe?
            HapticFeedback.heavyImpact();
          }

          notifyListeners();
          return false; // Move failed, but state changed
        }
      }
    }
    return false;
  }

  Future<void> _triggerShake(String blockId) async {
    HapticFeedback.mediumImpact();
    shakingBlockId = blockId;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 300));
    if (shakingBlockId == blockId) {
      shakingBlockId = null;
      notifyListeners();
    }
  }

  // === Sistema de Vidas ===

  /// Verifica se precisa resetar vidas (novo dia)
  void _checkDailyReset() {
    if (lastLivesReset == null) {
      _resetDailyLives();
      return;
    }

    final now = DateTime.now();
    final lastReset = lastLivesReset!;

    // Se mudou o dia, resetar vidas
    if (now.year != lastReset.year ||
        now.month != lastReset.month ||
        now.day != lastReset.day) {
      _resetDailyLives();
    }
  }

  /// Reseta vidas para o máximo
  void _resetDailyLives() {
    challengeLives = maxLives;
    lastLivesReset = DateTime.now();
    _saveProgress();
    notifyListeners();
  }

  /// Consome uma vida (modo desafio)
  bool consumeLife() {
    if (challengeLives > 0) {
      challengeLives--;
      _saveProgress();
      notifyListeners();
      return true;
    }
    return false;
  }

  /// Define o modo de jogo
  void setGameMode(GameMode mode) {
    currentGameMode = mode;
    notifyListeners();
  }

  void setActiveBlock(String? id) {
    activeBlockId = id;
    notifyListeners();
  }

  void clearActiveBlock() {
    activeBlockId = null;
    notifyListeners();
  }

  void _checkWin() {
    try {
      final primaryBlock = blocks.firstWhere(
        (b) => b.isPrimary,
        orElse: () => throw StateError('No primary block found'),
      );
      // Win condition: Primary block reaches the exit column
      // Simplificado: ganha quando o bloco chega na última coluna da saída
      if (primaryBlock.x + primaryBlock.width >= currentLevel.columns) {
        if (primaryBlock.y == currentLevel.exitRow) {
          isLevelCompleted = true;

          // Feedback
          audioController?.playWin();
          HapticFeedback.heavyImpact();

          // Recompensa baseada no modo de jogo
          final reward = currentGameMode == GameMode.challenge
              ? challengeModeReward
              : freeModeReward;
          addCoins(reward);

          _saveProgress();
          notifyListeners();
        }
      }
    } on StateError catch (e) {
      debugPrint('No primary block in level ${currentLevel.levelNumber}: $e');
    } catch (e) {
      debugPrint('Error in _checkWin: $e');
    }
  }

  void reset() {
    loadLevel(currentLevel);
  }

  void addCoins(int amount) {
    coins += amount;
    _saveProgress();
    notifyListeners();
  }

  bool unlockNextLevel() {
    if (coins >= unlockCost) {
      coins -= unlockCost;
      maxUnlockedLevel++;
      _saveProgress();
      notifyListeners();
      return true;
    }
    return false;
  }

  // === Sistema de Hints ===

  /// Verifica se precisa resetar hints (novo dia)
  void _checkDailyHintReset() {
    if (lastHintReset == null) {
      _resetDailyHints();
      return;
    }

    final now = DateTime.now();
    final lastReset = lastHintReset!;

    // Se mudou o dia, resetar hints
    if (now.year != lastReset.year ||
        now.month != lastReset.month ||
        now.day != lastReset.day) {
      _resetDailyHints();
    }
  }

  /// Reseta hints para o máximo (apenas se for menor que o diário)
  // Nota: Hints comprados podem acumular acima do diário,
  // mas o reset gratuito só leva até maxDailyHints.
  void _resetDailyHints() {
    if (availableHints < maxDailyHints) {
      availableHints = maxDailyHints;
    }
    lastHintReset = DateTime.now();
    _saveProgress(); // Salva estado inicial
  }

  /// Consome uma dica
  bool useHint() {
    if (availableHints > 0) {
      if (isCalculatingHint) return false;

      availableHints--;
      _saveProgress(); // Salvar consumo

      _calculateHint();

      notifyListeners();
      return true;
    }
    return false;
  }

  Future<void> _calculateHint() async {
    isCalculatingHint = true;
    notifyListeners();

    // Simular processamento (yield)
    await Future.delayed(Duration.zero);

    try {
      // Criar nível temporário com estado ATUAL
      final tempLevel = Level(
        levelNumber: currentLevel.levelNumber,
        blocks: List.of(blocks), // Cópia dos blocos atuais
        rows: currentLevel.rows,
        columns: currentLevel.columns,
        exitRow: currentLevel.exitRow,
        chapterIndex: currentLevel.chapterIndex,
        levelInChapter: currentLevel.levelInChapter,
      );

      final solver = Solver(tempLevel);
      // Limitar iterações para não travar UI
      final solution = solver.solve(
        maxIterations: 10000,
      ); // 10k deve ser rápido o suficiente

      if (solution != null && solution.isNotEmpty) {
        currentHintMove = solution.first;
        // debugPrint("Hint found: $currentHintMove");

        // Auto-limpar após 5 segundos se não usado
        Future.delayed(const Duration(seconds: 5), () {
          if (currentHintMove != null) {
            currentHintMove = null;
            notifyListeners(); // Atualizar UI para remover destaque
          }
        });
      } else {
        debugPrint("No solution found by solver.");
      }
    } catch (e) {
      debugPrint("Solver error: $e");
    }

    isCalculatingHint = false;
    notifyListeners();
  }

  /// Compra dicas com moedas
  bool buyHint() {
    if (coins >= hintCost) {
      coins -= hintCost;
      availableHints++;
      _saveProgress();
      notifyListeners();
      return true;
    }
    return false;
  }
}
