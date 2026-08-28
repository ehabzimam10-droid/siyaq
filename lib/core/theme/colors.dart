import 'package:flutter/material.dart';

class SiyaqColors {
  // --- Dark Mode (Stitch Deep Sea Navy #051424) ---
  static const Color darkBg = Color(0xFF051424);
  static const Color darkBgGradientStart = Color(0xFF071A2E);
  static const Color darkBgGradientEnd = Color(0xFF020B14);
  
  // Fluid WebGL Shader Light Leaks & Mesh Accents
  static const Color darkMeshDeepSea = Color(0xFF051424);
  static const Color darkMeshRoyalBlue = Color(0xFF1A3366);
  static const Color darkMeshAmberGlow = Color(0xFFCC661A);
  
  // Pure Glass Fill (5% opacity for maximum backdrop-filter refraction!)
  static const Color darkGlassBg = Color(0x0DFFFFFF); // 5% rgba(255, 255, 255, 0.05)
  static const Color darkGlassBorder = Color(0x26FFFFFF); // 15% rgba(255, 255, 255, 0.15)
  static const Color darkGlassBorderGold = Color(0x40E8C17D);
  
  static const Color darkTextPrimary = Color(0xFFD4E4FA);
  static const Color darkTextSecondary = Color(0xFF9A8F80);

  // --- Light Mode (Pearl Opal & Warm Cashmere) ---
  static const Color lightBg = Color(0xFFF4F6FB);
  static const Color lightBgGradientStart = Color(0xFFFAFCFF);
  static const Color lightBgGradientEnd = Color(0xFFE8EEF5);
  
  // Fluid Organic Mesh Accents (Light Mode)
  static const Color lightMeshOpal = Color(0xFFE3EBF7);
  static const Color lightMeshCashmere = Color(0xFFF2EBE1);
  static const Color lightMeshGoldGlow = Color(0xFFF7F0DC);

  static const Color lightGlassBg = Color(0x9EFFFFFF); // 62% translucent frosted porcelain glass fill
  static const Color lightGlassBorder = Color(0xB3FFFFFF); // Frosted highlight glass stroke
  static const Color lightGlassBorderDark = Color(0x1F0F172A); // Subtle crisp border
  
  static const Color lightTextPrimary = Color(0xFF0F172A);
  static const Color lightTextSecondary = Color(0xFF64748B);

  // --- Brand Accents & Liquid Orb Colors ---
  static const Color accentGold = Color(0xFFE8C17D);
  static const Color accentGoldLight = Color(0xFFFFDEA9);
  static const Color accentGoldDark = Color(0xFF775920);
  static const Color accentGoldGlow = Color(0x50E8C17D);
  
  static const Color accentTeal = Color(0xFF2DD4BF);
  static const Color accentTealGlow = Color(0x402DD4BF);

  static const Color accentBlue = Color(0xFF38BDF8);
  
  // 3D Liquid Orb Physics Gradients
  static const List<Color> orbLiquidGradient = [
    Color(0xFFFFDF9E),
    Color(0xFFE5B25D),
    Color(0xFF9E6815),
  ];
  
  static const List<Color> orbGlassRefraction = [
    Color(0x99FFFFFF),
    Color(0x22FFFFFF),
    Color(0x00FFFFFF),
    Color(0x33E5B25D),
  ];
  
  // --- Glass Effects & Refractions ---
  static const List<Color> darkGlassGlow = [
    Color(0x1AFFFFFF),
    Color(0x08FFFFFF),
  ];
  
  static const List<Color> lightGlassGlow = [
    Color(0x50FFFFFF),
    Color(0x18FFFFFF),
  ];
}
