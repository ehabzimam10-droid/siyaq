import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/colors.dart';

class FluidThemeTransition extends StatefulWidget {
  final Widget child;
  final ThemeMode themeMode;

  const FluidThemeTransition({
    super.key,
    required this.child,
    required this.themeMode,
  });

  @override
  State<FluidThemeTransition> createState() => _FluidThemeTransitionState();
}

class _FluidThemeTransitionState extends State<FluidThemeTransition>
    with SingleTickerProviderStateMixin {
  late AnimationController _transitionController;
  ThemeMode? _previousThemeMode;
  Offset _epicenter = const Offset(50, 50);

  @override
  void initState() {
    super.initState();
    _transitionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    );
    _previousThemeMode = widget.themeMode;
  }

  @override
  void didUpdateWidget(covariant FluidThemeTransition oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.themeMode != widget.themeMode) {
      _previousThemeMode = oldWidget.themeMode;
      _transitionController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _transitionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _transitionController,
      builder: (context, child) {
        final progress = CurvedAnimation(
          parent: _transitionController,
          curve: Curves.easeInOutCubic,
        ).value;

        return Stack(
          children: [
            // Base Child Screen
            widget.child,

            // Fluid Ink Expansion Overlay during theme toggle
            if (_transitionController.isAnimating)
              IgnorePointer(
                child: CustomPaint(
                  size: Size.infinite,
                  painter: _FluidInkWavePainter(
                    progress: progress,
                    epicenter: _epicenter,
                    isTargetDark: isDark,
                  ),
                ),
              ),
          ],
        );
      },
      child: widget.child,
    );
  }
}

class _FluidInkWavePainter extends CustomPainter {
  final double progress;
  final Offset epicenter;
  final bool isTargetDark;

  _FluidInkWavePainter({
    required this.progress,
    required this.epicenter,
    required this.isTargetDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final maxRadius = math.sqrt(size.width * size.width + size.height * size.height) * 1.2;
    final currentRadius = maxRadius * progress;

    final paint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.85, -0.92),
        radius: progress * 1.5,
        colors: isTargetDark
            ? [
                SiyaqColors.darkBg.withOpacity(0.95),
                SiyaqColors.darkMeshRoyalBlue.withOpacity(0.80),
                Colors.transparent,
              ]
            : [
                SiyaqColors.lightBg.withOpacity(0.95),
                SiyaqColors.lightMeshOpal.withOpacity(0.80),
                Colors.transparent,
              ],
        stops: const [0.0, 0.7, 1.0],
      ).createShader(Rect.fromCircle(center: epicenter, radius: currentRadius));

    canvas.drawCircle(epicenter, currentRadius, paint);
  }

  @override
  bool shouldRepaint(covariant _FluidInkWavePainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.isTargetDark != isTargetDark;
  }
}
