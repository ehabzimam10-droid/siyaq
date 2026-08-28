import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/colors.dart';
import '../../../core/widgets/solarium_glass_container.dart';
import '../../../core/widgets/siyaq_toast.dart';
import '../../../core/widgets/clone_conflict_dialog.dart';
import '../../../core/models/task_item.dart';
import '../../dashboard/providers/schedule_provider.dart';
import '../../dashboard/widgets/task_addition_sheet.dart';

class TemplatesManagerScreen extends ConsumerStatefulWidget {
  const TemplatesManagerScreen({super.key});

  @override
  ConsumerState<TemplatesManagerScreen> createState() => _TemplatesManagerScreenState();
}

class _TemplatesManagerScreenState extends ConsumerState<TemplatesManagerScreen> {
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  int _selectedWeekday = 6; // السبت كقيمة افتراضية

  final List<Map<String, dynamic>> _weekdays = [
    {'name': 'الاثنين', 'value': 1},
    {'name': 'الثلاثاء', 'value': 2},
    {'name': 'الأربعاء', 'value': 3},
    {'name': 'الخميس', 'value': 4},
    {'name': 'الجمعة', 'value': 5},
    {'name': 'السبت', 'value': 6},
    {'name': 'الأحد', 'value': 7},
  ];

  Future<void> _selectTargetDate() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
      builder: (context, child) {
        return Theme(
          data: isDark
              ? ThemeData.dark().copyWith(
                  colorScheme: const ColorScheme.dark(
                    primary: SiyaqColors.accentGold,
                    onPrimary: Colors.black,
                    surface: Color(0xFF0F172A),
                    onSurface: Colors.white,
                  ),
                )
              : ThemeData.light().copyWith(
                  colorScheme: const ColorScheme.light(
                    primary: SiyaqColors.accentGoldDark,
                    onPrimary: Colors.white,
                    surface: Colors.white,
                    onSurface: Color(0xFF0F172A),
                  ),
                ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _applyTemplate() async {
    final allTasks = ref.read(scheduleProvider).allTasks;
    final weeklyTasks = allTasks.where((t) => t.taskType == 'weekly_routine' && t.weekday == _selectedWeekday).toList();

    if (weeklyTasks.isEmpty) {
      SiyaqToast.show(
        context,
        'يوم القالب المختار لا يحتوي على أي مهام لنسخها',
        type: SiyaqToastType.warning,
      );
      return;
    }

    final scheduleNotifier = ref.read(scheduleProvider.notifier);
    final analysis = scheduleNotifier.analyzeCloneOperation(
      incomingTasks: weeklyTasks,
      targetTaskType: 'special_day',
      targetDate: _selectedDate,
    );

    final nonDuplicate = analysis['nonDuplicateIncoming'] as List<TaskItem>;
    final existing = analysis['existingTargetTasks'] as List<TaskItem>;
    final conflicting = analysis['conflictingIncoming'] as List<TaskItem>;

    final weekdayName = _weekdays.firstWhere((w) => w['value'] == _selectedWeekday)['name'];
    final dateStr = DateFormat('yyyy/MM/dd', 'ar').format(_selectedDate);

    if (nonDuplicate.isEmpty) {
      SiyaqToast.show(
        context,
        'جميع مهام هذا القالب متطابقة وموجودة بالفعل في هذا التاريخ',
        type: SiyaqToastType.info,
      );
      return;
    }

    if (conflicting.isNotEmpty) {
      final mode = await CloneConflictDialog.show(
        context,
        conflictingCount: conflicting.length,
        totalIncomingCount: nonDuplicate.length,
      );

      if (mode == null) return;

      final count = await scheduleNotifier.executeCloneTasks(
        nonDuplicateIncoming: nonDuplicate,
        existingTargetTasks: existing,
        targetTaskType: 'special_day',
        targetDate: _selectedDate,
        mode: mode,
      );

      if (mode == 'replace') {
        SiyaqToast.show(context, 'تم استبدال الجدول بالكامل وتطبيق قالب $weekdayName على تاريخ $dateStr! ⭐', type: SiyaqToastType.success);
      } else if (mode == 'skip_conflicts') {
        if (count > 0) {
          SiyaqToast.show(context, 'تم تطبيق $count مهام غير متعارضة من قالب $weekdayName على تاريخ $dateStr! ⭐', type: SiyaqToastType.success);
        } else {
          SiyaqToast.show(context, 'تم تخطي جميع المهام لتعارضها مع أوقات الجدول الحالي', type: SiyaqToastType.warning);
        }
      } else {
        SiyaqToast.show(context, 'تم دمج وتطبيق $count مهام من قالب $weekdayName على تاريخ $dateStr! ⭐', type: SiyaqToastType.success);
      }
    } else {
      final count = await scheduleNotifier.executeCloneTasks(
        nonDuplicateIncoming: nonDuplicate,
        existingTargetTasks: existing,
        targetTaskType: 'special_day',
        targetDate: _selectedDate,
        mode: 'add_all',
      );
      SiyaqToast.show(context, 'تم تطبيق قالب يوم $weekdayName بنجاح على تاريخ $dateStr! ($count مهام) ⭐', type: SiyaqToastType.success);
    }
  }

  void _openAddTaskForSpecialDay() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return TaskAdditionSheet(
          initialDate: _selectedDate,
          allowedTaskType: 'special_day',
        );
      },
    );
  }

  void _editTaskForSpecialDay(TaskItem task) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return TaskAdditionSheet(
          initialDate: _selectedDate,
          allowedTaskType: 'special_day',
          taskToEdit: task,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scheduleState = ref.watch(scheduleProvider);

    // مهام اليوم المميز المختار
    final specialTasksForSelectedDate = scheduleState.allTasks.where((t) {
      if (t.taskType != 'special_day') return false;
      return t.startTime.year == _selectedDate.year &&
          t.startTime.month == _selectedDate.month &&
          t.startTime.day == _selectedDate.day;
    }).toList();

    specialTasksForSelectedDate.sort((a, b) => a.startTime.compareTo(b.startTime));

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [SiyaqColors.darkBgGradientStart, SiyaqColors.darkBgGradientEnd]
                : [SiyaqColors.lightBgGradientStart, SiyaqColors.lightBgGradientEnd],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // شريط العناوين
              Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back_ios_new, size: 20, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.auto_awesome_rounded, color: isDark ? SiyaqColors.accentGold : const Color(0xFFB45309), size: 24),
                  const SizedBox(width: 8),
                  Text(
                    'قوالب الأيام المميزة',
                    style: TextStyle(
                      fontSize: 20, 
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // بطاقة إنشاء وتطبيق القالب
              SolariumGlassContainer(
                padding: const EdgeInsets.all(20),
                borderRadius: 24,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.style_rounded, color: isDark ? SiyaqColors.accentGold : const Color(0xFFB45309), size: 22),
                        const SizedBox(width: 8),
                        Text(
                          'تطبيق قالب روتين على يوم مميز',
                          style: TextStyle(
                            fontSize: 16, 
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'يمكنك اختيار تاريخ يوم مميز مستقبلي (مثل يوم إجازة، سفر، أو مناسبة) ونسخ روتين أحد أيام الأسبوع إليه للتعديل عليه مباشرة دون الحاجة للبدء من الصفر.',
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.5,
                        color: isDark ? SiyaqColors.darkTextSecondary : const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // اختيار يوم الأسبوع الأساسي كقالب
                    Text(
                      'اختر يوم الأسبوع (المصدر/القالب):', 
                      style: TextStyle(
                        fontWeight: FontWeight.bold, 
                        fontSize: 13,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<int>(
                      value: _selectedWeekday,
                      dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A), fontSize: 14),
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                      items: _weekdays.map((w) {
                        return DropdownMenuItem<int>(
                          value: w['value'],
                          child: Text(w['name']),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedWeekday = val;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // اختيار التاريخ المستهدف
                    Text(
                      'اختر التاريخ المستهدف (اليوم المميز):', 
                      style: TextStyle(
                        fontWeight: FontWeight.bold, 
                        fontSize: 13,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: _selectTargetDate,
                      icon: Icon(Icons.calendar_today_rounded, size: 18, color: isDark ? SiyaqColors.accentGold : const Color(0xFFD97706)),
                      label: Text(
                        'التاريخ المختار: ${DateFormat('yyyy/MM/dd', 'ar').format(_selectedDate)}',
                        style: TextStyle(
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        side: BorderSide(color: isDark ? SiyaqColors.accentGold.withOpacity(0.45) : const Color(0xFFCBD5E1)),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // زر النسخ والتطبيق
                    ElevatedButton.icon(
                      onPressed: _applyTemplate,
                      icon: const Icon(Icons.copy_rounded, size: 18),
                      label: const Text('تطبيق كقالب لليوم المميز'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark ? SiyaqColors.accentGold : const Color(0xFFD97706),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // بطاقة مهام اليوم المميز المختار
              SolariumGlassContainer(
                padding: const EdgeInsets.all(20),
                borderRadius: 24,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'مهام ${DateFormat('yyyy/MM/dd', 'ar').format(_selectedDate)}',
                              style: TextStyle(
                                fontSize: 16, 
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${specialTasksForSelectedDate.length} مهام مخصصة لهذا اليوم المميز',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? SiyaqColors.darkTextSecondary : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: Icon(Icons.add_circle_outline_rounded, color: isDark ? SiyaqColors.accentGold : const Color(0xFFD97706), size: 26),
                          tooltip: 'إضافة مهمة لهذا اليوم المميز',
                          onPressed: _openAddTaskForSpecialDay,
                        ),
                      ],
                    ),
                    Divider(height: 24, color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),

                    if (specialTasksForSelectedDate.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24.0),
                        child: Text(
                          'لا توجد مهام مضافة لهذا التاريخ بعد.\nيمكنك تطبيق قالب من الأعلى أو الضغط على زر الإضافة (+).',
                          style: TextStyle(
                            color: isDark ? SiyaqColors.darkTextSecondary : const Color(0xFF64748B),
                            fontSize: 13,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      )
                    else
                      ...specialTasksForSelectedDate.map((task) {
                        final startStr = DateFormat('hh:mm a').format(task.startTime);
                        final endStr = DateFormat('hh:mm a').format(task.endTime);

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8.0),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: isDark ? SiyaqColors.accentGold.withOpacity(0.2) : const Color(0xFFE2E8F0)),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      task.title, 
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold, 
                                        fontSize: 14,
                                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '$startStr - $endStr',
                                      style: TextStyle(
                                        fontSize: 12, 
                                        color: isDark ? Colors.white60 : const Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.edit_outlined, color: isDark ? SiyaqColors.accentGold : const Color(0xFFD97706), size: 20),
                                tooltip: 'تعديل المهمة',
                                onPressed: () => _editTaskForSpecialDay(task),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                                tooltip: 'حذف المهمة',
                                onPressed: () {
                                  ref.read(scheduleProvider.notifier).deleteTask(task.id);
                                  SiyaqToast.show(
                                    context,
                                    'تم حذف المهمة من اليوم المميز',
                                    type: SiyaqToastType.info,
                                  );
                                },
                              ),
                            ],
                          ),
                        );
                      }),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
