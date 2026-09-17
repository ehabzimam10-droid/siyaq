import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/colors.dart';

class LiquidDraggableFab extends StatefulWidget {
  final DateTime? initialDate;
  final double fabSize;
  final bool isDragging;
  final GestureDragStartCallback? onPanStart;
  final GestureDragUpdateCallback? onPanUpdate;
  final GestureDragEndCallback? onPanEnd;
  final VoidCallback? onTap;

  const LiquidDraggableFab({
    super.key,
    this.initialDate,
    this.fabSize = 58.0,
    this.isDragging = false,
    this.onPanStart,
    this.onPanUpdate,
    this.onPanEnd,
    this.onTap,
  });

  @override
  State<LiquidDraggableFab> createState() => _LiquidDraggableFabState();
}

class _LiquidDraggableFabState extends State<LiquidDraggableFab>
    with SingleTickerProviderStateMixin {
  late AnimationController _orbController;

  @override
  void initState() {
    super.initState();
    _orbController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();
  }

  @override
  void dispose() {
    _orbController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanStart: widget.onPanStart,
      onPanUpdate: widget.onPanUpdate,
      onPanEnd: widget.onPanEnd,
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: widget.isDragging ? 1.15 : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutBack,
        child: AnimatedBuilder(
          animation: _orbController,
          builder: (context, child) {
            final progress = _orbController.value;

            return Container(
              width: widget.fabSize,
              height: widget.fabSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  // هالة زجاجية خفيفة وشفافة تمنع حجب المحتوى
                  BoxShadow(
                    color: (isDark ? SiyaqColors.accentGold : const Color(0xFFD97706))
                        .withOpacity(widget.isDragging ? 0.30 : 0.18),
                    blurRadius: widget.isDragging ? 20 : 12,
                    spreadRadius: widget.isDragging ? 2 : 0,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipOval(
                child: BackdropFilter(
                  // تغبيش زجاجي مثلج ناعم يظهر ما خلفه بانسيابية
                  filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      // شفافية عالية تتيح قراءة أي نص خلف الزر
                      color: isDark
                          ? Colors.white.withOpacity(0.08)
                          : Colors.white.withOpacity(0.35),
                      border: Border.all(
                        color: (isDark ? SiyaqColors.accentGold : const Color(0xFFD97706))
                            .withOpacity(0.65),
                        width: 1.5,
                      ),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // 1. تموجات ماء زجاجية شفافة جداً
                        CustomPaint(
                          size: Size(widget.fabSize, widget.fabSize),
                          painter: _RealisticLiquidWaterPainter(
                            progress: progress,
                            isDark: isDark,
                          ),
                        ),
                        // 2. فقاعات دقيقة هادئة
                        CustomPaint(
                          size: Size(widget.fabSize, widget.fabSize),
                          painter: _LiquidMicroBubblesPainter(
                            progress: progress,
                          ),
                        ),
                        // 3. أيقونة الإضافة (+) واضحة ورشيقة
                        Icon(
                          Icons.add_rounded,
                          color: isDark ? Colors.white : const Color(0xFF78350F),
                          size: 30,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.35),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// Realistic Liquid Water Painter (Ultra Translucent)
class _RealisticLiquidWaterPainter extends CustomPainter {
  final double progress;
  final bool isDark;

  _RealisticLiquidWaterPainter({
    required this.progress,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;
    final animAngle = progress * 2 * math.pi;

    final wavePath = Path();
    final baseLevel = height * 0.52;
    wavePath.moveTo(0, baseLevel);

    for (double x = 0; x <= width; x++) {
      final y = baseLevel +
          math.sin((x / width * 2 * math.pi) + animAngle) * 3.5 +
          math.cos((x / width * 4 * math.pi) - animAngle * 1.5) * 1.5;
      wavePath.lineTo(x, y);
    }
    wavePath.lineTo(width, height);
    wavePath.lineTo(0, height);
    wavePath.close();

    // ألوان أمواج شفافة جداً (opacity 0.12 - 0.22) تسمح بمرور نصوص الخلفية بوضوح
    final wavePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: isDark
            ? [
                SiyaqColors.accentGold.withOpacity(0.12),
                SiyaqColors.accentGoldDark.withOpacity(0.20),
              ]
            : [
                SiyaqColors.accentGoldLight.withOpacity(0.16),
                const Color(0xFFB45309).withOpacity(0.22),
              ],
        stops: const [0.0, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, width, height));

    canvas.drawPath(wavePath, wavePaint);
  }

  @override
  bool shouldRepaint(covariant _RealisticLiquidWaterPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.isDark != isDark;
  }
}

// Micro-Bubbles Painter
class _LiquidMicroBubblesPainter extends CustomPainter {
  final double progress;

  _LiquidMicroBubblesPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;
    final animAngle = progress * 2 * math.pi;

    final bubbles = [
      Offset(width * 0.28 + math.sin(animAngle) * 2.0, height * 0.65 - (progress * 10) % 14),
      Offset(width * 0.68 + math.cos(animAngle * 1.3) * 2.5, height * 0.72 - ((progress + 0.4) * 12) % 16),
      Offset(width * 0.46 + math.sin(animAngle * 1.8) * 1.8, height * 0.58 - ((progress + 0.7) * 8) % 10),
    ];

    final bubblePaint = Paint()
      ..color = Colors.white.withOpacity(0.35)
      ..style = PaintingStyle.fill;

    for (var bubble in bubbles) {
      canvas.drawCircle(bubble, 1.4, bubblePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _LiquidMicroBubblesPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
