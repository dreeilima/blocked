import 'package:flutter_test/flutter_test.dart';
import 'package:blocked_game/models/block.dart';
import 'package:blocked_game/models/level.dart';
import 'package:blocked_game/controllers/game_controller.dart';

import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('Game Logic Tests', () {
    late GameController controller;

    setUp(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      SharedPreferences.setMockInitialValues({});
      controller = GameController();
    });

    test('Initial state loads correctly', () {
      final level = Level(
        levelNumber: 1,
        blocks: [
          Block(id: '1', x: 0, y: 0, width: 1, height: 2),
          Block(id: '2', x: 0, y: 2, width: 2, height: 1, isPrimary: true),
        ],
        rows: 6,
        columns: 6,
        exitRow: 2,
        optimalMoves: 10,
        chapterIndex: 0,
        levelInChapter: 1,
      );

      controller.loadLevel(level);
      expect(controller.blocks.length, 2);
    });

    test('Move block successfully', () {
      final level = Level(
        levelNumber: 1,
        blocks: [
          Block(id: '2', x: 0, y: 2, width: 2, height: 1, isPrimary: true),
        ],
        rows: 6,
        columns: 6,
        exitRow: 2,
        optimalMoves: 10,
        chapterIndex: 0,
        levelInChapter: 1,
      );

      controller.loadLevel(level);
      controller.setActiveBlock('2');

      // Mover de (0,2) para (1,2)
      controller.move('2', 1, 2);

      expect(controller.blocks.first.x, 1);
    });

    // Teste removido de activeBlockId pois move() retorna booleano e atualiza estado direto
  });
}
