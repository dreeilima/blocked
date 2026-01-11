import 'package:flutter/material.dart';

/// Widget helper para criar animações staggered (em cascata) em grids
class StaggeredGridAnimation extends StatefulWidget {
  final int index;
  final int columnCount;
  final Duration delay;
  final Duration duration;
  final Widget child;

  const StaggeredGridAnimation({
    super.key,
    required this.index,
    required this.child,
    this.columnCount = 3,
    this.delay = const Duration(milliseconds: 50),
    this.duration = const Duration(milliseconds: 400),
  });

  @override
  State<StaggeredGridAnimation> createState() => _StaggeredGridAnimationState();
}

class _StaggeredGridAnimationState extends State<StaggeredGridAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(vsync: this, duration: widget.duration);

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );

    // Calcula o delay baseado na posição no grid
    final row = widget.index ~/ widget.columnCount;
    final col = widget.index % widget.columnCount;
    final itemDelay = widget.delay * (row + col);

    // Inicia a animação após o delay
    Future.delayed(itemDelay, () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - _animation.value)),
            child: Transform.scale(
              scale: 0.8 + (0.2 * _animation.value),
              child: child,
            ),
          ),
        );
      },
      child: widget.child,
    );
  }
}
