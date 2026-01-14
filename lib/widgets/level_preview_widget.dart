import 'package:flutter/material.dart';
import '../models/level.dart';
import '../providers/theme_provider.dart';

class LevelPreviewWidget extends StatelessWidget {
  final Level level;
  final double size;
  final bool isCompleted;
  final bool isLocked;
  final bool isCurrent;

  const LevelPreviewWidget({
    super.key,
    required this.level,
    this.size = 80,
    this.isCompleted = false,
    this.isLocked = false,
    this.isCurrent = false,
  });

  @override
  Widget build(BuildContext context) {
    final gameColors = ThemeProvider.getGameColors(context);

    // Calculate tile size for preview
    final double borderWidth = 2.0;
    final double padding = 2.0;
    final double contentSize = size - (borderWidth + padding) * 2;
    final double tileSize =
        contentSize / (level.columns > level.rows ? level.columns : level.rows);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: isLocked ? Colors.grey[900] : gameColors.boardBackground,
        border: Border.all(
          color: isCurrent
              ? gameColors.activeBlockBorder
              : (isLocked ? Colors.grey[800]! : gameColors.boardBorder),
          width: isCurrent ? 2.5 : 1.5,
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: isLocked
          ? Center(
              child: Icon(
                Icons.lock_outline,
                color: Colors.grey[700],
                size: size * 0.3,
              ),
            )
          : Stack(
              children: [
                // Render blocks
                Padding(
                  padding: EdgeInsets.all(borderWidth + padding),
                  child: Stack(
                    children: level.blocks
                        .where(
                          (block) => !block.isWall,
                        ) // Não renderizar paredes
                        .map((block) {
                          return Positioned(
                            left: block.x * tileSize,
                            top: block.y * tileSize,
                            width: block.width * tileSize,
                            height: block.height * tileSize,
                            child: Container(
                              margin: const EdgeInsets.all(
                                0.3,
                              ), // Espaçamento mínimo
                              decoration: BoxDecoration(
                                color: block.isWall
                                    ? gameColors.wallFill
                                    : (block.isPrimary
                                          ? gameColors.blockFill
                                          : gameColors.secondaryBlockFill),
                                border: Border.all(
                                  color: block.isWall
                                      ? gameColors.wallBorder
                                      : (block.isPrimary
                                            ? gameColors.blockBorder
                                            : gameColors.secondaryBlockBorder),
                                  width: 1.0, // Borda mais visível
                                ),
                                borderRadius: BorderRadius.circular(
                                  1,
                                ), // Cantos afiados
                              ),
                            ),
                          );
                        })
                        .toList(),
                  ),
                ),
                // Completion indicator
                if (isCompleted)
                  Positioned(
                    top: 2,
                    right: 2,
                    child: Icon(
                      Icons.check_circle,
                      color: Colors.amber,
                      size: size * 0.2,
                    ),
                  ),
                // Level number overlay
                Positioned(
                  top: 2,
                  left: 2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 3,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: Text(
                      '${level.levelInChapter}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: size * 0.12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
