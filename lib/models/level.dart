import 'block.dart';

class Level {
  final int levelNumber;
  final List<Block> blocks;
  // Support non-square grids
  final int rows;
  final int columns;
  final int exitRow;
  final int optimalMoves; // Número ótimo de movimentos para 3 estrelas
  final String? tutorialText; // Texto opcional de tutorial

  // Novo sistema de Capítulos
  final int chapterIndex; // 0-based: 0 = Cap 1, 1 = Cap 2
  final int
  levelInChapter; // 1-based: Nível dentro do capítulo (ex: 1, 2, 3...)

  Level({
    required this.levelNumber,
    required this.blocks,
    required this.rows,
    required this.columns,
    required this.exitRow,
    required this.chapterIndex,
    required this.levelInChapter,
    this.optimalMoves = 0,
    this.tutorialText,
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

    // Leitura do Capítulo (com fallback para Cap 1)
    int chap = 0;
    if (json.containsKey('chapterIndex')) chap = json['chapterIndex'] as int;

    // Leitura do nível no capítulo (fallback para id)
    int lvlInChap = json['id'] as int;
    if (json.containsKey('levelInChapter'))
      lvlInChap = json['levelInChapter'] as int;

    return Level(
      levelNumber: json['id'] as int,
      blocks: blocks,
      rows: r,
      columns: c,
      exitRow: json['exitRow'] as int,
      optimalMoves: json.containsKey('optimalMoves')
          ? json['optimalMoves'] as int
          : 10,
      chapterIndex: chap,
      levelInChapter: lvlInChap,
    );
  }
}
