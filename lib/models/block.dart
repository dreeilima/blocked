class Block {
  final String id;
  final int width;
  final int height;
  final bool isPrimary;
  final int x;
  final int y;

  const Block({
    required this.id,
    required this.width,
    required this.height,
    required this.x,
    required this.y,
    this.isPrimary = false,
  });

  // Helper to copy with new position
  Block copyWith({int? x, int? y}) {
    return Block(
      id: id,
      width: width,
      height: height,
      x: x ?? this.x,
      y: y ?? this.y,
      isPrimary: isPrimary,
    );
  }

  factory Block.fromJson(Map<String, dynamic> json) {
    // Legacy support or direct parsing
    int w = 1;
    int h = 1;

    if (json.containsKey('width') && json.containsKey('height')) {
      w = json['width'] as int;
      h = json['height'] as int;
    } else if (json.containsKey('len') && json.containsKey('ori')) {
      // Convert legacy 1D format to 2D
      final len = json['len'] as int;
      final ori = json['ori'] as String;
      if (ori == 'h') {
        w = len;
        h = 1;
      } else {
        w = 1;
        h = len;
      }
    }

    return Block(
      id: json['id'] as String,
      width: w,
      height: h,
      x: json['x'] as int,
      y: json['y'] as int,
      isPrimary: json['primary'] == true,
    );
  }

  // Check if a point (gridX, gridY) is occupied by this block
  bool occupies(int gridX, int gridY) {
    return gridX >= x && gridX < x + width && gridY >= y && gridY < y + height;
  }
}
