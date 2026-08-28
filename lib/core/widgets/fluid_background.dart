import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/colors.dart';

class FluidBackground extends StatefulWidget {
  final Widget child;
  final bool isDark;

  const FluidBackground({
    super.key,
    required this.child,
    this.isDark = true,
  });

  @override
  State<FluidBackground> createState() => _FluidBackgroundState();
}

class _FluidBackgroundState extends State<FluidBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 16),
    )..repeat(reverse: true);
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
        final progress = _controller.value;
        final animAngle = progress * 2 * math.pi;

        return Stack(
          children: [
            // 1. WebGL-Style Base Shader Color Layer (#051424)
            Container(
              decoration: BoxDecoration(
                color: widget.isDark ? SiyaqColors.darkBg : SiyaqColors.lightBg,
              ),
            ),

            // 2. Animated WebGL Light Leaks & Glowing Ribbon Mesh (Amber + Royal Blue)
            Positioned.fill(
              child: CustomPaint(
                painter: _ShaderLightLeakPainter(
                  progress: progress,
                  angle: animAngle,
                  isDark: widget.isDark,
                ),
              ),
            ),

            // 3. Main Content Layer
            widget.child,
          ],
        );
      },
      child: widget.child,
    );
  }
}

class _ShaderLightLeakPainter extends CustomPainter {
  final double progress;
  final double angle;
  final bool isDark;

  _ShaderLightLeakPainter({
    required this.progress,
    required this.angle,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;

    // --- 1. Royal Blue Fluid Glow Blob (Center Left) ---
    final royalBlueCenter = Offset(
      width * 0.25 + math.cos(angle * 0.8) * 50,
      height * 0.45 + math.sin(angle * 0.8) * 40,
    );
    final royalBluePaint = Paint()
      ..shader = RadialGradient(
        colors: isDark
            ? [
                const Color(0xFF006BE3).withOpacity(0.55),
                const Color(0xFF1E293B).withOpacity(0.30),
                Colors.transparent,
              ]
            : [
                SiyaqColors.lightMeshOpal.withOpacity(0.95),
                const Color(0xFFADC6FF).withOpacity(0.40),
                Colors.transparent,
              ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(Rect.fromCircle(center: royalBlueCenter, radius: width * 0.75));

    canvas.drawCircle(royalBlueCenter, width * 0.75, royalBluePaint);

    // --- 2. High-Contrast Amber / Gold Light Leak Blob (Bottom Right) ---
    final amberLeakCenter = Offset(
      width * 0.80 + math.sin(angle) * 40,
      height * 0.70 - math.cos(angle) * 35,
    );
    final amberLeakPaint = Paint()
      ..shader = RadialGradient(
        colors: isDark
            ? [
                const Color(0xFFE8C17D).withOpacity(0.50),
                const Color(0xFFCC661A).withOpacity(0.35),
                const Color(0xFF93000A).withOpacity(0.15),
                Colors.transparent,
              ]
            : [
                SiyaqColors.accentGold.withOpacity(0.45),
                SiyaqColors.lightMeshCashmere.withOpacity(0.30),
                Colors.transparent,
              ],
        stops: const [0.0, 0.35, 0.70, 1.0],
      ).createShader(Rect.fromCircle(center: amberLeakCenter, radius: width * 0.70));

    canvas.drawCircle(amberLeakCenter, width * 0.70, amberLeakPaint);

    // --- 3. Flowing Luminous Fluid Ribbon Line (Sweeping Diagonally) ---
    final waveOffset = math.sin(angle * 1.5) * 45;

    final ribbonPath = Path();
    ribbonPath.moveTo(-60, height * 0.20 + waveOffset);
    ribbonPath.cubicTo(
      width * 0.30,
      height * 0.10 - waveOffset,
      width * 0.70,
      height * 0.60 + waveOffset,
      width + 60,
      height * 0.45 - waveOffset,
    );

    final ribbonPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isDark
            ? [
                Colors.white.withOpacity(0.70),
                const Color(0xFFE8C17D).withOpacity(0.85),
                const Color(0xFF006BE3).withOpacity(0.40),
                Colors.transparent,
              ]
            : [
                Colors.white.withOpacity(0.95),
                SiyaqColors.accentGold.withOpacity(0.75),
                Colors.transparent,
              ],
      ).createShader(Rect.fromLTWH(0, 0, width, height))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 4);

    canvas.drawPath(ribbonPath, ribbonPaint);
  }

  @override
  bool shouldRepaint(covariant _ShaderLightLeakPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.isDark != isDark;
  }
}
