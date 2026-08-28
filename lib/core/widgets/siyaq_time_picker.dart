import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/colors.dart';
import 'solarium_glass_container.dart';

Future<TimeOfDay?> showSiyaqTimePicker(
  BuildContext context, {
  required TimeOfDay initialTime,
  String title = 'تحديد الوقت',
}) async {
  return showDialog<TimeOfDay>(
    context: context,
    barrierColor: Colors.black.withOpacity(0.65),
    builder: (context) => _SiyaqTimePickerDialog(
      initialTime: initialTime,
      title: title,
    ),
  );
}

class _SiyaqTimePickerDialog extends StatefulWidget {
  final TimeOfDay initialTime;
  final String title;

  const _SiyaqTimePickerDialog({
    required this.initialTime,
    required this.title,
  });

  @override
  State<_SiyaqTimePickerDialog> createState() => _SiyaqTimePickerDialogState();
}

class _SiyaqTimePickerDialogState extends State<_SiyaqTimePickerDialog> {
  late int _selectedHour; // 1 - 12
  late int _selectedMinute; // 0 - 59
  late bool _isAm; // true for AM, false for PM

  @override
  void initState() {
    super.initState();
    final hour = widget.initialTime.hour;
    _selectedMinute = widget.initialTime.minute;
    _isAm = hour < 12;
    _selectedHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
  }

  void _adjustHour(int delta) {
    setState(() {
      int next = _selectedHour + delta;
      if (next > 12) next = 1;
      if (next < 1) next = 12;
      _selectedHour = next;
    });
  }

  void _adjustMinute(int delta) {
    setState(() {
      int next = _selectedMinute + delta;
      if (next >= 60) next = 0;
      if (next < 0) next = 55;
      _selectedMinute = next;
    });
  }

  TimeOfDay _getResultTime() {
    int hour24;
    if (_isAm) {
      hour24 = _selectedHour == 12 ? 0 : _selectedHour;
    } else {
      hour24 = _selectedHour == 12 ? 12 : _selectedHour + 12;
    }
    return TimeOfDay(hour: hour24, minute: _selectedMinute);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.70 : 0.25),
              blurRadius: 32,
              spreadRadius: 2,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 32, sigmaY: 32),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFB131D33) : const Color(0xFCFFFFFF),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: SiyaqColors.accentGold.withOpacity(isDark ? 0.40 : 0.60),
                  width: 1.5,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Title
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: SiyaqColors.accentGold.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.access_time_filled_rounded,
                              color: SiyaqColors.accentGold,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            widget.title,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // AM / PM Switcher Tabs
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _isAm = true),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: _isAm
                                    ? SiyaqColors.accentGold
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: _isAm
                                    ? [
                                        BoxShadow(
                                          color: SiyaqColors.accentGold.withOpacity(0.35),
                                          blurRadius: 10,
                                          offset: const Offset(0, 3),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Center(
                                child: Text(
                                  'صباحاً (ص)',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: _isAm
                                        ? Colors.white
                                        : (isDark ? Colors.white60 : Colors.black54),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _isAm = false),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: !_isAm
                                    ? const Color(0xFF0EA5E9)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: !_isAm
                                    ? [
                                        BoxShadow(
                                          color: const Color(0xFF0EA5E9).withOpacity(0.35),
                                          blurRadius: 10,
                                          offset: const Offset(0, 3),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Center(
                                child: Text(
                                  'مساءً (م)',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: !_isAm
                                        ? Colors.white
                                        : (isDark ? Colors.white60 : Colors.black54),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Large Numbers Display with Steppers
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Hours Section
                      _buildNumberStepper(
                        value: _selectedHour.toString().padLeft(2, '0'),
                        label: 'الساعة',
                        onIncrement: () => _adjustHour(1),
                        onDecrement: () => _adjustHour(-1),
                        isDark: isDark,
                      ),
                      
                      // Colon Separator
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          ':',
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: SiyaqColors.accentGold,
                          ),
                        ),
                      ),

                      // Minutes Section
                      _buildNumberStepper(
                        value: _selectedMinute.toString().padLeft(2, '0'),
                        label: 'الدقيقة',
                        onIncrement: () => _adjustMinute(5),
                        onDecrement: () => _adjustMinute(-5),
                        isDark: isDark,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Quick Minute Presets (00, 15, 30, 45)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [0, 15, 30, 45].map((m) {
                      final isSelected = _selectedMinute == m;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: ActionChip(
                          label: Text(
                            ':',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: isSelected
                                  ? Colors.white
                                  : (isDark ? Colors.white70 : Colors.black87),
                            ),
                          ),
                          backgroundColor: isSelected
                              ? SiyaqColors.accentGold
                              : (isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
                          onPressed: () => setState(() => _selectedMinute = m),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 28),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text('إلغاء', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(_getResultTime()),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: SiyaqColors.accentGold,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text(
                            'تأكيد الوقت',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNumberStepper({
    required String value,
    required String label,
    required VoidCallback onIncrement,
    required VoidCallback onDecrement,
    required bool isDark,
  }) {
    return Column(
      children: [
        IconButton(
          icon: const Icon(Icons.keyboard_arrow_up_rounded, size: 30),
          color: SiyaqColors.accentGold,
          onPressed: onIncrement,
        ),
        Container(
          width: 80,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: SiyaqColors.accentGold.withOpacity(isDark ? 0.35 : 0.50),
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                  fontFamily: 'Outfit',
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 30),
          color: SiyaqColors.accentGold,
          onPressed: onDecrement,
        ),
      ],
    );
  }
}
