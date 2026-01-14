import 'package:flutter/material.dart' hide Orientation;
import 'package:provider/provider.dart';
import '../controllers/game_controller.dart';
import '../providers/theme_provider.dart';
import 'block_widget.dart';

class BoardWidget extends StatelessWidget {
  const BoardWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<GameController>();
    final level = controller.currentLevel;
    final gameColors = ThemeProvider.getGameColors(context);

    // Aspect ratio: width / height = columns / rows
    // e.g. 5 / 1 = 5.0 (wide strip)
    // e.g. 6 / 6 = 1.0 (square)
    return Hero(
      tag: 'board_hero_${level.levelNumber}',
      child: Material(
        color: Colors.transparent,
        child: Center(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final double borderWidth = 4.0; // Borda mais fina como original
              final double internalPadding =
                  0.0; // Sem padding interno como original
              final double totalPadding = (borderWidth + internalPadding) * 2;

              // Calculate max available size for content
              final double maxContentWidth =
                  constraints.maxWidth - totalPadding;
              final double maxContentHeight =
                  constraints.maxHeight - totalPadding;

              // Determine tile size ensuring it fits both width and height constraints
              double tileSize = maxContentWidth / level.columns;

              // If we have a height constraint, check if we need to scale down
              if (maxContentHeight.isFinite) {
                final double tileSizeH = maxContentHeight / level.rows;
                if (tileSizeH < tileSize) {
                  tileSize = tileSizeH;
                }
              }

              // Calculate final board dimensions
              final double boardWidth =
                  (level.columns * tileSize) + totalPadding;
              final double boardHeight = (level.rows * tileSize) + totalPadding;

              return SizedBox(
                width: boardWidth,
                height: boardHeight,
                child: Container(
                  color: gameColors.boardBackground,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // Top Border
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        height: borderWidth,
                        child: Container(color: gameColors.boardBorder),
                      ),
                      // Bottom Border
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        height: borderWidth,
                        child: Container(color: gameColors.boardBorder),
                      ),
                      // Left Border
                      Positioned(
                        top: 0,
                        bottom: 0,
                        left: 0,
                        width: borderWidth,
                        child: Container(color: gameColors.boardBorder),
                      ),

                      // Right Border (Split in two to make hole)
                      // Top part of right border
                      Positioned(
                        top: 0,
                        right: 0,
                        height:
                            (level.exitRow * tileSize) +
                            borderWidth +
                            internalPadding,
                        width: borderWidth,
                        child: Container(color: gameColors.boardBorder),
                      ),
                      // Bottom part of right border
                      Positioned(
                        top:
                            ((level.exitRow + 1) * tileSize) +
                            borderWidth +
                            internalPadding,
                        right: 0,
                        bottom: 0,
                        width: borderWidth,
                        child: Container(color: gameColors.boardBorder),
                      ),

                      // Blocks Layer
                      Positioned.fill(
                        top: borderWidth,
                        left: borderWidth,
                        right: borderWidth,
                        bottom: borderWidth,
                        child: Padding(
                          padding: EdgeInsets.all(internalPadding),
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: controller.blocks.map((block) {
                              final bool isActive =
                                  block.id == controller.activeBlockId;
                              final bool shouldShake =
                                  block.id == controller.shakingBlockId;

                              final bool isHinted =
                                  controller.currentHintMove != null &&
                                  controller.currentHintMove!.blockId ==
                                      block.id;

                              return AnimatedPositioned(
                                duration: const Duration(milliseconds: 120),
                                curve: Curves.easeOut,
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
                                  isHintTarget: isHinted,
                                  hintDelta: isHinted
                                      ? controller.currentHintMove!.delta
                                      : 0,
                                  onDragStart: () =>
                                      controller.setActiveBlock(block.id),
                                  onMove: (String id, int newX, int newY) {
                                    controller.move(id, newX, newY);
                                  },
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
