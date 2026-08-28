import 'package:flutter/material.dart';
import 'solarium_glass_container.dart';
import '../theme/colors.dart';

class FloatingBottomBarItem {
  final IconData icon;
  final String label;

  FloatingBottomBarItem({
    required this.icon,
    required this.label,
  });
}

class FloatingBottomBar extends StatelessWidget {
  final int selectedIndex;
  final List<FloatingBottomBarItem> items;
  final ValueChanged<int> onTap;

  const FloatingBottomBar({
    super.key,
    required this.selectedIndex,
    required this.items,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return SafeArea(
      bottom: true,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 460.0),
          margin: EdgeInsets.only(
            left: 20.0,
            right: 20.0,
            bottom: bottomPadding > 0 ? 0.0 : 12.0,
          ),
          child: SolariumGlassContainer(
          borderRadius: 28.0,
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (index) {
              final item = items[index];
              final isSelected = index == selectedIndex;
              
              return InkWell(
                onTap: () => onTap(index),
                borderRadius: BorderRadius.circular(20),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOutCubic,
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? (isDark 
                            ? SiyaqColors.accentGold.withOpacity(0.15) 
                            : SiyaqColors.accentGold.withOpacity(0.1))
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        item.icon,
                        color: isSelected 
                            ? (isDark ? SiyaqColors.accentGold : const Color(0xFFB45309))
                            : (isDark ? SiyaqColors.darkTextSecondary : SiyaqColors.lightTextSecondary),
                        size: isSelected ? 26 : 22,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.label,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected 
                              ? (isDark ? Colors.white : const Color(0xFFB45309))
                              : (isDark ? SiyaqColors.darkTextSecondary : SiyaqColors.lightTextSecondary),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    ),
    );
  }
}
