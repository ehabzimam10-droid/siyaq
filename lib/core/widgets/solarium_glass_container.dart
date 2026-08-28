import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/colors.dart';

class SolariumGlassContainer extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final double blur;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final List<BoxShadow>? boxShadow;
  final Color? customBgColor;
  final Color? customBorderColor;

  const SolariumGlassContainer({
    super.key,
    required this.child,
    this.borderRadius = 24.0,
    this.blur = 22.0,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.boxShadow,
    this.customBgColor,
    this.customBorderColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Pure Glass Colors (5% for dark, 62% translucent frosted porcelain for light)
    final defaultBg = isDark ? SiyaqColors.darkGlassBg : SiyaqColors.lightGlassBg;
    final defaultBorder = isDark ? SiyaqColors.darkGlassBorder : SiyaqColors.lightGlassBorder;

    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: boxShadow ?? [
          BoxShadow(
            color: isDark ? Colors.black.withOpacity(0.35) : const Color(0x0C0F172A),
            blurRadius: isDark ? 30 : 16,
            spreadRadius: isDark ? -5 : 0,
            offset: const Offset(0, 4),
          ),
          if (isDark)
            BoxShadow(
              color: Colors.white.withOpacity(0.03),
              blurRadius: 10,
              spreadRadius: -2,
              offset: const Offset(0, -2),
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 32.0, sigmaY: 32.0),
          child: Container(
            padding: padding ?? const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: customBgColor ?? defaultBg,
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                color: customBorderColor ?? defaultBorder,
                width: 1.0,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
