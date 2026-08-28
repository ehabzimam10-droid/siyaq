import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/colors.dart';
import '../../../core/widgets/solarium_glass_container.dart';
import '../../../core/widgets/siyaq_toast.dart';
import '../../../core/widgets/clone_conflict_dialog.dart';
import '../../dashboard/providers/schedule_provider.dart';
import '../../dashboard/widgets/task_addition_sheet.dart';
import '../../../core/models/task_item.dart';
import '../providers/settings_provider.dart';

class RamadanScheduleManager extends ConsumerStatefulWidget {
  const RamadanScheduleManager({super.key});

  @override
  ConsumerState<RamadanScheduleManager> createState() => _RamadanScheduleManagerState();
}

class _RamadanScheduleManagerState extends ConsumerState<RamadanScheduleManager>
    with SingleTickerProviderStateMixin {
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
          allowedTaskType: 'ramadan',
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
          allowedTaskType: 'ramadan',
          fixedWeekday: weekday,
          taskToEdit: task,
        );
      },
    );
  }

  Future<void> _importFromRegularRoutine(int targetWeekday) async {
    final allTasks = ref.read(scheduleProvider).allTasks;
    final routineTasks = allTasks.where((t) => t.taskType == 'weekly_routine' && t.weekday == targetWeekday).toList();

    if (routineTasks.isEmpty) {
      SiyaqToast.show(
        context,
        'لا توجد مهام روتينية عادية مسجلة في هذا اليوم لنسخها',
        type: SiyaqToastType.warning,
      );
      return;
    }

    final scheduleNotifier = ref.read(scheduleProvider.notifier);
    final analysis = scheduleNotifier.analyzeCloneOperation(
      incomingTasks: routineTasks,
      targetTaskType: 'ramadan',
      targetWeekday: targetWeekday,
    );

    final nonDuplicate = analysis['nonDuplicateIncoming'] as List<TaskItem>;
    final existing = analysis['existingTargetTasks'] as List<TaskItem>;
    final conflicting = analysis['conflictingIncoming'] as List<TaskItem>;

    if (nonDuplicate.isEmpty) {
      SiyaqToast.show(
        context,
        'جميع المهام الروتينية متطابقة وموجودة بالفعل في هذا اليوم الرمضاني',
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
        targetTaskType: 'ramadan',
        targetWeekday: targetWeekday,
        mode: mode,
      );

      if (mode == 'replace') {
        SiyaqToast.show(context, 'تم استبدال الجدول الرمضاني بالكامل واستيراد $count مهام! 🌙', type: SiyaqToastType.success);
      } else if (mode == 'skip_conflicts') {
        if (count > 0) {
          SiyaqToast.show(context, 'تم استيراد $count مهام غير متعارضة لرمضان بنجاح! 🌙', type: SiyaqToastType.success);
        } else {
          SiyaqToast.show(context, 'تم تخطي جميع المهام لتعارضها مع أوقات الجدول الحالي', type: SiyaqToastType.warning);
        }
      } else {
        SiyaqToast.show(context, 'تم دمج واستيراد $count مهام لجدول رمضان بنجاح! 🌙', type: SiyaqToastType.success);
      }
    } else {
      final count = await scheduleNotifier.executeCloneTasks(
        nonDuplicateIncoming: nonDuplicate,
        existingTargetTasks: existing,
        targetTaskType: 'ramadan',
        targetWeekday: targetWeekday,
        mode: 'add_all',
      );
      SiyaqToast.show(context, 'تم استيراد $count مهام من الروتين العادي لرمضان بنجاح! 🌙', type: SiyaqToastType.success);
    }
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
              backgroundColor: isDark ? const Color(0xFF131D33) : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: Row(
                children: const [
                  Icon(Icons.copy_all_rounded, color: SiyaqColors.accentGold),
                  SizedBox(width: 8),
                  Text('نسخ جدول يوم رمضاني', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('اختر اليوم الرمضاني المصدر لنسخ مهامه إلى هذا اليوم:'),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    value: sourceWeekday,
                    dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 14),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    items: _days
                        .where((d) => d['value'] != targetWeekday)
                        .map((d) => DropdownMenuItem<int>(
                              value: d['value'],
                              child: Text(d['name']),
                            ))
                        .toList(),
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
                    final sourceTasks = allTasks.where((t) => t.taskType == 'ramadan' && t.weekday == sourceWeekday).toList();
                    if (sourceTasks.isEmpty) {
                      SiyaqToast.show(
                        context,
                        'اليوم المختار لا يحتوي على أي مهام رمضانية لنسخها',
                        type: SiyaqToastType.warning,
                      );
                      return;
                    }

                    final scheduleNotifier = ref.read(scheduleProvider.notifier);
                    final analysis = scheduleNotifier.analyzeCloneOperation(
                      incomingTasks: sourceTasks,
                      targetTaskType: 'ramadan',
                      targetWeekday: targetWeekday,
                    );

                    final nonDuplicate = analysis['nonDuplicateIncoming'] as List<TaskItem>;
                    final existing = analysis['existingTargetTasks'] as List<TaskItem>;
                    final conflicting = analysis['conflictingIncoming'] as List<TaskItem>;

                    if (nonDuplicate.isEmpty) {
                      Navigator.of(dialogCtx).pop();
                      SiyaqToast.show(
                        context,
                        'جميع مهام هذا اليوم الرمضاني متطابقة وموجودة مسبقاً',
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
                        targetTaskType: 'ramadan',
                        targetWeekday: targetWeekday,
                        mode: mode,
                      );

                      if (mode == 'replace') {
                        SiyaqToast.show(context, 'تم استبدال الجدول الرمضاني بالكامل واستيراد $count مهام! 🌙', type: SiyaqToastType.success);
                      } else if (mode == 'skip_conflicts') {
                        if (count > 0) {
                          SiyaqToast.show(context, 'تم استيراد $count مهام رمضانية غير متعارضة بنجاح! 🌙', type: SiyaqToastType.success);
                        } else {
                          SiyaqToast.show(context, 'تم تخطي جميع المهام لتعارضها مع أوقات الجدول الحالي', type: SiyaqToastType.warning);
                        }
                      } else {
                        SiyaqToast.show(context, 'تم دمج واستيراد $count مهام لجدول رمضان بنجاح! 🌙', type: SiyaqToastType.success);
                      }
                    } else {
                      final count = await scheduleNotifier.executeCloneTasks(
                        nonDuplicateIncoming: nonDuplicate,
                        existingTargetTasks: existing,
                        targetTaskType: 'ramadan',
                        targetWeekday: targetWeekday,
                        mode: 'add_all',
                      );
                      SiyaqToast.show(context, 'تم نسخ $count مهام رمضانية بنجاح! 🌙', type: SiyaqToastType.success);
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
    final settings = ref.watch(settingsProvider);

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
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.arrow_back_ios_new, size: 20, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                        const SizedBox(width: 8),
                        Row(
                          children: [
                            Icon(Icons.nightlight_round, color: isDark ? SiyaqColors.accentGold : const Color(0xFFB45309), size: 24),
                            const SizedBox(width: 8),
                            Text(
                              'جدول شهر رمضان المبارك',
                              style: TextStyle(
                                fontSize: 18, 
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Auto-activation Banner
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B).withOpacity(0.6) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark ? SiyaqColors.accentGold.withOpacity(0.30) : const Color(0xFFE2E8F0),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isDark ? Colors.black.withOpacity(0.2) : const Color(0x0C0F172A),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    'تفعيل وضع جدول رمضان تلقائياً', 
                    style: TextStyle(
                      fontWeight: FontWeight.bold, 
                      fontSize: 14,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  subtitle: Text(
                    'استبدال الروتين العادي بجدول رمضان وإرسال تنبيهات العبادة', 
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white70 : const Color(0xFF64748B),
                    ),
                  ),
                  value: settings.isRamadanModeEnabled,
                  activeColor: isDark ? SiyaqColors.accentGold : const Color(0xFFD97706),
                  onChanged: (val) {
                    ref.read(settingsProvider.notifier).setRamadanMode(val);
                    SiyaqToast.show(
                      context,
                      val
                          ? '🌙 تم تفعيل وضع جدول رمضان التلقائي بنجاح!'
                          : 'تم إيقاف وضع رمضان والعودة للجدول الروتيني.',
                      type: SiyaqToastType.info,
                    );
                  },
                ),
              ),

              // TabBar for the 7 Days
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B).withOpacity(0.5) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  indicator: BoxDecoration(
                    color: isDark ? SiyaqColors.accentGold : const Color(0xFFD97706),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: SiyaqColors.accentGold.withOpacity(0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: isDark ? Colors.white60 : const Color(0xFF64748B),
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  tabs: _days.map((day) => Tab(text: day['name'])).toList(),
                ),
              ),

              // TabBarView for Tasks
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: _days.map((day) {
                    final weekday = day['value'] as int;
                    final dayName = day['name'] as String;
                    final dayTasks = scheduleState.allTasks
                        .where((t) => t.taskType == 'ramadan' && t.weekday == weekday)
                        .toList();

                    dayTasks.sort((a, b) => a.startTime.compareTo(b.startTime));

                    return ListView(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16.0),
                      children: [
                        // Card Header for the day
                        SolariumGlassContainer(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'جدول يوم $dayName في رمضان',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? SiyaqColors.accentGold : const Color(0xFFB45309),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${dayTasks.length} مهام رمضانية مخصصة',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark ? SiyaqColors.darkTextSecondary : const Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  // زر استيراد من الروتين العادي
                                  IconButton(
                                    tooltip: 'استيراد مهام هذا اليوم من الروتين العادي',
                                    icon: Icon(Icons.file_download_outlined, color: isDark ? Colors.cyanAccent : const Color(0xFF0D9488)),
                                    onPressed: () => _importFromRegularRoutine(weekday),
                                  ),
                                  // زر نسخ من يوم رمضاني آخر
                                  IconButton(
                                    tooltip: 'نسخ مهام من يوم رمضاني آخر',
                                    icon: Icon(Icons.copy_rounded, color: isDark ? SiyaqColors.accentGold : const Color(0xFFD97706)),
                                    onPressed: () => _showCopyScheduleDialog(weekday),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Tasks list
                        if (dayTasks.isEmpty)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 60.0),
                              child: Column(
                                children: [
                                  Icon(Icons.nights_stay_outlined, size: 48, color: isDark ? Colors.grey.withOpacity(0.5) : const Color(0xFF94A3B8)),
                                  const SizedBox(height: 12),
                                  Text(
                                    'لا توجد مهام مضافة ليوم $dayName في رمضان.\nاضغط على الزر أدناه لإضافة مهام العبادة والروتين.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: isDark ? SiyaqColors.darkTextSecondary : const Color(0xFF64748B),
                                      height: 1.5,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton.icon(
                                    onPressed: () => _importFromRegularRoutine(weekday),
                                    icon: const Icon(Icons.file_download_outlined, size: 18),
                                    label: const Text('استيراد من الروتين الأسبوعي العادي'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                                      foregroundColor: isDark ? Colors.cyanAccent : const Color(0xFF0D9488),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          ...dayTasks.map((task) {
                            final startStr = DateFormat('hh:mm a').format(task.startTime);
                            final endStr = DateFormat('hh:mm a').format(task.endTime);

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              color: Colors.transparent,
                              elevation: 0,
                              child: SolariumGlassContainer(
                                padding: const EdgeInsets.all(14.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          task.title,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold, 
                                            fontSize: 15,
                                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '$startStr - $endStr',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: isDark ? SiyaqColors.darkTextSecondary : const Color(0xFF64748B),
                                          ),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: task.isSleepTime
                                                ? (isDark ? Colors.indigoAccent.withOpacity(0.15) : const Color(0xFFEEF2FF))
                                                : (isDark ? SiyaqColors.accentGold.withOpacity(0.15) : const Color(0xFFFEF3C7)),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            task.isSleepTime ? 'نوم' : 'رمضان',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: task.isSleepTime ? (isDark ? Colors.indigoAccent : const Color(0xFF4338CA)) : (isDark ? SiyaqColors.accentGold : const Color(0xFF92400E)),
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        IconButton(
                                          icon: Icon(Icons.edit_outlined, color: isDark ? SiyaqColors.accentGold : const Color(0xFFD97706), size: 20),
                                          tooltip: 'تعديل المهمة الرمضانية',
                                          onPressed: () => _editTaskForDay(task, weekday),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                                          tooltip: 'حذف المهمة',
                                          onPressed: () {
                                            ref.read(scheduleProvider.notifier).deleteTask(task.id);
                                            SiyaqToast.show(
                                              context,
                                              'تم حذف المهمة من جدول رمضان',
                                              type: SiyaqToastType.info,
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                        const SizedBox(height: 24),

                        // Add Task Button
                        ElevatedButton.icon(
                          onPressed: () => _openAddTaskForDay(weekday),
                          icon: const Icon(Icons.add_rounded),
                          label: Text('إضافة مهمة ليوم $dayName في رمضان'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDark ? SiyaqColors.accentGold : const Color(0xFFD97706),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
