import 'package:flutter/material.dart' hide Orientation;
import 'dart:math';
import '../models/block.dart';
import '../providers/theme_provider.dart';

class BlockWidget extends StatefulWidget {
  final Block block;
  final double tileSize;
  final bool isActive;
  final bool shouldShake;
  final VoidCallback? onDragStart;
  final VoidCallback? onDragEnd;
  final Function(String, int, int) onMove;
  final bool isHintTarget;
  final int hintDelta;

  const BlockWidget({
    super.key,
    required this.block,
    required this.tileSize,
    required this.isActive,
    this.shouldShake = false,
    this.onDragStart,
    this.onDragEnd,
    required this.onMove,
    this.isHintTarget = false,
    this.hintDelta = 0,
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
    final gameColors = ThemeProvider.getGameColors(context);

    // Determine colors based on state
    // Primary block is always green-ish.
    // Other blocks are grey usually.
    // ANY block becomes "active" (green-ish) when being dragged.

    final bool isHighlighted = widget.isActive;

    final Color blockColor = isHighlighted
        ? gameColors.blockFill
        : gameColors.secondaryBlockFill;

    final Color borderColor = widget.isActive
        ? gameColors.activeBlockBorder
        : (widget.block.isPrimary
              ? gameColors.blockBorder
              : gameColors.secondaryBlockBorder);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanStart: widget.isActive
          ? (_) {
              _accumulatedOffset = Offset.zero;
              widget.onDragStart?.call();
            }
          : null,
      onPanEnd: widget.isActive
          ? (_) {
              _accumulatedOffset = Offset.zero;
              widget.onDragEnd?.call();
            }
          : null,
      onPanUpdate: widget.isActive
          ? (details) {
              _handleDrag(details);
            }
          : null,
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
          margin: const EdgeInsets.all(4.0), // gutter spacing between blocks
          decoration: BoxDecoration(
            color: blockColor,
            borderRadius: BorderRadius.circular(8.0), // slightly rounder
            border: Border.all(
              color: borderColor,
              width: widget.isActive ? 3.0 : 2.0,
            ),
            boxShadow: widget.isActive
                ? [
                    BoxShadow(
                      color: gameColors.activeBlockBorder.withValues(
                        alpha: 0.3,
                      ),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ]
                : [],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Círculo do bloco primário
              if (widget.block.isPrimary)
                Container(
                  width: widget.tileSize * 0.35,
                  height: widget.tileSize * 0.35,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: gameColors.primaryCircle,
                      width: 2.5,
                    ),
                  ),
                ),

              // Seta de Dica (Hint)
              if (widget.isHintTarget) _buildHintArrow(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHintArrow() {
    IconData icon;
    bool isHorizontal = widget.block.width > widget.block.height;

    if (isHorizontal) {
      icon = widget.hintDelta > 0 ? Icons.arrow_forward : Icons.arrow_back;
    } else {
      icon = widget.hintDelta > 0 ? Icons.arrow_downward : Icons.arrow_upward;
    }

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: (sin(value * pi * 2) + 1) / 2, // Pulse opacity
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.8),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.amber[900], size: 24),
          ),
        );
      },
      onEnd: () {
        // Loop animation manual para o Tween?
        // Melhor usar um Controller separado no initState se quisermos loop infinito perfeito.
        // Mas como setState pode ser chamado frequentemente, TweenBuilder reseta.
        // Vamos simplificar: usar o _pulseController existente ou criar um novo?
        // O TweenAnimationBuilder não loopa fácil.
        // Vou usar apenas um Icon estático visível por enquanto, ou com o Opacity animado pelo Controller existente?
        // Vamos fazer simples: Icon com Shadow.
      },
      child: null,
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
