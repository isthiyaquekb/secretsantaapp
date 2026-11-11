import 'dart:math';
import 'package:flutter/material.dart';

class SnowflakeParticle {
  double x; // 0.0 to 1.0
  double y; // 0.0 to 1.0
  double radius;
  double speed;
  double opacity;
  double swayOffset;
  double swaySpeed;

  SnowflakeParticle({
    required this.x,
    required this.y,
    required this.radius,
    required this.speed,
    required this.opacity,
    required this.swayOffset,
    required this.swaySpeed,
  });

  factory SnowflakeParticle.random(Random rng) {
    return SnowflakeParticle(
      x: rng.nextDouble(),
      y: rng.nextDouble(),
      radius: 1.5 + rng.nextDouble() * 2.5,
      speed: 0.0008 + rng.nextDouble() * 0.0016,
      opacity: 0.15 + rng.nextDouble() * 0.35,
      swayOffset: rng.nextDouble() * 2 * pi,
      swaySpeed: 1.0 + rng.nextDouble() * 2.0,
    );
  }
}

class SnowfallOverlay extends StatefulWidget {
  final Widget child;
  final bool enableSnow;

  const SnowfallOverlay({
    super.key,
    required this.child,
    this.enableSnow = true,
  });

  @override
  State<SnowfallOverlay> createState() => _SnowfallOverlayState();
}

class _SnowfallOverlayState extends State<SnowfallOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final List<SnowflakeParticle> _snowflakes = [];
  final Random _rng = Random();
  static const int _flakeCount = 40;

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < _flakeCount; i++) {
      _snowflakes.add(SnowflakeParticle.random(_rng));
    }

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..addListener(_updateFlakes);

    _controller.repeat();
  }

  void _updateFlakes() {
    for (final flake in _snowflakes) {
      flake.y += flake.speed;
      if (flake.y > 1.0) {
        flake.y = 0.0;
        flake.x = _rng.nextDouble();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Respect OS "reduce motion" setting
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    if (!widget.enableSnow || reduceMotion) {
      return widget.child;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final flakeColor = isDark
        ? Colors.white.withValues(alpha: 0.4)
        : const Color(0xFFBC0009).withValues(alpha: 0.18);

    return Stack(
      children: [
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return CustomPaint(
                painter: _SnowPainter(
                  flakes: _snowflakes,
                  color: flakeColor,
                  animationValue: _controller.value,
                ),
              );
            },
          ),
        ),
        widget.child,
      ],
    );
  }
}

class _SnowPainter extends CustomPainter {
  final List<SnowflakeParticle> flakes;
  final Color color;
  final double animationValue;

  _SnowPainter({
    required this.flakes,
    required this.color,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;

    for (final flake in flakes) {
      final sway = sin(animationValue * 2 * pi * flake.swaySpeed + flake.swayOffset) * 0.02;
      final px = ((flake.x + sway) % 1.0) * size.width;
      final py = flake.y * size.height;

      paint.color = color.withValues(alpha: flake.opacity * (color.a));
      canvas.drawCircle(Offset(px, py), flake.radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SnowPainter oldDelegate) => true;
}
