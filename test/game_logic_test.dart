import 'package:flutter_test/flutter_test.dart';
import 'package:blocked_game/models/block.dart';
import 'package:blocked_game/models/level.dart';
import 'package:blocked_game/controllers/game_controller.dart';

void main() {
  group('Game Logic Tests', () {
    late GameController controller;

    setUp(() {
      controller = GameController();
    });

    test('Initial state loads correctly', () {
      final level = Level(
        levelNumber: 1,
        blocks: [
          Block(id: 'main', width: 2, height: 1, x: 1, y: 2, isPrimary: true),
        ],
      );
      controller.loadLevel(level);
      expect(controller.blocks.length, 1);
      expect(controller.blocks[0].x, 1);
    });

    test('Move horizontal block right - Success', () {
      final level = Level(
        levelNumber: 1,
        blocks: [
          Block(id: 'main', width: 2, height: 1, x: 1, y: 2, isPrimary: true),
        ],
      );
      controller.loadLevel(level);

      // Try move to (2, 2)
      bool moved = controller.move('main', 2, 2);
      expect(moved, true);
      expect(controller.blocks[0].x, 2);
    });

    test('Move in Y axis (now allowed for any block) - Success', () {
      final level = Level(
        levelNumber: 1,
        blocks: [
          Block(id: 'main', width: 2, height: 1, x: 1, y: 2, isPrimary: true),
        ],
      );
      controller.loadLevel(level);

      // Try move to (1, 3) - change Y (Allowed in 2D engine if space exists)
      bool moved = controller.move('main', 1, 3);
      expect(moved, true);
      expect(controller.blocks[0].y, 3);
    });

    test('Collision with another block - Fail', () {
      final level = Level(
        levelNumber: 1,
        blocks: [
          Block(
            id: 'main',
            width: 2,
            height: 1,
            x: 0,
            y: 0,
            isPrimary: true, // Needs to be active to move
          ),
          Block(id: 'obs', width: 2, height: 1, x: 2, y: 0),
        ],
      );
      controller.loadLevel(level);

      // Try move main to (1, 0) -> occupies (1,0) and (2,0).
      // (2,0) is occupied by 'obs'.
      bool moved = controller.move('main', 1, 0);
      expect(moved, false);
      expect(controller.blocks[0].x, 0); // Should stay
    });

    test('Collision with wall - Fail', () {
      final level = Level(
        levelNumber: 1,
        blocks: [
          Block(id: 'main', width: 2, height: 1, x: 4, y: 0, isPrimary: true),
        ],
        rows: 6,
        columns: 6,
      );
      controller.loadLevel(level);

      // Grid is 6x6 (indices 0..5).
      // Block at x=4 width=2 occupies 4, 5.
      // Try move to 5 -> occupies 5, 6. 6 is out of bounds.
      bool moved = controller.move('main', 5, 0);
      expect(moved, false);
    });

    test('Win condition', () {
      final level = Level(
        levelNumber: 1,
        rows: 6,
        columns: 6,
        blocks: [
          Block(id: 'main', width: 2, height: 1, x: 3, y: 2, isPrimary: true),
        ],
      );
      controller.loadLevel(level);

      // Move to edge: x=4 (occupies 4,5) width=2.
      // Grid=6. x+w = 4+2=6.
      // Win condition: primaryBlock.x + width == gridSize

      controller.move('main', 4, 2);
      expect(controller.isLevelCompleted, true);
    });
  });
}
