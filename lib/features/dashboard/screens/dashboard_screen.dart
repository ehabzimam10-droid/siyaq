import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/models/task_item.dart';
import '../../../core/models/prayer_times.dart';
import '../../../core/theme/colors.dart';
import '../../../core/widgets/solarium_glass_container.dart';
import '../../../core/widgets/siyaq_toast.dart';
import '../providers/schedule_provider.dart';
import '../widgets/task_addition_sheet.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  final ScrollController scrollController;

  const DashboardScreen({
    super.key,
    required this.scrollController,
  });

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  String _selectedFilter = 'all'; // 'all', 'remaining', 'completed', 'prayers', 'sleep'
  final GlobalKey _currentTaskKey = GlobalKey();
  DateTime? _lastScrolledDate;

  // إيجاد مؤشر المهمة أو الصلاة الأقرب للوقت الحالي
  int _findClosestTaskIndex(List<TaskItem> tasks) {
    if (tasks.isEmpty) return -1;
    final now = DateTime.now();

    // 1. مهمة جارية الآن
    int idx = tasks.indexWhere((t) =>
        (t.startTime.isBefore(now) || t.startTime.isAtSameMomentAs(now)) &&
        (t.endTime.isAfter(now) || t.endTime.isAtSameMomentAs(now)));
    if (idx != -1) return idx;

    // 2. أول مهمة قادمة بعد الآن
    idx = tasks.indexWhere((t) => t.startTime.isAfter(now));
    if (idx != -1) return idx;

    // 3. آخر مهمة إذا انتهت جميع المهام
    return tasks.length - 1;
  }

  // التمرير التلقائي السلس لأقرب مهمة للوقت الحالي عند فتح الصفحة
  void _checkAndScrollToCurrentTask(List<TaskItem> tasks, DateTime selectedDate, int targetIndex) {
    final now = DateTime.now();
    final isToday = selectedDate.year == now.year && selectedDate.month == now.month && selectedDate.day == now.day;
    if (!isToday || tasks.isEmpty || targetIndex == -1) return;

    if (_lastScrolledDate != null &&
        _lastScrolledDate!.year == selectedDate.year &&
        _lastScrolledDate!.month == selectedDate.month &&
        _lastScrolledDate!.day == selectedDate.day) {
      return;
    }

    _lastScrolledDate = selectedDate;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 350), () {
        if (!mounted) return;
        if (_currentTaskKey.currentContext != null) {
          Scrollable.ensureVisible(
            _currentTaskKey.currentContext!,
            duration: const Duration(milliseconds: 650),
            curve: Curves.easeInOutCubic,
            alignment: 0.12,
          );
        } else if (widget.scrollController.hasClients) {
          final approxOffset = (280.0 + (targetIndex * 85.0))
              .clamp(0.0, widget.scrollController.position.maxScrollExtent);
          widget.scrollController.animateTo(
            approxOffset,
            duration: const Duration(milliseconds: 650),
            curve: Curves.easeInOutCubic,
          );
        }
      });
    });
  }

  // فتح ورقة إضافة المهمة مع أوقات فراغ محددة مسبقاً
  void _openAddTaskAtSlot(BuildContext context, DateTime date, TimeOfDay start, TimeOfDay end) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TaskAdditionSheet(
        initialDate: date,
        initialStartTime: start,
        initialEndTime: end,
        allowedTaskType: 'single_date',
      ),
    );
  }

  // التبديل بين إنجاز المهمة وإلغائها بشكل فوري وموثوق
  void _toggleTaskCompletion(BuildContext context, TaskItem task) {
    final newStatus = !task.isCompleted;
    ref.read(scheduleProvider.notifier).updateTask(
      task.copyWith(isCompleted: newStatus),
    );
    if (newStatus) {
      SiyaqToast.show(
        context,
        'أحسنت! تم إنجاز المهمة بنجاح 🎯',
        type: SiyaqToastType.success,
      );
    } else {
      SiyaqToast.show(
        context,
        'تم إلغاء تحديد إنجاز المهمة 🔄',
        type: SiyaqToastType.info,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedDate = ref.watch(selectedDateProvider);
    final prayerTimesAsync = ref.watch(prayerTimesProvider(selectedDate));
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Container(
      color: Colors.transparent,
      child: SafeArea(
        bottom: false,
        child: prayerTimesAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: SiyaqColors.accentGold),
          ),
          error: (err, stack) => Center(
            child: Text('خطأ في جلب أوقات الصلاة: $err'),
          ),
          data: (prayers) {
            // جلب المهام وتكييفها ديناميكياً
            final allAdjustedTasks = ref
                .watch(scheduleProvider.notifier)
                .getAdjustedTasksForDate(selectedDate, prayers);

            // تصفية المهام وفق الفلتر النشط
            final adjustedTasks = allAdjustedTasks.where((task) {
              if (_selectedFilter == 'remaining') {
                return task.taskType != 'free_time' && task.taskType != 'prayer_block' && !task.isCompleted;
              } else if (_selectedFilter == 'completed') {
                return task.isCompleted;
              } else if (_selectedFilter == 'prayers') {
                return task.taskType == 'prayer_block';
              } else if (_selectedFilter == 'sleep') {
                return task.isSleepTime;
              }
              return true; // 'all'
            }).toList();

            // حساب إحصائيات الإنجاز اليومي للمهام الفعلية
            final actualTasks = allAdjustedTasks.where((t) => t.taskType != 'free_time' && t.taskType != 'prayer_block').toList();
            final completedCount = actualTasks.where((t) => t.isCompleted).length;
            final totalCount = actualTasks.length;
            final progressRatio = totalCount > 0 ? (completedCount / totalCount) : 0.0;

            // إيجاد المهمة الأقرب للوقت الحالي والتمرير إليها تلقائياً
            final closestIndex = _findClosestTaskIndex(adjustedTasks);
            _checkAndScrollToCurrentTask(adjustedTasks, selectedDate, closestIndex);

            // جلب الصلاة القادمة والوقت المتبقي لها
            final nextPrayer = prayers.getNextPrayer(DateTime.now());
            final difference = nextPrayer['difference'] as Duration;
            final hours = difference.inHours;
            final minutes = difference.inMinutes % 60;
            final countdownStr = hours > 0 
                ? 'متبقي $hours ساعة و $minutes دقيقة' 
                : 'متبقي $minutes دقيقة';

            return Align(
              alignment: Alignment.topCenter,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 1080.0),
                child: ListView(
                  controller: widget.scrollController,
                  physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                  padding: EdgeInsets.only(
                    top: 90.0,
                    left: isMobile ? 12.0 : 20.0,
                    right: isMobile ? 12.0 : 20.0,
                    bottom: 100.0,
                  ),
                  children: [
                    // 1. كارت الصلاة القادمة المتجاوب
                    SolariumGlassContainer(
                      margin: const EdgeInsets.only(bottom: 12.0),
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 14.0 : 18.0,
                        vertical: isMobile ? 12.0 : 16.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: SiyaqColors.accentGold.withOpacity(isDark ? 0.15 : 0.08),
                          blurRadius: 30,
                          spreadRadius: -5,
                          offset: const Offset(0, 10),
                        ),
                      ],
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(isMobile ? 8 : 10),
                            decoration: BoxDecoration(
                              color: (isDark ? SiyaqColors.accentGold : const Color(0xFFB45309)).withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.mosque_rounded,
                              color: isDark ? SiyaqColors.accentGold : const Color(0xFFB45309),
                              size: isMobile ? 20 : 22,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'الصلاة القادمة: ${nextPrayer['name']}',
                                  style: TextStyle(
                                    fontSize: isMobile ? 14 : 16,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? SiyaqColors.accentGold : const Color(0xFFB45309),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  countdownStr,
                                  style: TextStyle(
                                    fontSize: isMobile ? 11 : 13,
                                    color: isDark ? SiyaqColors.darkTextSecondary : const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            DateFormat('hh:mm a').format(nextPrayer['time']),
                            style: TextStyle(
                              fontSize: isMobile ? 16 : 19,
                              fontWeight: FontWeight.bold,
                              color: isDark ? SiyaqColors.accentGold : const Color(0xFFB45309),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // 2. كارت مؤشر الإنجاز والإنتاجية لليوم
                    if (totalCount > 0)
                      SolariumGlassContainer(
                        margin: const EdgeInsets.only(bottom: 12.0),
                        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.trending_up_rounded,
                                      size: 16,
                                      color: isDark ? SiyaqColors.accentTeal : const Color(0xFF0D9488),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'إنجاز مهام اليوم',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: (isDark ? SiyaqColors.accentTeal : const Color(0xFF0D9488)).withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '$completedCount من $totalCount (${(progressRatio * 100).toInt()}%)',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? SiyaqColors.accentTeal : const Color(0xFF0D9488),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: LinearProgressIndicator(
                                value: progressRatio,
                                minHeight: 6,
                                backgroundColor: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  progressRatio == 1.0
                                      ? (isDark ? SiyaqColors.accentTeal : const Color(0xFF0D9488))
                                      : (isDark ? SiyaqColors.accentGold : const Color(0xFFD97706)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // 3. شريط الفلاتر السريعة
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Row(
                        children: [
                          _buildFilterChip('all', 'الكل (${allAdjustedTasks.length})', isDark),
                          const SizedBox(width: 6),
                          _buildFilterChip('remaining', 'المتبقية (${actualTasks.where((t) => !t.isCompleted).length})', isDark),
                          const SizedBox(width: 6),
                          _buildFilterChip('completed', 'المكتملة ($completedCount)', isDark),
                          const SizedBox(width: 6),
                          _buildFilterChip('prayers', 'الصلوات', isDark),
                          const SizedBox(width: 6),
                          _buildFilterChip('sleep', 'النوم', isDark),
                        ],
                      ),
                    ),

                    // عنوان قسم الجدول والتاريخ
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'جدول اليوم في ميقاف',
                            style: TextStyle(
                              fontSize: isMobile ? 16 : 18,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                          Text(
                            DateFormat('EEEE, d MMMM', 'ar').format(selectedDate),
                            style: TextStyle(
                              fontSize: isMobile ? 12 : 13,
                              color: isDark ? SiyaqColors.darkTextSecondary : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),

                    if (adjustedTasks.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 40.0),
                          child: Column(
                            children: [
                              Icon(
                                Icons.calendar_today_outlined,
                                size: 50,
                                color: isDark ? SiyaqColors.darkTextSecondary : const Color(0xFF94A3B8),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'لا توجد مهام مطابقة لهذا الفلتر اليوم.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: isDark ? Colors.grey : const Color(0xFF64748B),
                                  fontSize: 13,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ...adjustedTasks.asMap().entries.map((entry) {
                        final index = entry.key;
                        final task = entry.value;
                        final startStr = DateFormat('hh:mm a').format(task.startTime);
                        final endStr = DateFormat('hh:mm a').format(task.endTime);

                        Widget slotWidget;
                        // 1. تصميم وقت الفراغ
                        if (task.taskType == 'free_time') {
                          slotWidget = _buildFreeTimeSlot(context, task, startStr, endStr, isDark, isMobile, selectedDate);
                        } else if (task.taskType == 'prayer_block') {
                          // 2. تصميم الصلاة
                          slotWidget = _buildPrayerTimeSlot(task, startStr, endStr, isDark, isMobile);
                        } else if (task.isSleepTime) {
                          // 3. تصميم وقت النوم
                          slotWidget = _buildSleepTimeSlot(context, task, startStr, endStr, isDark, isMobile);
                        } else {
                          // 4. تصميم المهمة العادية
                          slotWidget = _buildRegularTaskSlot(context, task, startStr, endStr, isDark, isMobile);
                        }

                        if (index == closestIndex) {
                          return KeyedSubtree(
                            key: _currentTaskKey,
                            child: slotWidget,
                          );
                        }
                        return slotWidget;
                      }).toList(),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFilterChip(String filterId, String label, bool isDark) {
    final isSelected = _selectedFilter == filterId;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedFilter = filterId;
        });
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? SiyaqColors.accentGold : const Color(0xFFB45309))
              : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : (isDark ? Colors.white10 : const Color(0xFFCBD5E1)),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected
                ? Colors.white
                : (isDark ? Colors.white70 : const Color(0xFF334155)),
          ),
        ),
      ),
    );
  }

  // ودجت وقت الفراغ
  Widget _buildFreeTimeSlot(BuildContext context, TaskItem task, String start, String end, bool isDark, bool isMobile, DateTime date) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildTimeColumn(start, end, isDark, isMobile),
          _buildTimelineIndicator(isDark ? Colors.grey.withOpacity(0.5) : const Color(0xFF94A3B8), isDashed: true),
          const SizedBox(width: 8),
          Expanded(
            child: GestureDetector(
              onTap: () => _openAddTaskAtSlot(
                context,
                date,
                TimeOfDay.fromDateTime(task.startTime),
                TimeOfDay.fromDateTime(task.endTime),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
                    style: BorderStyle.solid,
                    width: 1.2,
                  ),
                  color: isDark ? Colors.transparent : const Color(0x73FFFFFF),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.add_circle_outline_rounded, 
                      size: 16, 
                      color: isDark ? Colors.white38 : const Color(0xFF64748B),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'وقت فراغ - اضغط للإضافة',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white38 : const Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ودجت أوقات الصلوات المجدولة (تمييز بصري فائق بين الصلوات الحالية والمنتهية)
  Widget _buildPrayerTimeSlot(TaskItem task, String start, String end, bool isDark, bool isMobile) {
    final isPast = task.endTime.isBefore(DateTime.now());
    final emeraldColor = isDark ? const Color(0xFF2DD4BF) : const Color(0xFF0D9488);
    final mutedColor = isDark ? Colors.white38 : const Color(0xFF94A3B8);

    return Opacity(
      opacity: isPast ? 0.45 : 1.0,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildTimeColumn(start, end, isDark, isMobile, isPast: isPast),
            _buildTimelineIndicator(isPast ? mutedColor : emeraldColor),
            const SizedBox(width: 8),
            Expanded(
              child: SolariumGlassContainer(
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
                customBgColor: isPast 
                    ? (isDark ? const Color(0x08FFFFFF) : const Color(0x60E2E8F0))
                    : (isDark ? const Color(0x142DD4BF) : const Color(0x66CCFBF1)),
                customBorderColor: isPast
                    ? (isDark ? Colors.white12 : const Color(0xFFCBD5E1))
                    : (isDark ? const Color(0x502DD4BF) : const Color(0xFF0D9488)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: isPast
                                ? (isDark ? Colors.white10 : const Color(0xFFE2E8F0))
                                : (isDark ? const Color(0xFF2DD4BF) : const Color(0xFF0D9488)).withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.mosque_rounded, color: isPast ? mutedColor : emeraldColor, size: 16),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            task.title,
                            style: TextStyle(
                              fontSize: isMobile ? 14 : 15,
                              fontWeight: FontWeight.bold,
                              color: isPast ? mutedColor : emeraldColor,
                              decoration: isPast ? TextDecoration.lineThrough : null,
                              decorationColor: mutedColor,
                              decorationThickness: 2.0,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: isPast
                                ? (isDark ? Colors.white10 : const Color(0xFFF1F5F9))
                                : (isDark ? const Color(0xFF2DD4BF) : const Color(0xFF0D9488)).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            isPast ? 'انتهى وقتها' : 'صلاة مفروضة',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isPast ? mutedColor : emeraldColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isPast ? 'انقضى وقت أداء هذه الصلاة' : 'وقت الصلاة المفروضة وأداء السنن',
                      style: TextStyle(
                        fontSize: 10.5,
                        color: isPast ? mutedColor : (isDark ? Colors.white60 : const Color(0xFF64748B)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ودجت وقت النوم
  Widget _buildSleepTimeSlot(BuildContext context, TaskItem task, String start, String end, bool isDark, bool isMobile) {
    final isPast = task.endTime.isBefore(DateTime.now());
    final indigoColor = isDark ? Colors.indigoAccent : const Color(0xFF4338CA);
    final mutedColor = isDark ? Colors.white38 : const Color(0xFF94A3B8);

    return Opacity(
      opacity: isPast ? 0.45 : 1.0,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildTimeColumn(start, end, isDark, isMobile, isPast: isPast),
            _buildTimelineIndicator(isPast ? mutedColor : indigoColor),
            const SizedBox(width: 8),
            Expanded(
              child: SolariumGlassContainer(
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
                customBgColor: isPast
                    ? (isDark ? const Color(0x08FFFFFF) : const Color(0x60E2E8F0))
                    : (isDark ? Colors.indigoAccent.withOpacity(0.08) : const Color(0x66EEF2FF)),
                customBorderColor: isPast
                    ? (isDark ? Colors.white12 : const Color(0xFFCBD5E1))
                    : (isDark ? Colors.indigoAccent.withOpacity(0.2) : const Color(0x99C7D2FE)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: isPast
                                ? (isDark ? Colors.white10 : const Color(0xFFE2E8F0))
                                : (isDark ? Colors.indigoAccent.withOpacity(0.15) : const Color(0xFFE0E7FF)),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.bedtime_rounded, color: isPast ? mutedColor : indigoColor, size: 16),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            task.title,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isPast ? mutedColor : indigoColor,
                              decoration: isPast ? TextDecoration.lineThrough : null,
                              decorationColor: mutedColor,
                              decorationThickness: 2.0,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (task.isContinuation)
                          _buildBadge('تكملة', isDark ? Colors.tealAccent : const Color(0xFF0F766E), isDark ? Colors.tealAccent.withOpacity(0.15) : const Color(0xFFCCFBF1)),
                        if (isPast)
                          _buildBadge('مضى وقتها', mutedColor, isDark ? Colors.white10 : const Color(0xFFF1F5F9)),
                        Text(
                          'وضع الهدوء وكتم الإشعارات مفعل',
                          style: TextStyle(
                            fontSize: 10.5, 
                            color: isPast ? mutedColor : (isDark ? Colors.grey : const Color(0xFF64748B)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ودجت المهمة العادية (تمييز بصري فائق وإنجاز فوري)
  Widget _buildRegularTaskSlot(BuildContext context, TaskItem task, String start, String end, bool isDark, bool isMobile) {
    final isPast = task.endTime.isBefore(DateTime.now());
    final isDoneOrPast = task.isCompleted || isPast;
    final mutedColor = isDark ? Colors.white38 : const Color(0xFF94A3B8);

    final statusColor = task.isCompleted 
        ? (isDark ? SiyaqColors.accentTeal : const Color(0xFF0D9488))
        : (isPast
            ? mutedColor
            : (task.isFlexible ? (isDark ? SiyaqColors.accentGold : const Color(0xFFD97706)) : Colors.redAccent));

    return Opacity(
      opacity: isDoneOrPast ? 0.48 : 1.0,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildTimeColumn(start, end, isDark, isMobile, isPast: isPast),
            _buildTimelineIndicator(statusColor),
            const SizedBox(width: 8),
            Expanded(
              child: SolariumGlassContainer(
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
                customBgColor: isDoneOrPast
                    ? (isDark ? const Color(0x08FFFFFF) : const Color(0x60E2E8F0))
                    : null,
                customBorderColor: isDoneOrPast
                    ? (isDark ? Colors.white12 : const Color(0xFFCBD5E1))
                    : null,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: Icon(
                            task.isCompleted ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                            color: task.isCompleted 
                                ? (isDark ? SiyaqColors.accentTeal : const Color(0xFF0D9488))
                                : (isPast ? mutedColor : (isDark ? SiyaqColors.darkTextSecondary : const Color(0xFF94A3B8))),
                            size: 20,
                          ),
                          constraints: const BoxConstraints(),
                          padding: const EdgeInsets.all(4),
                          tooltip: task.isCompleted ? 'إلغاء الإنجاز' : 'إنهاء المهمة',
                          onPressed: () => _toggleTaskCompletion(context, task),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            task.title,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isDoneOrPast ? mutedColor : (isDark ? Colors.white : const Color(0xFF0F172A)),
                              decoration: isDoneOrPast ? TextDecoration.lineThrough : null,
                              decorationColor: mutedColor,
                              decorationThickness: 2.0,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (task.isCompleted)
                          _buildBadge('مكتملة ✓', isDark ? SiyaqColors.accentTeal : const Color(0xFF0F766E), isDark ? SiyaqColors.accentTeal.withOpacity(0.15) : const Color(0xFFCCFBF1))
                        else if (isPast)
                          _buildBadge('انتهت', mutedColor, isDark ? Colors.white10 : const Color(0xFFF1F5F9)),
                        if (task.isContinuation)
                          _buildBadge('تكملة', isDark ? Colors.tealAccent : const Color(0xFF0F766E), isDark ? Colors.tealAccent.withOpacity(0.15) : const Color(0xFFCCFBF1)),
                        _buildBadge(task.isFlexible ? 'مرن' : 'ثابت', isDoneOrPast ? mutedColor : (task.isFlexible ? (isDark ? SiyaqColors.accentGold : const Color(0xFF92400E)) : (isDark ? Colors.redAccent : const Color(0xFFB91C1C))), isDoneOrPast ? (isDark ? Colors.white10 : const Color(0xFFF1F5F9)) : (task.isFlexible ? (isDark ? SiyaqColors.accentGold.withOpacity(0.15) : const Color(0xFFFEF3C7)) : (isDark ? Colors.redAccent.withOpacity(0.15) : const Color(0xFFFEE2E2)))),
                        if (task.description.isNotEmpty)
                          Text(
                            task.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              color: isDoneOrPast ? mutedColor : (isDark ? SiyaqColors.darkTextSecondary : const Color(0xFF64748B)),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(String text, Color textColor, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }

  // مساعدات رسم الأوقات والخطوط الزمنية المتجاوبة
  Widget _buildTimeColumn(String start, String end, bool isDark, bool isMobile, {bool isPast = false}) {
    final muted = isDark ? Colors.white38 : const Color(0xFF94A3B8);
    return SizedBox(
      width: isMobile ? 52 : 68,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            start, 
            style: TextStyle(
              fontSize: isMobile ? 10.5 : 12, 
              fontWeight: FontWeight.bold,
              color: isPast ? muted : (isDark ? Colors.white : const Color(0xFF0F172A)),
            ),
          ),
          Text(
            end,
            style: TextStyle(
              fontSize: isMobile ? 9.5 : 10.5,
              color: isPast ? muted : (isDark ? SiyaqColors.darkTextSecondary : SiyaqColors.lightTextSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineIndicator(Color color, {bool isDashed = false}) {
    return Column(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: isDashed ? Border.all(color: color, width: 1.2) : null,
          ),
        ),
        Container(
          width: 1.5,
          height: 38,
          color: color.withOpacity(0.3),
        ),
      ],
    );
  }
}
