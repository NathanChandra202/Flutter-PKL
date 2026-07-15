import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

class LiquidBackground extends StatefulWidget {
  final Widget child;

  const LiquidBackground({super.key, required this.child});

  @override
  State<LiquidBackground> createState() => _LiquidBackgroundState();
}

class _LiquidBackgroundState extends State<LiquidBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat(reverse: true);

    _anim = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, child) {
        return CustomPaint(
          painter: _LiquidPainter(_anim.value),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class _LiquidPainter extends CustomPainter {
  final double t; // 0.0 → 1.0

  _LiquidPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    // ─── Base background ─────────────────────────────────────────────────
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = AppTheme.bgWhite,
    );

    final w = size.width;
    final h = size.height;

    // ─── Blob 1 — large gold blob top-right ──────────────────────────────
    final paint1 = Paint()
      ..shader = RadialGradient(
        colors: [
          AppTheme.accentGold.withOpacity(0.18),
          AppTheme.accentGold.withOpacity(0.0),
        ],
      ).createShader(Rect.fromCircle(
        center: Offset(w * 0.85 + 30 * math.sin(t * math.pi),
            h * 0.12 + 20 * math.cos(t * math.pi)),
        radius: w * 0.5,
      ));

    canvas.drawCircle(
      Offset(w * 0.85 + 30 * math.sin(t * math.pi),
          h * 0.12 + 20 * math.cos(t * math.pi)),
      w * 0.5,
      paint1,
    );

    // ─── Blob 2 — medium dark blob bottom-left ───────────────────────────
    final paint2 = Paint()
      ..shader = RadialGradient(
        colors: [
          AppTheme.primaryBlack.withOpacity(0.06),
          AppTheme.primaryBlack.withOpacity(0.0),
        ],
      ).createShader(Rect.fromCircle(
        center: Offset(w * 0.1 + 25 * math.cos(t * math.pi * 1.3),
            h * 0.75 + 30 * math.sin(t * math.pi * 1.3)),
        radius: w * 0.45,
      ));

    canvas.drawCircle(
      Offset(w * 0.1 + 25 * math.cos(t * math.pi * 1.3),
          h * 0.75 + 30 * math.sin(t * math.pi * 1.3)),
      w * 0.45,
      paint2,
    );

    // ─── Blob 3 — small accent blob middle ───────────────────────────────
    final paint3 = Paint()
      ..shader = RadialGradient(
        colors: [
          AppTheme.accentGoldLight.withOpacity(0.22),
          AppTheme.accentGoldLight.withOpacity(0.0),
        ],
      ).createShader(Rect.fromCircle(
        center: Offset(w * 0.45 + 20 * math.sin(t * math.pi * 0.7),
            h * 0.45 + 25 * math.cos(t * math.pi * 0.7)),
        radius: w * 0.28,
      ));

    canvas.drawCircle(
      Offset(w * 0.45 + 20 * math.sin(t * math.pi * 0.7),
          h * 0.45 + 25 * math.cos(t * math.pi * 0.7)),
      w * 0.28,
      paint3,
    );
  }

  @override
  bool shouldRepaint(_LiquidPainter old) => old.t != t;
}
