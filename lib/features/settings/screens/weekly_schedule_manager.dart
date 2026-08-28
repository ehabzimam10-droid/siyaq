import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/colors.dart';
import '../../../core/widgets/solarium_glass_container.dart';
import '../../../core/widgets/floating_app_bar.dart';
import '../../../core/widgets/siyaq_toast.dart';
import '../../../core/widgets/clone_conflict_dialog.dart';
import '../../dashboard/providers/schedule_provider.dart';
import '../../dashboard/widgets/task_addition_sheet.dart';
import '../../../core/models/task_item.dart';

class WeeklyScheduleManager extends ConsumerStatefulWidget {
  const WeeklyScheduleManager({super.key});

  @override
  ConsumerState<WeeklyScheduleManager> createState() => _WeeklyScheduleManagerState();
}

class _WeeklyScheduleManagerState extends ConsumerState<WeeklyScheduleManager> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();

  final List<Map<String, dynamic>> _days = const [
    {'name': 'السبت', 'value': 6},
    {'name': 'الأحد', 'value': 7},
    {'name': 'الاثنين', 'value': 1},
    {'name': 'الثلاثاء', 'value': 2},
    {'name': 'الأربعاء', 'value': 3},
    {'name': 'الخميس', 'value': 4},
    {'name': 'الجمعة', 'value': 5},
  ];

  @override
  void initState() {
    super.initState();
    final todayWeekday = DateTime.now().weekday;
    final initialIndex = _days.indexWhere((d) => d['value'] == todayWeekday);
    _tabController = TabController(
      length: _days.length,
      vsync: this,
      initialIndex: initialIndex != -1 ? initialIndex : 0,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _openAddTaskForDay(int weekday) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return TaskAdditionSheet(
          initialDate: DateTime.now(),
          allowedTaskType: 'weekly_routine',
          fixedWeekday: weekday,
        );
      },
    );
  }

  void _editTaskForDay(TaskItem task, int weekday) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return TaskAdditionSheet(
          initialDate: DateTime.now(),
          allowedTaskType: 'weekly_routine',
          fixedWeekday: weekday,
          taskToEdit: task,
        );
      },
    );
  }

  void _showCopyScheduleDialog(int targetWeekday) {
    int sourceWeekday = _days.firstWhere((d) => d['value'] != targetWeekday)['value'];
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: const Text('نسخ جدول من يوم آخر', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('اختر اليوم الذي تريد استيراد ونسخ مهامه إلى هذا اليوم:'),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    value: sourceWeekday,
                    dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    items: _days.where((d) => d['value'] != targetWeekday).map((d) => DropdownMenuItem<int>(
                      value: d['value'] as int,
                      child: Text(d['name'] as String),
                    )).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() {
                          sourceWeekday = val;
                        });
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogCtx).pop(),
                  child: const Text('إلغاء'),
                ),
                ElevatedButton.icon(
                  onPressed: () async {
                    final allTasks = ref.read(scheduleProvider).allTasks;
                    final sourceTasks = allTasks.where((t) => t.taskType == 'weekly_routine' && t.weekday == sourceWeekday).toList();
                    if (sourceTasks.isEmpty) {
                      SiyaqToast.show(
                        context,
                        'اليوم المختار لا يحتوي على أي مهام روتينية لنسخها',
                        type: SiyaqToastType.warning,
                      );
                      return;
                    }

                    final scheduleNotifier = ref.read(scheduleProvider.notifier);
                    final analysis = scheduleNotifier.analyzeCloneOperation(
                      incomingTasks: sourceTasks,
                      targetTaskType: 'weekly_routine',
                      targetWeekday: targetWeekday,
                    );

                    final nonDuplicate = analysis['nonDuplicateIncoming'] as List<TaskItem>;
                    final existing = analysis['existingTargetTasks'] as List<TaskItem>;
                    final conflicting = analysis['conflictingIncoming'] as List<TaskItem>;

                    if (nonDuplicate.isEmpty) {
                      Navigator.of(dialogCtx).pop();
                      SiyaqToast.show(
                        context,
                        'جميع مهام هذا اليوم متطابقة وموجودة بالفعل ولا توجد مهام جديدة لنسخها',
                        type: SiyaqToastType.info,
                      );
                      return;
                    }

                    Navigator.of(dialogCtx).pop();

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
                        targetTaskType: 'weekly_routine',
                        targetWeekday: targetWeekday,
                        mode: mode,
                      );

                      if (mode == 'replace') {
                        SiyaqToast.show(context, 'تم استبدال الجدول بالكامل واستيراد $count مهام! ✨', type: SiyaqToastType.success);
                      } else if (mode == 'skip_conflicts') {
                        if (count > 0) {
                          SiyaqToast.show(context, 'تم استيراد $count مهام غير متعارضة بنجاح! ✨', type: SiyaqToastType.success);
                        } else {
                          SiyaqToast.show(context, 'تم تخطي جميع المهام لتعارضها مع أوقات الجدول الحالي', type: SiyaqToastType.warning);
                        }
                      } else {
                        SiyaqToast.show(context, 'تم دمج واستيراد $count مهام بنجاح! ✨', type: SiyaqToastType.success);
                      }
                    } else {
                      final count = await scheduleNotifier.executeCloneTasks(
                        nonDuplicateIncoming: nonDuplicate,
                        existingTargetTasks: existing,
                        targetTaskType: 'weekly_routine',
                        targetWeekday: targetWeekday,
                        mode: 'add_all',
                      );
                      SiyaqToast.show(context, 'تم استيراد $count مهام بنجاح! 📌', type: SiyaqToastType.success);
                    }
                  },
                  icon: const Icon(Icons.copy_rounded, size: 18),
                  label: const Text('استيراد ونسخ'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: SiyaqColors.accentGold,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scheduleState = ref.watch(scheduleProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
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
          child: Column(
            children: [
              // شريط العنوان المتجاوب
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back_ios_new, size: 20, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                      tooltip: 'رجوع',
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerRight,
                        child: Text(
                          'الجدول الأسبوعي الثابت',
                          style: TextStyle(
                            fontSize: 18, 
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    MediaQuery.of(context).size.width < 450
                        ? IconButton(
                            icon: const Icon(Icons.file_download_outlined, size: 20),
                            tooltip: 'استيراد جدول يوم آخر',
                            style: IconButton.styleFrom(
                              backgroundColor: isDark ? SiyaqColors.accentGold.withOpacity(0.2) : const Color(0xFFFEF3C7),
                              foregroundColor: isDark ? SiyaqColors.accentGold : const Color(0xFF92400E),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.all(8),
                            ),
                            onPressed: () => _showCopyScheduleDialog(_days[_tabController.index]['value']),
                          )
                        : ElevatedButton.icon(
                            onPressed: () => _showCopyScheduleDialog(_days[_tabController.index]['value']),
                            icon: const Icon(Icons.file_download_outlined, size: 18),
                            label: const Text('استيراد يوم آخر'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isDark ? SiyaqColors.accentGold.withOpacity(0.2) : const Color(0xFFFEF3C7),
                              foregroundColor: isDark ? SiyaqColors.accentGold : const Color(0xFF92400E),
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            ),
                          ),
                  ],
                ),
              ),

              // شريط الأيام (Tabs)
              TabBar(
                controller: _tabController,
                isScrollable: true,
                indicatorColor: isDark ? SiyaqColors.accentGold : const Color(0xFFD97706),
                labelColor: isDark ? Colors.white : const Color(0xFF0F172A),
                unselectedLabelColor: isDark ? Colors.white38 : const Color(0xFF64748B),
                tabs: _days.map((day) => Tab(text: day['name'])).toList(),
              ),

              // محتوى التبويبات
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: _days.map((day) {
                    final int weekdayValue = day['value'];
                    // تصفية مهام الروتين الأسبوعي لهذا اليوم المحدد
                    final dayRoutineTasks = scheduleState.allTasks
                        .where((t) => t.taskType == 'weekly_routine' && t.weekday == weekdayValue)
                        .toList();

                    // ترتيب المهام حسب وقت البدء
                    dayRoutineTasks.sort((a, b) => a.startTime.compareTo(b.startTime));

                    return _buildDayRoutineList(weekdayValue, dayRoutineTasks, isDark);
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDayRoutineList(int weekday, List<TaskItem> tasks, bool isDark) {
    if (tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_view_week_rounded,
              size: 64,
              color: isDark ? Colors.white24 : const Color(0xFF94A3B8),
            ),
            const SizedBox(height: 16),
            Text(
              'لا توجد مهام روتينية مضافة لهذا اليوم.\nالأوقات غير المحددة تعتبر تلقائياً "وقت فراغ".',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? Colors.grey : const Color(0xFF64748B),
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _openAddTaskForDay(weekday),
              icon: const Icon(Icons.add_rounded),
              label: const Text('إضافة مهمة روتينية'),
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? SiyaqColors.accentGold : const Color(0xFFD97706),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'المهام الروتينية المجدولة (${tasks.length})',
              style: TextStyle(
                fontWeight: FontWeight.bold, 
                fontSize: 15,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            IconButton(
              icon: Icon(Icons.add_circle_outline_rounded, color: isDark ? SiyaqColors.accentGold : const Color(0xFFD97706)),
              onPressed: () => _openAddTaskForDay(weekday),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...tasks.map((task) => Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: SolariumGlassContainer(
            padding: const EdgeInsets.all(16),
            borderRadius: 20,
            child: Row(
              children: [
                // أيقونة الحالة (نوم أو مهمة عادية)
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: task.isSleepTime
                        ? (isDark ? Colors.indigoAccent.withOpacity(0.2) : const Color(0xFFEEF2FF))
                        : (isDark ? SiyaqColors.accentGold.withOpacity(0.2) : const Color(0xFFFEF3C7)),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    task.isSleepTime ? Icons.bedtime_rounded : Icons.task_alt_rounded,
                    color: task.isSleepTime ? (isDark ? Colors.indigoAccent : const Color(0xFF4338CA)) : (isDark ? SiyaqColors.accentGold : const Color(0xFFB45309)),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),

                // تفاصيل المهمة
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold, 
                          fontSize: 16,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${task.startTime.hour.toString().padLeft(2, '0')}:${task.startTime.minute.toString().padLeft(2, '0')} - ${task.endTime.hour.toString().padLeft(2, '0')}:${task.endTime.minute.toString().padLeft(2, '0')}',
                        style: TextStyle(
                          color: isDark ? Colors.white60 : const Color(0xFF64748B),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),

                // أزرار التحكم
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.edit_outlined, color: isDark ? SiyaqColors.accentGold : const Color(0xFFD97706), size: 20),
                      tooltip: 'تعديل المهمة الروتينية',
                      onPressed: () => _editTaskForDay(task, weekday),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                      tooltip: 'حذف المهمة',
                      onPressed: () {
                        ref.read(scheduleProvider.notifier).deleteTask(task.id);
                        SiyaqToast.show(
                          context,
                          'تمت إزالة المهمة الروتينية',
                          type: SiyaqToastType.info,
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        )),
      ],
    );
  }
}
