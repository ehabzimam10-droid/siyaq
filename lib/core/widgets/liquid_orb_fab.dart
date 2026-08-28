import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../../features/dashboard/widgets/task_addition_sheet.dart';

class LiquidDraggableFab extends StatefulWidget {
  final DateTime? initialDate;

  const LiquidDraggableFab({
    super.key,
    this.initialDate,
  });

  @override
  State<LiquidDraggableFab> createState() => _LiquidDraggableFabState();
}

class _LiquidDraggableFabState extends State<LiquidDraggableFab>
    with SingleTickerProviderStateMixin {
  late AnimationController _orbController;
  Offset? _position;
  bool _isDragging = false;

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

  void _openTaskSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        return TaskAdditionSheet(
          initialDate: widget.initialDate ?? DateTime.now(),
          allowedTaskType: 'single_date',
        );
      },
    );
  }

  double _dragDistance = 0;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;
    const fabSize = 62.0;

    // حدود الأمان: تمنع الخروج عن الشاشة أو الدخول تحت الشريط العلوي أو السفلي
    final minX = 8.0;
    final maxX = math.max(minX, screenWidth - fabSize - 8.0);
    final minY = mediaQuery.padding.top + 70.0; // أسفل الشريط العلوي
    final maxY = math.max(minY, screenHeight - mediaQuery.padding.bottom - 90.0 - fabSize); // أعلى الشريط السفلي

    // تهيئة الموضع المبدئي وتثبيته داخل الحدود الآمنة
    final currentPos = _position ?? Offset(maxX - 8.0, maxY - 12.0);
    final clampedPos = Offset(
      currentPos.dx.clamp(minX, maxX),
      currentPos.dy.clamp(minY, maxY),
    );

    return Positioned(
      left: clampedPos.dx,
      top: clampedPos.dy,
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: (event) {
          _dragDistance = 0;
          setState(() {
            _isDragging = true;
            _position = clampedPos;
          });
        },
        onPointerMove: (event) {
          if (!_isDragging) return;
          _dragDistance += event.delta.distance;
          final cur = _position ?? clampedPos;
          final nextX = (cur.dx + event.delta.dx).clamp(minX, maxX);
          final nextY = (cur.dy + event.delta.dy).clamp(minY, maxY);
          setState(() {
            _position = Offset(nextX, nextY);
          });
        },
        onPointerUp: (event) {
          final wasDragging = _isDragging;
          setState(() {
            _isDragging = false;
          });
          if (wasDragging && _dragDistance < 10) {
            _openTaskSheet(context);
          }
        },
        onPointerCancel: (_) {
          setState(() {
            _isDragging = false;
          });
        },
        child: AnimatedScale(
          scale: _isDragging ? 1.15 : 1.0,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOutBack,
          child: AnimatedBuilder(
            animation: _orbController,
            builder: (context, child) {
              final progress = _orbController.value;

              return Container(
                width: fabSize,
                height: fabSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    // Ambient Liquid Halo Glow
                    BoxShadow(
                      color: (isDark ? SiyaqColors.accentGold : const Color(0xFFD97706)).withOpacity(isDark ? 0.55 : 0.40),
                      blurRadius: _isDragging ? 36 : 24,
                      spreadRadius: _isDragging ? 4 : 2,
                      offset: const Offset(0, 8),
                    ),
                    // Drop shadow
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.50 : 0.20),
                      blurRadius: 16,
                      spreadRadius: -2,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          center: const Alignment(-0.35, -0.45),
                          radius: 0.95,
                          colors: isDark
                              ? [
                                  Colors.white.withOpacity(0.50),
                                  SiyaqColors.accentGold.withOpacity(0.40),
                                  SiyaqColors.accentGoldDark.withOpacity(0.70),
                                  const Color(0xFF0F172A).withOpacity(0.85),
                                ]
                              : [
                                  Colors.white.withOpacity(0.90),
                                  SiyaqColors.accentGoldLight.withOpacity(0.70),
                                  SiyaqColors.accentGold.withOpacity(0.60),
                                  const Color(0xFFB45309).withOpacity(0.75),
                                ],
                          stops: const [0.0, 0.40, 0.75, 1.0],
                        ),
                        border: Border.all(
                          color: Colors.white.withOpacity(isDark ? 0.75 : 0.95),
                          width: 2.0,
                        ),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // 1. Water waves
                          CustomPaint(
                            size: const Size(fabSize, fabSize),
                            painter: _RealisticLiquidWaterPainter(
                              progress: progress,
                              isDark: isDark,
                            ),
                          ),
                          // 2. Micro bubbles
                          CustomPaint(
                            size: const Size(fabSize, fabSize),
                            painter: _LiquidMicroBubblesPainter(
                              progress: progress,
                            ),
                          ),
                          // 3. Top lens highlight
                          Positioned(
                            top: 4,
                            left: 10,
                            right: 10,
                            height: 16,
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: const BorderRadius.all(
                                  Radius.elliptical(25, 10),
                                ),
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.white.withOpacity(isDark ? 0.85 : 0.95),
                                    Colors.white.withOpacity(0.0),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          // 4. Center icon
                          Icon(
                            Icons.add_rounded,
                            color: isDark ? Colors.white : const Color(0xFF3B1A00),
                            size: 32,
                            shadows: [
                              Shadow(
                                color: Colors.black.withOpacity(0.50),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                              Shadow(
                                color: (isDark ? SiyaqColors.accentGoldLight : Colors.white).withOpacity(0.80),
                                blurRadius: 8,
                                offset: const Offset(0, -1),
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
      ),
    );
  }
}

// Realistic Liquid Water & Caustics Painter
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

    // 1. Organic Wave Path
    final wavePath = Path();
    final baseLevel = height * 0.48;
    wavePath.moveTo(0, baseLevel);

    for (double x = 0; x <= width; x++) {
      final y = baseLevel +
          math.sin((x / width * 2 * math.pi) + animAngle) * 4.5 +
          math.cos((x / width * 4 * math.pi) - animAngle * 1.5) * 2.0;
      wavePath.lineTo(x, y);
    }
    wavePath.lineTo(width, height);
    wavePath.lineTo(0, height);
    wavePath.close();

    final wavePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: isDark
            ? [
                SiyaqColors.accentGoldLight.withOpacity(0.40),
                SiyaqColors.accentGold.withOpacity(0.60),
                SiyaqColors.accentGoldDark.withOpacity(0.75),
              ]
            : [
                SiyaqColors.accentGoldLight.withOpacity(0.65),
                SiyaqColors.accentGold.withOpacity(0.75),
                const Color(0xFFB45309).withOpacity(0.85),
              ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, width, height));

    canvas.drawPath(wavePath, wavePaint);
  }

  @override
  bool shouldRepaint(covariant _RealisticLiquidWaterPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.isDark != isDark;
  }
}

// Micro-Bubbles inside Liquid Painter
class _LiquidMicroBubblesPainter extends CustomPainter {
  final double progress;

  _LiquidMicroBubblesPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;
    final animAngle = progress * 2 * math.pi;

    final bubbles = [
      Offset(width * 0.28 + math.sin(animAngle) * 2.5, height * 0.65 - (progress * 10) % 14),
      Offset(width * 0.68 + math.cos(animAngle * 1.3) * 3, height * 0.72 - ((progress + 0.4) * 12) % 16),
      Offset(width * 0.46 + math.sin(animAngle * 1.8) * 2, height * 0.58 - ((progress + 0.7) * 8) % 10),
    ];

    final bubblePaint = Paint()
      ..color = Colors.white.withOpacity(0.65)
      ..style = PaintingStyle.fill;

    for (var bubble in bubbles) {
      canvas.drawCircle(bubble, 1.8, bubblePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _LiquidMicroBubblesPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
