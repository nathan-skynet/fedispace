import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

class GlitchEffect extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Duration frequency;

  const GlitchEffect({
    Key? key,
    required this.child,
    this.duration = const Duration(milliseconds: 300),
    this.frequency = const Duration(milliseconds: 3000),
  }) : super(key: key);

  @override
  _GlitchEffectState createState() => _GlitchEffectState();
}

class _GlitchEffectState extends State<GlitchEffect> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Timer _timer;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _timer = Timer.periodic(widget.frequency, (timer) {
      if (mounted) {
        _triggerGlitch();
      }
    });

    // Initial glitch
    Future.delayed(const Duration(milliseconds: 500), _triggerGlitch);
  }

  void _triggerGlitch() {
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        if (!_controller.isAnimating) {
          return widget.child;
        }

        final double offset = _random.nextDouble() * 10.0; // Increased from 5.0
        final double distortion = _random.nextDouble() * 0.1;
        
        return Stack(
          children: [
             // Cyan Channel (Offset Left)
            Transform.translate(
              offset: Offset(-offset, 0),
              child: Opacity(
                opacity: 0.9, // Increased from 0.7
                child: ColorFiltered(
                  colorFilter: const ColorFilter.mode(
                    Colors.cyan,
                    BlendMode.srcIn,
                  ),
                  child: widget.child,
                
                ),
              ),
            ),
             // Magenta Channel (Offset Right)
            Transform.translate(
              offset: Offset(offset, 0),
              child: Opacity(
                opacity: 0.9, // Increased from 0.7
                child: ColorFiltered(
                  colorFilter: const ColorFilter.mode(
                    Color(0xFFFF00FF), // Magenta/Neon Pink
                    BlendMode.srcIn,
                  ),
                  child: widget.child,
                ),
              ),
            ),
            // Main Content (Jittered)
            Transform.translate(
               offset: Offset(_random.nextDouble() * 2 - 1, _random.nextDouble() * 2 - 1),
               child: widget.child
            ),
          ],
        );
      },
    );
  }
}
