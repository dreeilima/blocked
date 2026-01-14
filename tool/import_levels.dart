import 'dart:convert';
import 'dart:io';

// Script to import levels from jeffsieu.com level editor format (YAML)
// and solutions (JSON) into our simplified JSON format.

void main() async {
  final levelsFile = File('assets/levels.yaml.raw');
  final solutionsFile = File('assets/solutions.json.raw');
  final outputFile = File('assets/levels.json');

  if (!levelsFile.existsSync()) {
    print('Error: assets/levels.yaml.raw not found.');
    return;
  }

  String yamlContent = await levelsFile.readAsString();
  Map<String, int> optimalMovesMap = {};

  if (solutionsFile.existsSync()) {
    try {
      final solsJson = jsonDecode(await solutionsFile.readAsString());
      if (solsJson is Map && solsJson.containsKey('chapters')) {
        for (var chap in solsJson['chapters']) {
          if (chap['levels'] != null) {
            for (var lvl in chap['levels']) {
              if (lvl['name'] != null && lvl['solution'] != null) {
                String sol = lvl['solution'];
                optimalMovesMap[lvl['name']] = sol.length;
              }
            }
          }
        }
      }
    } catch (e) {
      print('Warning: Could not parse solutions.json: $e');
    }
  }

  List<Map<String, dynamic>> outputLevels = [];
  int globalId = 1;
  int currentChapterIndex = 0;

  // Use regex to split lines safely handling Windows/Unix line endings
  List<String> lines = const LineSplitter().convert(yamlContent);

  String? currentChapterName;
  String? currentLevelName;
  List<String> currentMapLines = [];
  bool readingMap = false;

  print("Total lines to parse: ${lines.length}");

  for (int i = 0; i < lines.length; i++) {
    String line = lines[i];
    if (line.trim().isEmpty && !readingMap) continue;

    String trimmed = line.trim();

    // Check for Chapter: "- name: ..." (at root level)
    // We assume root level means no indentation or very specific patterns.
    // In YAML, root list items start with "- ".
    if (line.startsWith('- name:')) {
      currentChapterName = line.substring(7).trim();
      print("Found Chapter: $currentChapterName");

      if (currentChapterName == 'misc1')
        currentChapterIndex = 4;
      else if (currentChapterName == 'misc2')
        currentChapterIndex = 5;
      else if (currentChapterName == 'misc3')
        currentChapterIndex = 6;
      else if (currentChapterName == 'misc4')
        currentChapterIndex = 7;
      else if (int.tryParse(currentChapterName!) != null) {
        currentChapterIndex = int.parse(currentChapterName!) - 1;
      }
      continue;
    }

    // Check for Level: "    - name: ..." (indented)
    if (trimmed.startsWith('- name:') &&
        (line.startsWith(' ') || line.startsWith('\t'))) {
      // Save previous level if pending
      if (currentLevelName != null && currentMapLines.isNotEmpty) {
        _saveLevel(
          outputLevels,
          globalId,
          currentChapterIndex,
          currentLevelName,
          currentMapLines,
          optimalMovesMap,
        );
        globalId++;
        currentLevelName = null;
        currentMapLines = [];
      }

      currentLevelName = trimmed.substring(7).trim();
      readingMap = false;
      continue;
    }

    if (trimmed.startsWith('map: |-')) {
      readingMap = true;
      currentMapLines = [];
      continue;
    }

    if (readingMap) {
      // Logic: If line is indented more than the map key, it belongs to block scalar.
      // But typically check if it's NOT a new key.
      bool isKey =
          trimmed.startsWith('- name:') ||
          trimmed.startsWith('hint:') ||
          trimmed.startsWith('description:') ||
          trimmed.startsWith('levels:');

      if (isKey) {
        readingMap = false;
        // We hit a key, so map ended.
        // We need to re-process this line in the main loop logic (decrement i?)
        // Or just let the next iteration handle it?
        // IF we continue here without processing, we skip this key logic.
        // So we should break map reading and re-evaluate 'trimmed' logic.
        // Or simpler: save level now.
        if (currentLevelName != null && currentMapLines.isNotEmpty) {
          _saveLevel(
            outputLevels,
            globalId,
            currentChapterIndex,
            currentLevelName,
            currentMapLines,
            optimalMovesMap,
          );
          globalId++;
          currentLevelName = null;
          currentMapLines = [];
        }

        // Re-evaluate current line context
        if (trimmed.startsWith('- name:') &&
            (line.startsWith(' ') || line.startsWith('\t'))) {
          currentLevelName = trimmed.substring(7).trim();
        } else if (line.startsWith('- name:')) {
          currentChapterName = line.substring(7).trim();
          print("Found Chapter (after map): $currentChapterName");
          if (currentChapterName == 'misc1')
            currentChapterIndex = 4;
          else if (int.tryParse(currentChapterName!) != null) {
            currentChapterIndex = int.parse(currentChapterName!) - 1;
          }
        }
      } else {
        // Collect map line
        if (line.trim().isNotEmpty) {
          currentMapLines.add(line);
        }
      }
    }
  }

  // Flush last level
  if (currentLevelName != null && currentMapLines.isNotEmpty) {
    _saveLevel(
      outputLevels,
      globalId,
      currentChapterIndex,
      currentLevelName,
      currentMapLines,
      optimalMovesMap,
    );
  }

  String jsonOutput = JsonEncoder.withIndent(
    '  ',
  ).convert({'levels': outputLevels});
  await outputFile.writeAsString(jsonOutput);
  print(
    'Successfully exported ${outputLevels.length} levels to assets/levels.json',
  );
}

void _saveLevel(
  List<Map<String, dynamic>> output,
  int id,
  int chapterIndex,
  String? name,
  List<String> mapLines,
  Map<String, int> optimalMovesMap,
) {
  if (name == null) return;
  var processed = processLevel(
    id,
    chapterIndex,
    name,
    mapLines,
    optimalMovesMap[name] ?? 12,
  );
  output.add(processed);
}

Map<String, dynamic> processLevel(
  int id,
  int chapterIndex,
  String name,
  List<String> rawMapLines,
  int optimalMoves,
) {
  // Trim indentation
  int minIndent = 999;
  for (var line in rawMapLines) {
    if (line.trim().isEmpty) continue;
    int indent = 0;
    while (indent < line.length && line[indent] == ' ') indent++;
    if (indent < minIndent) minIndent = indent;
  }

  List<String> mapLines = rawMapLines
      .map((l) => l.length > minIndent ? l.substring(minIndent) : l.trim())
      .toList();

  int rows = mapLines.length;
  if (rows == 0) return {};
  int cols = mapLines.map((l) => l.length).reduce((a, b) => a > b ? a : b);
  mapLines = mapLines.map((l) => l.padRight(cols, ' ')).toList();

  // Pre-processing: Determine bounding box of CONTENT (non-wall, non-space)
  // Included content chars: ., M, m, x, X, e
  // Excluded: *, space
  int minX = 999;
  int maxX = -1;
  int minY = 999;
  int maxY = -1;

  for (int y = 0; y < rows; y++) {
    for (int x = 0; x < mapLines[y].length; x++) {
      String char = mapLines[y][x];
      if (char != '*' && char != ' ') {
        if (x < minX) minX = x;
        if (x > maxX) maxX = x;
        if (y < minY) minY = y;
        if (y > maxY) maxY = y;
      }
    }
  }

  // If no content found (empty level?), keep original or empty
  if (maxX == -1) {
    // Fallback: don't crop if empty logic
  } else {
    // Crop the mapLines
    List<String> croppedLines = [];
    for (int y = minY; y <= maxY; y++) {
      String line = mapLines[y];
      // Ensure line is long enough (it passed padRight but just to be safe)
      int end = (maxX + 1) <= line.length ? (maxX + 1) : line.length;
      int start = minX < line.length ? minX : line.length; // Safety
      if (start > end) start = end;

      croppedLines.add(line.substring(start, end));
    }
    mapLines = croppedLines;
    rows = mapLines.length;
    cols = (maxX - minX + 1);
  }

  int exitRow = -1;
  List<Map<String, dynamic>> blocks = [];
  Set<String> visited = {};

  // Note: We scan the NEW cropped mapLines, so (x, y) are relative to the new origin.
  for (int y = 0; y < rows; y++) {
    for (int x = 0; x < cols; x++) {
      if (x >= mapLines[y].length) continue;
      String char = mapLines[y][x];

      if (char == 'e') {
        exitRow = y;
        continue;
      }
      if (char == '.' || char == ' ') continue;
      if (visited.contains('$x,$y')) continue;

      bool isWall = (char == '*');
      bool isPrimary = (char == 'M' || char == 'm');

      int w = 0;
      int h = 1;

      int tx = x;
      while (tx < cols &&
          mapLines[y][tx] == char &&
          !visited.contains('$tx,$y')) {
        w++;
        tx++;
      }

      int ty = y + 1;
      while (ty < rows) {
        bool match = true;
        for (int k = 0; k < w; k++) {
          if (mapLines[ty][x + k] != char || visited.contains('${x + k},$ty')) {
            match = false;
            break;
          }
        }
        if (!match) break;
        ty++;
        h++;
      }

      for (int dy = 0; dy < h; dy++) {
        for (int dx = 0; dx < w; dx++) {
          visited.add('${x + dx},${y + dy}');
        }
      }

      blocks.add({
        'id': isWall ? 'wall_${x}_$y' : '${char}_${x}_$y',
        'width': w,
        'height': h,
        'x': x,
        'y': y,
        'isPrimary': isPrimary,
        'isWall': isWall, // Apenas paredes (*) são walls
      });
    }
  }

  // Parse levelInChapter
  int levelInChapter = id; // fallback
  if (name.contains('-')) {
    try {
      // names like "m1-22" need handling
      String numPart = name.split('-')[1];
      levelInChapter = int.parse(numPart);
    } catch (_) {}
  }

  return {
    'id': id,
    'chapterIndex': chapterIndex,
    'levelInChapter': levelInChapter,
    'gridSize': cols > rows ? cols : rows,
    'rows': rows,
    'columns': cols,
    'exitRow': exitRow != -1 ? exitRow : 2,
    'optimalMoves': optimalMoves,
    'blocks': blocks,
  };
}
