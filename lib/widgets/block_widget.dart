import 'package:flutter/material.dart' hide Orientation;
import 'dart:math';
import '../models/block.dart';

class BlockWidget extends StatefulWidget {
  final Block block;
  final double tileSize;
  final bool isActive;
  final bool shouldShake;
  final Function(String, int, int) onMove;

  const BlockWidget({
    super.key,
    required this.block,
    required this.tileSize,
    required this.isActive,
    this.shouldShake = false,
    required this.onMove,
  });

  @override
  State<BlockWidget> createState() => _BlockWidgetState();
}

class _BlockWidgetState extends State<BlockWidget>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;

  late AnimationController _shakeController;

  Offset _accumulatedOffset = Offset.zero;
  int _lastMoveTime = 0;

  @override
  void initState() {
    super.initState();
    // Pulse animation for active state
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnimation =
        TweenSequence<double>([
          TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.05), weight: 50),
          TweenSequenceItem(tween: Tween(begin: 1.05, end: 1.0), weight: 50),
        ]).animate(
          CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
        );

    // Shake animation for collision
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300), // Faster shake
    );
  }

  @override
  void didUpdateWidget(BlockWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Trigger pulse on active
    if (widget.isActive && !oldWidget.isActive) {
      _pulseController.forward(from: 0.0);
    }

    // Trigger shake on collision
    if (widget.shouldShake && !oldWidget.shouldShake) {
      _shakeController.forward(from: 0.0).then((_) => _shakeController.reset());
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Dark theme colors matching the reference screenshot
    const Color blockFill = Color(0xFF3A4A4A); // Dark grey-teal block fill
    const Color blockBorder = Color(
      0xFF5A6A6A,
    ); // Lighter grey border for inactive
    const Color activeBorder = Color(
      0xFF8FBC8F,
    ); // Green border for active block
    const Color primaryCircle = Color(0xFF8FBC8F); // Same green for circle

    final Color borderColor = widget.isActive ? activeBorder : blockBorder;

    return GestureDetector(
      behavior: HitTestBehavior.opaque, // Capture all gestures in the area
      onPanStart: (_) => _accumulatedOffset = Offset.zero,
      onPanEnd: (_) => _accumulatedOffset = Offset.zero,
      onPanUpdate: (details) {
        _handleDrag(details);
      },
      child: AnimatedBuilder(
        animation: Listenable.merge([_scaleAnimation, _shakeController]),
        builder: (context, child) {
          // Calculate shake offset based on sine wave using controller value
          double offsetX = 0;
          if (_shakeController.isAnimating) {
            const double shakeAmount = 6.0;
            // Simple back-and-forth shake
            // _shakeController.value goes 0->1. We want a few sine waves.
            offsetX = shakeAmount * sin(_shakeController.value * 6 * pi);
          }

          return Transform.translate(
            offset: Offset(offsetX, 0),
            child: Transform.scale(scale: _scaleAnimation.value, child: child),
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(
            6.0,
          ), // increased margin for better visual separation
          decoration: BoxDecoration(
            color: blockFill,
            borderRadius: BorderRadius.circular(8.0), // slightly rounder
            border: Border.all(
              color: borderColor,
              width: widget.isActive ? 3.0 : 2.0,
            ),
            boxShadow: widget.isActive
                ? [
                    BoxShadow(
                      color: activeBorder.withOpacity(0.3),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ]
                : [],
          ),
          child: Center(
            // Circle outline for primary block
            child: widget.block.isPrimary
                ? Container(
                    width: widget.tileSize * 0.35,
                    height: widget.tileSize * 0.35,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: primaryCircle, width: 2.5),
                    ),
                  )
                : null,
          ),
        ),
      ),
    );
  }

  void _handleDrag(DragUpdateDetails details) {
    // Only allow dragging the active block
    if (!widget.isActive) return;

    // Throttle movement to prevent "flying" blocks
    final int now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastMoveTime < 120) return; // 120ms cooldown

    // Accumulate the drag delta
    _accumulatedOffset += details.delta;

    // Movement threshold: move 1 tile when drag exceeds 40% of tile size
    // or a fixed comfortable pixel distance
    final double threshold = widget.tileSize * 0.45;

    // Determine primary direction of drag based on total accumulated offset
    if (_accumulatedOffset.dx.abs() > _accumulatedOffset.dy.abs()) {
      // Horizontal drag
      if (_accumulatedOffset.dx > threshold) {
        // Move Right
        widget.onMove(widget.block.id, widget.block.x + 1, widget.block.y);
        _accumulatedOffset = Offset.zero; // Reset after move
        _lastMoveTime = now;
      } else if (_accumulatedOffset.dx < -threshold) {
        // Move Left
        widget.onMove(widget.block.id, widget.block.x - 1, widget.block.y);
        _accumulatedOffset = Offset.zero;
        _lastMoveTime = now;
      }
    } else {
      // Vertical drag
      if (_accumulatedOffset.dy > threshold) {
        // Move Down
        widget.onMove(widget.block.id, widget.block.x, widget.block.y + 1);
        _accumulatedOffset = Offset.zero;
        _lastMoveTime = now;
      } else if (_accumulatedOffset.dy < -threshold) {
        // Move Up
        widget.onMove(widget.block.id, widget.block.x, widget.block.y - 1);
        _accumulatedOffset = Offset.zero;
        _lastMoveTime = now;
      }
    }
  }
}
