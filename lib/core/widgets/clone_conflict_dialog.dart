import 'package:flutter/material.dart';
import '../theme/colors.dart';

class CloneConflictDialog extends StatelessWidget {
  final int conflictingCount;
  final int totalIncomingCount;

  const CloneConflictDialog({
    super.key,
    required this.conflictingCount,
    required this.totalIncomingCount,
  });

  static Future<String?> show(
    BuildContext context, {
    required int conflictingCount,
    required int totalIncomingCount,
  }) {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => CloneConflictDialog(
        conflictingCount: conflictingCount,
        totalIncomingCount: totalIncomingCount,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Icon & Title
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFFFEF3C7).withOpacity(0.12) : const Color(0xFFFEF3C7),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.alt_route_rounded,
                    color: isDark ? SiyaqColors.accentGold : const Color(0xFFB45309),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'تعارض في أوقات المهام',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'يوجد $conflictingCount مهام متعارضة من أصل $totalIncomingCount مهام',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white60 : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'اختر الإجراء المناسب للتعامل مع هذا الاستيراد:',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.white70 : const Color(0xFF334155),
              ),
            ),
            const SizedBox(height: 14),

            // Option 1: Replace Complete Schedule
            _buildOptionCard(
              context: context,
              mode: 'replace',
              icon: Icons.swap_horiz_rounded,
              iconColor: const Color(0xFFEF4444),
              iconBgColor: isDark ? const Color(0xFFEF4444).withOpacity(0.15) : const Color(0xFFFEE2E2),
              title: '1. استبدال الجدول الحالي بالكامل',
              description: 'حذف جميع مهام اليوم الحالي واستبدالها بمهام اليوم المستورد.',
              isDark: isDark,
            ),
            const SizedBox(height: 10),

            // Option 2: Skip Conflicting Tasks
            _buildOptionCard(
              context: context,
              mode: 'skip_conflicts',
              icon: Icons.filter_alt_outlined,
              iconColor: isDark ? Colors.cyanAccent : const Color(0xFF0D9488),
              iconBgColor: isDark ? Colors.cyanAccent.withOpacity(0.15) : const Color(0xFFCCFBF1),
              title: '2. تجنب المهام المتعارضة',
              description: 'إضافة المهام غير المتعارضة فقط، وتخطي المهام المتداخلة مع مواعيدك الحالية.',
              isDark: isDark,
            ),
            const SizedBox(height: 10),

            // Option 3: Add All Tasks
            _buildOptionCard(
              context: context,
              mode: 'add_all',
              icon: Icons.playlist_add_rounded,
              iconColor: isDark ? SiyaqColors.accentGold : const Color(0xFFD97706),
              iconBgColor: isDark ? SiyaqColors.accentGold.withOpacity(0.15) : const Color(0xFFFEF3C7),
              title: '3. إضافة جميع المهام',
              description: 'دمج وإضافة كافة المهام المستوردة مع الجدول الحالي.',
              isDark: isDark,
            ),
            const SizedBox(height: 16),

            // Cancel Button
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              style: TextButton.styleFrom(
                foregroundColor: isDark ? Colors.white60 : const Color(0xFF64748B),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text('إلغاء الاستيراد', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionCard({
    required BuildContext context,
    required String mode,
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required String description,
    required bool isDark,
  }) {
    return InkWell(
      onTap: () => Navigator.of(context).pop(mode),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
            width: 1.2,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.white60 : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
