import 'package:flutter/material.dart' hide Orientation;
import 'package:provider/provider.dart';
import '../controllers/game_controller.dart';
import 'block_widget.dart';

class BoardWidget extends StatelessWidget {
  const BoardWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<GameController>();
    final level = controller.currentLevel;

    // Aspect ratio: width / height = columns / rows
    // e.g. 5 / 1 = 5.0 (wide strip)
    // e.g. 6 / 6 = 1.0 (square)
    return Center(
      child: AspectRatio(
        aspectRatio: level.columns / level.rows,
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Calculate tile size based on available width
            final double tileSize = constraints.maxWidth / level.columns;
            final double borderWidth = 10.0;

            // Manual Border Construction to allow gaps
            return Container(
              color: const Color(0xFF2A3A3A), // Board background
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Top Border
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: borderWidth,
                    child: Container(color: const Color(0xFF5A6A6A)),
                  ),
                  // Bottom Border
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    height: borderWidth,
                    child: Container(color: const Color(0xFF5A6A6A)),
                  ),
                  // Left Border
                  Positioned(
                    top: 0,
                    bottom: 0,
                    left: 0,
                    width: borderWidth,
                    child: Container(color: const Color(0xFF5A6A6A)),
                  ),

                  // Right Border (Split in two to make hole)
                  // Top part of right border
                  Positioned(
                    top: 0,
                    right: 0,
                    height:
                        (level.exitRow * tileSize), // Extend just to tile start
                    width: borderWidth,
                    child: Container(color: const Color(0xFF5A6A6A)),
                  ),
                  // Bottom part of right border
                  Positioned(
                    top:
                        (level.exitRow + 1) * tileSize, // Start after exit tile
                    right: 0,
                    bottom: 0,
                    width: borderWidth,
                    child: Container(color: const Color(0xFF5A6A6A)),
                  ),

                  // Exit Indication (faint line or arrow?)
                  // Let's keep it clean for now, just the hole.

                  // Blocks Layer (shifted by borderWidth to be inside)
                  Positioned.fill(
                    top: borderWidth,
                    left: borderWidth,
                    right: borderWidth,
                    bottom: borderWidth,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: controller.blocks.map((block) {
                        final bool isActive =
                            block.id == controller.activeBlockId;
                        final bool shouldShake =
                            block.id == controller.shakingBlockId;

                        return AnimatedPositioned(
                          duration: const Duration(milliseconds: 120),
                          curve: Curves.easeOut,
                          // Use inner coordinates
                          left: block.x * tileSize,
                          top: block.y * tileSize,
                          width: block.width * tileSize,
                          height: block.height * tileSize,
                          child: BlockWidget(
                            key: ValueKey(block.id),
                            block: block,
                            tileSize: tileSize,
                            isActive: isActive,
                            shouldShake: shouldShake,
                            onMove: (String id, int newX, int newY) {
                              controller.move(id, newX, newY);
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
