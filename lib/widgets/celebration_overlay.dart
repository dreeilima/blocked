import 'dart:math';
import 'package:flutter/material.dart';

/// Widget de celebração com partículas/confete animadas
class CelebrationOverlay extends StatefulWidget {
  final VoidCallback? onComplete;

  const CelebrationOverlay({super.key, this.onComplete});

  @override
  State<CelebrationOverlay> createState() => _CelebrationOverlayState();
}

class _CelebrationOverlayState extends State<CelebrationOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<Particle> _particles = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: 4500,
      ), // Aumentado para melhor visualização
    );

    // Criar partículas com posições e velocidades variadas
    for (int i = 0; i < 60; i++) {
      final startX = 0.3 + _random.nextDouble() * 0.4; // Começa no centro
      final velocityX =
          (_random.nextDouble() - 0.5) * 0.8; // Velocidade horizontal variada
      final velocityY =
          -0.3 -
          _random.nextDouble() * 0.5; // Velocidade vertical inicial (para cima)

      _particles.add(
        Particle(
          color: _getRandomColor(),
          startX: startX,
          velocityX: velocityX,
          velocityY: velocityY,
          rotation: _random.nextDouble() * 2 * pi,
          rotationSpeed: (_random.nextDouble() - 0.5) * 8,
          size: 6 + _random.nextDouble() * 10,
          gravity: 0.8 + _random.nextDouble() * 0.4,
        ),
      );
    }

    _controller.forward().then((_) {
      widget.onComplete?.call();
    });
  }

  Color _getRandomColor() {
    final colors = [
      const Color(0xFF8FBC8F), // Verde
      const Color(0xFFFFD700), // Dourado
      const Color(0xFF87CEEB), // Azul claro
      const Color(0xFFFF69B4), // Rosa
      const Color(0xFFFFFFFF), // Branco
      const Color(0xFFFF6B6B), // Vermelho
      const Color(0xFF4ECDC4), // Turquesa
    ];
    return colors[_random.nextInt(colors.length)];
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: ParticlePainter(
            particles: _particles,
            progress: _controller.value,
          ),
          child: Container(),
        );
      },
    );
  }
}

class Particle {
  final Color color;
  final double startX;
  final double velocityX;
  final double velocityY;
  final double rotation;
  final double rotationSpeed;
  final double size;
  final double gravity;

  Particle({
    required this.color,
    required this.startX,
    required this.velocityX,
    required this.velocityY,
    required this.rotation,
    required this.rotationSpeed,
    required this.size,
    required this.gravity,
  });
}

class ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  final double progress;

  ParticlePainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (var particle in particles) {
      // Física realista: movimento parabólico
      final t = progress;

      // Posição X: movimento linear com velocidade
      final x = size.width * (particle.startX + particle.velocityX * t);

      // Posição Y: movimento parabólico (velocidade inicial + gravidade)
      final y =
          size.height *
          (0.3 + particle.velocityY * t + 0.5 * particle.gravity * t * t);

      // Sair da tela = não desenhar
      if (y > size.height || x < 0 || x > size.width) continue;

      // Fade out gradual
      final opacity = progress < 0.8 ? 1.0 : (1.0 - (progress - 0.8) / 0.2);

      final paint = Paint()
        ..color = particle.color.withValues(alpha: opacity)
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(x, y);

      // Rotação contínua
      canvas.rotate(
        particle.rotation + particle.rotationSpeed * progress * 2 * pi,
      );

      // Desenhar confete (retângulo pequeno arredondado)
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset.zero,
            width: particle.size,
            height: particle.size * 0.5,
          ),
          const Radius.circular(2),
        ),
        paint,
      );

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(ParticlePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
