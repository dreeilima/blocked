import 'dart:collection';
import '../models/block.dart';
import '../models/level.dart';

class Move {
  final String blockId;
  final int delta; // +move ou -move
  final int startX;
  final int startY;
  final int endX;
  final int endY;

  Move({
    required this.blockId,
    required this.delta,
    required this.startX,
    required this.startY,
    required this.endX,
    required this.endY,
  });

  @override
  String toString() => 'Move($blockId, delta: $delta)';
}

class Node {
  final List<Block> blocks;
  final Node? parent;
  final Move? moveFromParent;
  final String stateHash;

  Node(this.blocks, this.parent, this.moveFromParent)
    : stateHash = _calculateHash(blocks);

  static String _calculateHash(List<Block> blocks) {
    // Ordenar por ID para garantir consistência no hash
    final sortedBlocks = List<Block>.from(blocks)
      ..sort((a, b) => a.id.compareTo(b.id)); // Importante se a ordem mudar

    final buffer = StringBuffer();
    for (var b in sortedBlocks) {
      buffer.write('${b.id}:${b.x},${b.y}|');
    }
    return buffer.toString();
  }
}

class Solver {
  final Level initialLevel;
  final int rows;
  final int columns;

  Solver(this.initialLevel)
    : rows = initialLevel.rows,
      columns = initialLevel.columns;

  /// Retorna a lista de movimentos para vencer
  List<Move>? solve({int maxIterations = 50000}) {
    // Precisamos de blocos mutaveis ou clonaveis. O Block é imutavel
    final startNode = Node(List.of(initialLevel.blocks), null, null);
    final Queue<Node> frontier = Queue();
    final Set<String> visited = {};

    frontier.add(startNode);
    visited.add(startNode.stateHash);

    int iterations = 0;

    while (frontier.isNotEmpty) {
      iterations++;
      if (iterations > maxIterations) return null; // Timeout

      final currentNode = frontier.removeFirst();

      if (_isSolution(currentNode.blocks)) {
        return _reconstructPath(currentNode);
      }

      // Gerar sucessores
      for (int i = 0; i < currentNode.blocks.length; i++) {
        final block = currentNode.blocks[i];

        // Esquerda/Cima (delta negativo)
        for (int d = -1; d >= -columns; d--) {
          if (!_canMove(currentNode.blocks, i, d)) break;
          _addIfNew(currentNode, i, d, frontier, visited);
        }

        // Direita/Baixo (delta positivo)
        for (int d = 1; d <= columns; d++) {
          if (!_canMove(currentNode.blocks, i, d)) break;
          _addIfNew(currentNode, i, d, frontier, visited);
        }
      }
    }

    return null;
  }

  bool _isSolution(List<Block> blocks) {
    try {
      final primary = blocks.firstWhere((b) => b.isPrimary);
      return primary.x + primary.width == columns;
    } catch (e) {
      return false;
    }
  }

  bool _canMove(List<Block> blocks, int blockIndex, int delta) {
    final block = blocks[blockIndex];

    int newX = block.x;
    int newY = block.y;

    // Determinar orientação baseada na forma: horizontal se largura > altura
    bool isHorizontal = block.width >= block.height;
    // Cuidado: alguns blocos 1x1 podem ser ambíguos, mas no blocked game geralmente não existem blocos 1x1 móveis que mudam de direção?
    // Se o bloco é 1x1, ele teoricamente pode mover pra ambos? Não, no Rush Hour peças tem orientação fixa.
    // O modelo `Block` atual não tem `type`. Assumimos width > height = horizontal.
    // Se width == height (1x1), o comportamento padrão de engines Rush Hour é não existir, ou ter orientação fixa definida.
    // Vamos assumir: width > height = Horizontal. width < height = Vertical. width == height = ???
    // Vou assumir que width >= height é Horizontal, mas e se for 1x2 Vertical? width < height. Ok.
    // Se 1x1? Vamos considerar Horizontal se não tiver flag. Mas 1x1 raramente existe em blocked puzzle clássico.

    if (block.width > block.height) {
      // Horizontal
      newX += delta;
      if (newX < 0 || newX + block.width > columns) return false;
    } else {
      // Vertical
      newY += delta;
      if (newY < 0 || newY + block.height > rows) return false;
    }

    // Colisão
    for (int i = 0; i < blocks.length; i++) {
      if (i == blockIndex) continue;
      final other = blocks[i];
      if (newX < other.x + other.width &&
          newX + block.width > other.x &&
          newY < other.y + other.height &&
          newY + block.height > other.y) {
        return false;
      }
    }
    return true;
  }

  void _addIfNew(
    Node parent,
    int blockIdx,
    int delta,
    Queue<Node> frontier,
    Set<String> visited,
  ) {
    final newBlocks = List<Block>.from(parent.blocks);
    final oldBlock = newBlocks[blockIdx];

    int newX = oldBlock.x;
    int newY = oldBlock.y;

    if (oldBlock.width > oldBlock.height) {
      newX += delta;
    } else {
      newY += delta;
    }

    newBlocks[blockIdx] = oldBlock.copyWith(x: newX, y: newY);

    final newNode = Node(
      newBlocks,
      parent,
      Move(
        blockId: oldBlock.id,
        delta: delta,
        startX: oldBlock.x,
        startY: oldBlock.y,
        endX: newX,
        endY: newY,
      ),
    );

    if (!visited.contains(newNode.stateHash)) {
      visited.add(newNode.stateHash);
      frontier.add(newNode);
    }
  }

  List<Move> _reconstructPath(Node node) {
    final path = <Move>[];
    Node? current = node;
    while (current?.moveFromParent != null) {
      path.add(current!.moveFromParent!);
      current = current.parent;
    }
    return path.reversed.toList();
  }
}
