import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../../features/dashboard/widgets/task_addition_sheet.dart';

/// Recognizer that immediately claims the gesture arena so underlying scrollables
/// (like ListView) and browser touch-scroll cannot steal or cancel the drag.
class _ImmediatePanGestureRecognizer extends PanGestureRecognizer {
  @override
  void addAllowedPointer(PointerDownEvent event) {
    super.addAllowedPointer(event);
    resolve(GestureDisposition.accepted);
  }
}

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
  double _dragDistance = 0;

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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;
    const fabSize = 62.0;

    // حدود الأمان: تمنع الخروج عن الشاشة أو الدخول تحت الشريط العلوي أو السفلي
    final minX = 12.0;
    final maxX = math.max(minX, screenWidth - fabSize - 12.0);
    final minY = mediaQuery.padding.top + 72.0; // أسفل الشريط العلوي
    final maxY = math.max(minY, screenHeight - mediaQuery.padding.bottom - 95.0 - fabSize); // أعلى الشريط السفلي

    // الموضع المبدئي الافتراضي أسفل يمين الشاشة (فوق الشريط السفلي)
    final defaultPos = Offset(maxX - 8.0, maxY - 12.0);
    final currentPos = _position ?? defaultPos;
    final clampedPos = Offset(
      currentPos.dx.clamp(minX, maxX),
      currentPos.dy.clamp(minY, maxY),
    );

    return Positioned(
      left: clampedPos.dx,
      top: clampedPos.dy,
      child: RawGestureDetector(
        gestures: {
          _ImmediatePanGestureRecognizer: GestureRecognizerFactoryWithHandlers<_ImmediatePanGestureRecognizer>(
            () => _ImmediatePanGestureRecognizer(),
            (_ImmediatePanGestureRecognizer instance) {
              instance.onStart = (DragStartDetails details) {
                _dragDistance = 0;
                setState(() {
                  _isDragging = true;
                  _position = clampedPos;
                });
              };
              instance.onUpdate = (DragUpdateDetails details) {
                _dragDistance += details.delta.distance;
                final cur = _position ?? clampedPos;
                final nextX = (cur.dx + details.delta.dx).clamp(minX, maxX);
                final nextY = (cur.dy + details.delta.dy).clamp(minY, maxY);
                setState(() {
                  _position = Offset(nextX, nextY);
                });
              };
              instance.onEnd = (DragEndDetails details) {
                final wasDragging = _isDragging;
                setState(() {
                  _isDragging = false;
                });
                if (wasDragging && _dragDistance < 10) {
                  _openTaskSheet(context);
                }
              };
              instance.onCancel = () {
                setState(() {
                  _isDragging = false;
                });
              };
            },
          ),
        },
        behavior: HitTestBehavior.opaque,
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
                    // هالة زجاجية شفافة وناعمة
                    BoxShadow(
                      color: (isDark ? SiyaqColors.accentGold : const Color(0xFFD97706)).withOpacity(isDark ? 0.25 : 0.20),
                      blurRadius: _isDragging ? 24 : 16,
                      spreadRadius: _isDragging ? 2 : 1,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: BackdropFilter(
                    // تأثير الزجاج المثلج الشفاف لإظهار ما خلف الزر بوضوح
                    filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        // خلفية نصف شفافة تتيح رؤية وقراءة النصوص والعناصر من خلفها
                        gradient: RadialGradient(
                          center: const Alignment(-0.35, -0.45),
                          radius: 0.95,
                          colors: isDark
                              ? [
                                  Colors.white.withOpacity(0.22),
                                  SiyaqColors.accentGold.withOpacity(0.18),
                                  const Color(0xFF0F172A).withOpacity(0.35),
                                ]
                              : [
                                  Colors.white.withOpacity(0.40),
                                  SiyaqColors.accentGoldLight.withOpacity(0.25),
                                  const Color(0xFFB45309).withOpacity(0.20),
                                ],
                          stops: const [0.0, 0.45, 1.0],
                        ),
                        border: Border.all(
                          color: (isDark ? Colors.white : SiyaqColors.accentGold).withOpacity(isDark ? 0.35 : 0.50),
                          width: 1.5,
                        ),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // 1. أمواج سائلة شفافة
                          CustomPaint(
                            size: const Size(fabSize, fabSize),
                            painter: _RealisticLiquidWaterPainter(
                              progress: progress,
                              isDark: isDark,
                            ),
                          ),
                          // 2. فقاعات دقيقة ناعمة
                          CustomPaint(
                            size: const Size(fabSize, fabSize),
                            painter: _LiquidMicroBubblesPainter(
                              progress: progress,
                            ),
                          ),
                          // 3. لمعة زجاجية علوية رقيقة
                          Positioned(
                            top: 4,
                            left: 12,
                            right: 12,
                            height: 14,
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: const BorderRadius.all(
                                  Radius.elliptical(25, 10),
                                ),
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.white.withOpacity(isDark ? 0.45 : 0.60),
                                    Colors.white.withOpacity(0.0),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          // 4. أيقونة الإضافة الذهبية
                          Icon(
                            Icons.add_rounded,
                            color: isDark ? Colors.white : const Color(0xFF78350F),
                            size: 32,
                            shadows: [
                              Shadow(
                                color: Colors.black.withOpacity(0.35),
                                blurRadius: 4,
                                offset: const Offset(0, 1.5),
                              ),
                              Shadow(
                                color: (isDark ? SiyaqColors.accentGoldLight : Colors.white).withOpacity(0.60),
                                blurRadius: 6,
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

// Realistic Liquid Water & Caustics Painter (Translucent Edition)
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
    final baseLevel = height * 0.52;
    wavePath.moveTo(0, baseLevel);

    for (double x = 0; x <= width; x++) {
      final y = baseLevel +
          math.sin((x / width * 2 * math.pi) + animAngle) * 4.0 +
          math.cos((x / width * 4 * math.pi) - animAngle * 1.5) * 1.8;
      wavePath.lineTo(x, y);
    }
    wavePath.lineTo(width, height);
    wavePath.lineTo(0, height);
    wavePath.close();

    // ألوان أمواج شفافة تسمح برؤية النصوص خلفها
    final wavePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: isDark
            ? [
                SiyaqColors.accentGoldLight.withOpacity(0.20),
                SiyaqColors.accentGold.withOpacity(0.28),
                SiyaqColors.accentGoldDark.withOpacity(0.35),
              ]
            : [
                SiyaqColors.accentGoldLight.withOpacity(0.25),
                SiyaqColors.accentGold.withOpacity(0.30),
                const Color(0xFFB45309).withOpacity(0.35),
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
      ..color = Colors.white.withOpacity(0.40)
      ..style = PaintingStyle.fill;

    for (var bubble in bubbles) {
      canvas.drawCircle(bubble, 1.6, bubblePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _LiquidMicroBubblesPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
