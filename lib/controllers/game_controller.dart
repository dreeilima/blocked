import 'dart:convert';
import 'package:flutter/material.dart' hide Orientation;
import 'package:flutter/services.dart'; // For rootBundle
import 'package:shared_preferences/shared_preferences.dart';
import '../models/block.dart';
import '../models/level.dart';

class GameController extends ChangeNotifier {
  Level currentLevel = Level(
    levelNumber: 0,
    blocks: [],
    rows: 4,
    columns: 4,
    exitRow: 0,
  );
  List<Level> allLevels = [];
  List<Block> blocks = [];
  int moves = 0;
  bool isLevelCompleted = false;
  int currentLevelIndex = 0;
  int maxUnlockedLevel = 1;

  // Track which block is currently active (can be moved)
  String? activeBlockId;
  // Track which block is currently shaking due to collision
  String? shakingBlockId;

  GameController() {
    _init();
  }

  Future<void> _init() async {
    await loadLevels();
    await _loadProgress();
    // Always start at level 1 (index 0)
    loadLevelIndex(0);
  }

  Future<void> loadLevels() async {
    try {
      final jsonString = await rootBundle.loadString('assets/levels.json');
      final List<dynamic> jsonList = json.decode(jsonString);
      allLevels = jsonList.map((j) => Level.fromJson(j)).toList();
      notifyListeners();
    } catch (e) {
      debugPrint("Error loading levels: $e");
    }
  }

  Future<void> _loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    maxUnlockedLevel = prefs.getInt('maxUnlockedLevel') ?? 1;
  }

  Future<void> _saveProgress() async {
    if (currentLevel.levelNumber >= maxUnlockedLevel) {
      // If we just beat the latest level, unlock the next one
      // currentLevelIndex is 0-based. Level 1 is index 0.
      // If we beat level 1, we want to unlock level 2.
      int nextLevelId = currentLevel.levelNumber + 1;
      if (nextLevelId > maxUnlockedLevel) {
        maxUnlockedLevel = nextLevelId;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('maxUnlockedLevel', maxUnlockedLevel);
      }
    }
  }

  void loadLevelIndex(int index) {
    if (index < 0 || index >= allLevels.length) return;
    currentLevelIndex = index;
    loadLevel(allLevels[index]);
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
    if (block.isPrimary && block.y == currentLevel.exitRow && newY == block.y) {
      // Allow moving past the grid size
      if (newX > currentLevel.columns) return false; // Hard limit 1 step past
    } else {
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
    int dx = newX - block.x;
    int dy = newY - block.y;

    if (canMove(block, newX, newY)) {
      blocks[index] = block.copyWith(x: newX, y: newY);
      moves++;

      // Check if we touched another block (passing or sliding alongside)
      String? touchedBlockId = _findTouchedBlock(blocks[index], dx, dy);
      if (touchedBlockId != null) {
        activeBlockId = touchedBlockId;
      }

      _checkWin();
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
          // We hit 'other'. Transfer control!
          activeBlockId = other.id;
          _triggerShake(blockId); // Shake the one that hit
          notifyListeners();
          return false; // Move failed, but state changed
        }
      }
    }
    return false;
  }

  Future<void> _triggerShake(String blockId) async {
    shakingBlockId = blockId;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 300));
    if (shakingBlockId == blockId) {
      shakingBlockId = null;
      notifyListeners();
    }
  }

  // Find if the block is now adjacent to another block, BUT ONLY in the direction of movement
  String? _findTouchedBlock(Block mover, int deltaX, int deltaY) {
    // If moving UP (deltaY < 0)
    if (deltaY < 0) {
      return _findCollisionInRect(
        mover.x,
        mover.y - 1,
        mover.width,
        1,
        mover.id,
      );
    }
    // If moving DOWN (deltaY > 0)
    if (deltaY > 0) {
      return _findCollisionInRect(
        mover.x,
        mover.y + mover.height,
        mover.width,
        1,
        mover.id,
      );
    }
    // If moving LEFT (deltaX < 0)
    if (deltaX < 0) {
      return _findCollisionInRect(
        mover.x - 1,
        mover.y,
        1,
        mover.height,
        mover.id,
      );
    }
    // If moving RIGHT (deltaX > 0)
    if (deltaX > 0) {
      return _findCollisionInRect(
        mover.x + mover.width,
        mover.y,
        1,
        mover.height,
        mover.id,
      );
    }

    return null;
  }

  String? _findCollisionInRect(int x, int y, int w, int h, String excludeId) {
    for (var other in blocks) {
      if (other.id == excludeId) continue;
      if (_checkOverlap(x, y, w, h, other)) {
        return other.id;
      }
    }
    return null;
  }

  void _checkWin() {
    try {
      final primaryBlock = blocks.firstWhere((b) => b.isPrimary);
      // Win condition: Primary block reaches past the right edge
      // Assuming exit is always on the right side for now
      if (primaryBlock.x >= currentLevel.columns - 1) {
        // -1 to trigger as it starts exiting? Or fully out?
        // User said "move for out of the square".
        // If grid is 0..5 (size 6). Edge is 6.
        // If x=4, w=2. x+w=6 (at edge).
        // If x=5, w=2. x+w=7 (half out).
        // If x=6, w=2. x+w=8 (fully out).
        // Let's trigger when it's at least half out.

        if (primaryBlock.x + primaryBlock.width > currentLevel.columns) {
          if (primaryBlock.y == currentLevel.exitRow) {
            isLevelCompleted = true;
            _saveProgress();
          }
        }
      }
    } catch (e) {
      // No primary block?
    }
  }

  void reset() {
    loadLevel(currentLevel);
  }
}
