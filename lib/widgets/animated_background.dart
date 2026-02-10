import 'dart:math';
import 'package:flutter/material.dart';

/// Premium animated background with floating gradient orbs and particles.
/// Matches the dark glassmorphic theme (0x0A0A0F base).
class AnimatedPremiumBackground extends StatefulWidget {
  const AnimatedPremiumBackground({super.key});

  @override
  State<AnimatedPremiumBackground> createState() =>
      _AnimatedPremiumBackgroundState();
}

class _AnimatedPremiumBackgroundState extends State<AnimatedPremiumBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<_FloatingOrb> _orbs;
  late List<_Particle> _particles;

  @override
  void initState() {
    super.initState();
    final rng = Random(42);

    // Generate floating gradient orbs
    _orbs = List.generate(5, (i) => _FloatingOrb.random(rng, i));

    // Generate small drifting particles
    _particles = List.generate(30, (i) => _Particle.random(rng));

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
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
      builder: (context, _) {
        return CustomPaint(
          painter: _BackgroundPainter(
            progress: _controller.value,
            orbs: _orbs,
            particles: _particles,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Data models
// ─────────────────────────────────────────────────────────────────────────────

class _FloatingOrb {
  final double baseX; // 0..1 normalized
  final double baseY;
  final double radius;
  final Color color;
  final double speed; // multiplier for animation
  final double phaseX;
  final double phaseY;
  final double driftRadius; // how far it drifts

  _FloatingOrb({
    required this.baseX,
    required this.baseY,
    required this.radius,
    required this.color,
    required this.speed,
    required this.phaseX,
    required this.phaseY,
    required this.driftRadius,
  });

  factory _FloatingOrb.random(Random rng, int index) {
    const colors = [
      Color(0xFF00F3FF), // Cyan
      Color(0xFFFF2D78), // Pink
      Color(0xFF6C63FF), // Purple
      Color(0xFF00E676), // Green
      Color(0xFF00F3FF), // Cyan again
    ];
    return _FloatingOrb(
      baseX: 0.1 + rng.nextDouble() * 0.8,
      baseY: 0.1 + rng.nextDouble() * 0.8,
      radius: 80 + rng.nextDouble() * 120,
      color: colors[index % colors.length],
      speed: 0.5 + rng.nextDouble() * 1.5,
      phaseX: rng.nextDouble() * 2 * pi,
      phaseY: rng.nextDouble() * 2 * pi,
      driftRadius: 0.04 + rng.nextDouble() * 0.08,
    );
  }
}

class _Particle {
  final double x;
  final double y;
  final double size;
  final double opacity;
  final double speedX;
  final double speedY;
  final double phase;

  _Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.opacity,
    required this.speedX,
    required this.speedY,
    required this.phase,
  });

  factory _Particle.random(Random rng) {
    return _Particle(
      x: rng.nextDouble(),
      y: rng.nextDouble(),
      size: 1.0 + rng.nextDouble() * 2.5,
      opacity: 0.15 + rng.nextDouble() * 0.35,
      speedX: -0.02 + rng.nextDouble() * 0.04,
      speedY: -0.03 + rng.nextDouble() * 0.01, // mostly drift upward
      phase: rng.nextDouble() * 2 * pi,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Custom painter
// ─────────────────────────────────────────────────────────────────────────────

class _BackgroundPainter extends CustomPainter {
  final double progress;
  final List<_FloatingOrb> orbs;
  final List<_Particle> particles;

  _BackgroundPainter({
    required this.progress,
    required this.orbs,
    required this.particles,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // ── 1. Deep dark base ──
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = const Color(0xFF0A0A0F),
    );

    // ── 2. Subtle animated gradient overlay ──
    final gradientAngle = progress * 2 * pi;
    final gradientCenter = Offset(
      size.width * (0.5 + 0.2 * cos(gradientAngle)),
      size.height * (0.4 + 0.15 * sin(gradientAngle * 0.7)),
    );
    final gradientPaint = Paint()
      ..shader = RadialGradient(
        center: Alignment(
          (gradientCenter.dx / size.width) * 2 - 1,
          (gradientCenter.dy / size.height) * 2 - 1,
        ),
        radius: 1.0,
        colors: [
          const Color(0xFF0A0A0F).withValues(alpha: 0.0),
          const Color(0xFF1A1A2E).withValues(alpha: 0.4),
          const Color(0xFF0A0A0F).withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      gradientPaint,
    );

    // ── 3. Floating gradient orbs (blurred circles) ──
    for (final orb in orbs) {
      final t = progress * orb.speed;
      final dx = orb.driftRadius * cos(t * 2 * pi + orb.phaseX);
      final dy = orb.driftRadius * sin(t * 2 * pi + orb.phaseY);

      final cx = (orb.baseX + dx) * size.width;
      final cy = (orb.baseY + dy) * size.height;

      // Pulsing opacity
      final pulseAlpha = 0.06 + 0.04 * sin(t * 2 * pi + orb.phaseX);

      final orbPaint = Paint()
        ..shader = RadialGradient(
          colors: [
            orb.color.withValues(alpha: pulseAlpha),
            orb.color.withValues(alpha: 0.0),
          ],
        ).createShader(
          Rect.fromCircle(center: Offset(cx, cy), radius: orb.radius),
        )
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 40);

      canvas.drawCircle(Offset(cx, cy), orb.radius, orbPaint);
    }

    // ── 4. Drifting particles ──
    for (final p in particles) {
      final t = progress;
      // Wrap around
      final px = ((p.x + p.speedX * t * 10 + 1) % 1.0) * size.width;
      final py = ((p.y + p.speedY * t * 10 + 1) % 1.0) * size.height;

      // Twinkling effect
      final twinkle = 0.5 + 0.5 * sin(t * 2 * pi * 3 + p.phase);
      final alpha = p.opacity * twinkle;

      final paint = Paint()
        ..color = Colors.white.withValues(alpha: alpha)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, p.size * 0.5);

      canvas.drawCircle(Offset(px, py), p.size, paint);
    }

    // ── 5. Subtle grid lines ──
    _drawSubtleGrid(canvas, size);
  }

  void _drawSubtleGrid(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.02)
      ..strokeWidth = 0.5;

    const spacing = 60.0;

    // Vertical lines
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    // Horizontal lines
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _BackgroundPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
