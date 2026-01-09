import 'block.dart';

class Level {
  final int levelNumber;
  final List<Block> blocks;
  // Support non-square grids
  final int rows;
  final int columns;
  final int exitRow;

  const Level({
    required this.levelNumber,
    required this.blocks,
    this.rows = 6,
    this.columns = 6,
    this.exitRow = 2,
  });

  factory Level.fromJson(Map<String, dynamic> json) {
    final list = json['blocks'] as List;
    final blocks = list.map((b) => Block.fromJson(b)).toList();

    // Legacy support: if 'gridSize' exists, use it for both rows and cols
    int r = 6;
    int c = 6;
    if (json.containsKey('gridSize')) {
      r = json['gridSize'] as int;
      c = json['gridSize'] as int;
    }
    // Explicit override
    if (json.containsKey('rows')) r = json['rows'] as int;
    if (json.containsKey('columns')) c = json['columns'] as int;

    return Level(
      levelNumber: json['id'] as int,
      blocks: blocks,
      rows: r,
      columns: c,
      exitRow: json['exitRow'] as int? ?? 2,
    );
  }
}
