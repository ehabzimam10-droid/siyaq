import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/colors.dart';
import '../../../core/widgets/solarium_glass_container.dart';
import '../../../core/widgets/siyaq_toast.dart';
import '../../../core/models/prayer_times.dart';
import '../../../core/models/task_item.dart';
import '../../dashboard/providers/schedule_provider.dart';
import '../../dashboard/widgets/task_addition_sheet.dart';
import '../../settings/providers/settings_provider.dart';

class CalendarScreen extends ConsumerWidget {
  final ScrollController scrollController;

  const CalendarScreen({
    super.key,
    required this.scrollController,
  });

  // فتح نافذة اختيار التاريخ
  Future<void> _selectDate(BuildContext context, WidgetRef ref) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: ref.read(selectedDateProvider),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 3650)), // دعم لـ 10 سنوات قادمة
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
      ref.read(selectedDateProvider.notifier).setDate(picked);
    }
  }

  // حذف المهمة لتاريخ اليوم المحدد مع فحص خيار التأكيد
  Future<void> _handleDeleteTask(BuildContext context, WidgetRef ref, TaskItem task, DateTime selectedDate) async {
    final settings = ref.read(settingsProvider);
    
    if (settings.confirmDeleteTasks) {
      bool dontAskAgain = false;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => StatefulBuilder(
          builder: (context, setStateDialog) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            return AlertDialog(
              backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 22),
                  ),
                  const SizedBox(width: 10),
                  const Text('تأكيد حذف المهمة', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'هل أنت متأكد من رغبتك في حذف المهمة "${task.title}" من جدول هذا اليوم؟',
                    style: TextStyle(
                      fontSize: 13.5,
                      color: isDark ? Colors.white70 : const Color(0xFF334155),
                    ),
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: () {
                      setStateDialog(() {
                        dontAskAgain = !dontAskAgain;
                      });
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Row(
                      children: [
                        Checkbox(
                          value: dontAskAgain,
                          activeColor: const Color(0xFFEF4444),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                          onChanged: (val) {
                            setStateDialog(() {
                              dontAskAgain = val ?? false;
                            });
                          },
                        ),
                        const Text(
                          'عدم تذكيري مرة أخرى',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text('إلغاء', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEF4444),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: const Text('حذف', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        ),
      );

      if (confirmed != true) return;

      if (dontAskAgain) {
        ref.read(settingsProvider.notifier).setConfirmDeleteTasks(false);
      }
    }

    // حذف المهمة من تاريخ اليوم المحدد فقط
    await ref.read(scheduleProvider.notifier).deleteTaskForDate(task, selectedDate);
    if (context.mounted) {
      SiyaqToast.show(context, 'تم حذف المهمة من جدول هذا اليوم بنجاح 🗑️', type: SiyaqToastType.info);
    }
  }

  // التبديل بين إنجاز المهمة وإلغائها بشكل فوري وموثوق
  void _toggleTaskCompletion(BuildContext context, WidgetRef ref, TaskItem task) {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedDate = ref.watch(selectedDateProvider);
    final prayerTimesAsync = ref.watch(prayerTimesProvider(selectedDate));
    ref.watch(scheduleProvider); // مراقبة التغييرات لضمان إعادة البناء التلقائي عند إضافة/حذف المهام
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        color: Colors.transparent,
        child: SafeArea(
          bottom: false,
          child: Align(
            alignment: Alignment.topCenter,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 1080.0),
              child: RefreshIndicator(
                color: SiyaqColors.accentGold,
                backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                edgeOffset: 90.0,
                onRefresh: () async {
                  ref.invalidate(scheduleProvider);
                  ref.invalidate(prayerTimesProvider(selectedDate));
                  await Future.delayed(const Duration(milliseconds: 450));
                  if (context.mounted) {
                    SiyaqToast.show(context, 'تم تحديث جدول التقويم ومواقيت الصلاة 🔄', type: SiyaqToastType.info);
                  }
                },
                child: ListView(
                  controller: scrollController,
                  physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                  padding: EdgeInsets.only(
                    top: 95.0,
                    left: isMobile ? 12.0 : 16.0,
                    right: isMobile ? 12.0 : 16.0,
                    bottom: 100.0,
                  ),
                children: [
                  // محدد التاريخ الطافي المدمج مع أسهم التنقل السريع
                  Builder(
                    builder: (context) {
                      final now = DateTime.now();
                      final isToday = selectedDate.year == now.year &&
                          selectedDate.month == now.month &&
                          selectedDate.day == now.day;

                      String formattedDateStr;
                      if (screenWidth < 380) {
                        formattedDateStr = '${selectedDate.day} / ${selectedDate.month} / ${selectedDate.year % 100}';
                      } else if (screenWidth < 600) {
                        formattedDateStr = '${selectedDate.day} ${DateFormat('MMM', 'ar').format(selectedDate)} ${selectedDate.year % 100}';
                      } else {
                        formattedDateStr = DateFormat('d MMMM yyyy', 'ar').format(selectedDate);
                      }

                      return SolariumGlassContainer(
                        margin: const EdgeInsets.only(bottom: 12.0),
                        padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
                        child: Row(
                          children: [
                            // سهم اليوم السابق
                            IconButton(
                              icon: const Icon(Icons.arrow_back_ios_rounded, size: 16),
                              tooltip: 'اليوم السابق',
                              constraints: const BoxConstraints(),
                              style: IconButton.styleFrom(
                                backgroundColor: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                padding: const EdgeInsets.all(8),
                              ),
                              onPressed: () {
                                ref.read(selectedDateProvider.notifier).setDate(
                                  selectedDate.subtract(const Duration(days: 1)),
                                );
                              },
                            ),

                            // زر التاريخ المركزي
                            Expanded(
                              child: InkWell(
                                onTap: () => _selectDate(context, ref),
                                borderRadius: BorderRadius.circular(12),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 4.0),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            DateFormat('EEEE', 'ar').format(selectedDate),
                                            style: TextStyle(
                                              fontSize: isMobile ? 14 : 15,
                                              fontWeight: FontWeight.bold,
                                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                                            ),
                                          ),
                                          if (isToday) ...[
                                            const SizedBox(width: 6),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                              decoration: BoxDecoration(
                                                color: (isDark ? SiyaqColors.accentGold : const Color(0xFFD97706)).withOpacity(0.2),
                                                borderRadius: BorderRadius.circular(6),
                                                border: Border.all(
                                                  color: isDark ? SiyaqColors.accentGold.withOpacity(0.5) : const Color(0xFFD97706),
                                                  width: 0.8,
                                                ),
                                              ),
                                              child: Text(
                                                'اليوم',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  color: isDark ? SiyaqColors.accentGold : const Color(0xFFB45309),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        formattedDateStr,
                                        style: TextStyle(
                                          fontSize: isMobile ? 11 : 12,
                                          color: isDark ? SiyaqColors.darkTextSecondary : SiyaqColors.lightTextSecondary,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            // زر الانتقال والعودة لتاريخ اليوم (يظهر فقط إذا كان المعروض ليس اليوم)
                            if (!isToday) ...[
                              IconButton(
                                icon: const Icon(Icons.history_rounded, size: 17),
                                tooltip: 'العودة لليوم الحالي',
                                constraints: const BoxConstraints(),
                                style: IconButton.styleFrom(
                                  backgroundColor: (isDark ? SiyaqColors.accentGold : const Color(0xFFB45309)).withOpacity(0.15),
                                  foregroundColor: isDark ? SiyaqColors.accentGold : const Color(0xFFB45309),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  padding: const EdgeInsets.all(7),
                                ),
                                onPressed: () {
                                  ref.read(selectedDateProvider.notifier).setDate(DateTime.now());
                                },
                              ),
                              const SizedBox(width: 4),
                            ],

                            // سهم اليوم التالي
                            IconButton(
                              icon: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                              tooltip: 'اليوم التالي',
                              constraints: const BoxConstraints(),
                              style: IconButton.styleFrom(
                                backgroundColor: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                padding: const EdgeInsets.all(8),
                              ),
                              onPressed: () {
                                ref.read(selectedDateProvider.notifier).setDate(
                                  selectedDate.add(const Duration(days: 1)),
                                );
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  // أوقات صلاة اليوم المحدد
                  Row(
                    children: [
                      Icon(
                        Icons.access_time_filled_rounded, 
                        color: isDark ? SiyaqColors.accentGold : const Color(0xFFB45309), 
                        size: 15,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'أوقات الصلاة المعتمدة لليوم',
                        style: TextStyle(
                          fontSize: 13.5, 
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  prayerTimesAsync.when(
                    loading: () => const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 16.0),
                        child: CircularProgressIndicator(color: SiyaqColors.accentGold),
                      ),
                    ),
                    error: (err, stack) => Center(
                      child: Text('حدث خطأ في تحميل الصلوات: $err'),
                    ),
                    data: (prayers) {
                      final list = prayers.toList();
                      
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // جدول أوقات الصلاة الرشيق والمتناسق
                          _buildPrayerTimesGrid(context, list, isDark, isMobile),
                          const SizedBox(height: 12),

                          // المهام المجدولة لليوم المحدد
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.format_list_bulleted_rounded, 
                                    color: isDark ? SiyaqColors.accentGold : const Color(0xFFB45309), 
                                    size: 15,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'المهام المقررة في هذا التاريخ',
                                    style: TextStyle(
                                      fontSize: 14, 
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isDark ? SiyaqColors.accentGold.withOpacity(0.15) : const Color(0xFFFEF3C7),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${ref.read(scheduleProvider.notifier).getAdjustedTasksForDate(selectedDate, prayers).where((t) => t.taskType != "free_time" && t.taskType != "prayer_block").length} مهام',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? SiyaqColors.accentGold : const Color(0xFFB45309),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // قائمة المهام
                          _buildDayScheduleView(context, ref, selectedDate, prayers, isMobile),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
        ),
      ),
    );
  }

  // شبكة عرض مواقيت الصلاة بتصميم متناسق ومدمج
  Widget _buildPrayerTimesGrid(BuildContext context, List<Map<String, dynamic>> prayers, bool isDark, bool isMobile) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
          children: prayers.map((prayer) {
            final name = prayer['name'] as String;
            final time = prayer['time'] as DateTime;
            final timeStr = DateFormat('hh:mm a').format(time);
            final itemWidth = (constraints.maxWidth - (isMobile ? 16.0 : 40.0)) / (isMobile ? 3 : 6);

            return SizedBox(
              width: itemWidth,
              child: SolariumGlassContainer(
                padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                borderRadius: 16.0,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: isMobile ? 11.5 : 13,
                        fontWeight: FontWeight.bold,
                        color: isDark ? SiyaqColors.accentGold : const Color(0xFFB45309),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      timeStr,
                      style: TextStyle(
                        fontSize: isMobile ? 10 : 11,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  void _openEditTask(BuildContext context, TaskItem task, DateTime date) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return TaskAdditionSheet(
          initialDate: date,
          taskToEdit: task,
          isFromCalendar: true,
        );
      },
    );
  }

  // عرض المهام الخاصة باليوم المختار
  Widget _buildDayScheduleView(BuildContext context, WidgetRef ref, DateTime date, PrayerTimes prayers, bool isMobile) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dayTasks = ref.read(scheduleProvider.notifier).getAdjustedTasksForDate(date, prayers);

    // تصفية أوقات الفراغ والصلوات لعرض مهام المستخدم الفعلية فقط في صفحة التقويم
    final userTasks = dayTasks.where((t) => t.taskType != 'free_time' && t.taskType != 'prayer_block').toList();

    if (userTasks.isEmpty) {
      return SolariumGlassContainer(
        margin: const EdgeInsets.only(top: 4.0),
        padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey.withOpacity(0.12) : const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.event_available_rounded, color: isDark ? Colors.grey : const Color(0xFF64748B), size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'لا توجد مهام مقررة لهذا اليوم. اضغط على زر الإضافة (+) لإدراج مهمة.',
                style: TextStyle(
                  fontSize: 12.5,
                  color: isDark ? SiyaqColors.darkTextSecondary : const Color(0xFF64748B),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final now = DateTime.now();

    return Column(
      children: userTasks.map((task) {
        final startStr = DateFormat('hh:mm a').format(task.startTime);
        final endStr = DateFormat('hh:mm a').format(task.endTime);
        final isPast = task.endTime.isBefore(now);
        final isFutureOrOngoing = !isPast;

        final taskBadgeBg = task.isSleepTime
            ? (isDark ? Colors.indigoAccent.withOpacity(0.15) : const Color(0xFFEEF2FF))
            : (task.isFlexible 
                ? (isDark ? SiyaqColors.accentGold.withOpacity(0.15) : const Color(0xFFFEF3C7))
                : (isDark ? Colors.redAccent.withOpacity(0.15) : const Color(0xFFFEE2E2)));

        final taskBadgeText = task.isSleepTime
            ? (isDark ? Colors.indigoAccent : const Color(0xFF4338CA))
            : (task.isFlexible 
                ? (isDark ? SiyaqColors.accentGold : const Color(0xFF92400E))
                : (isDark ? Colors.redAccent : const Color(0xFFB91C1C)));

        final isDoneOrPast = task.isCompleted || isPast;
        final mutedColor = isDark ? Colors.white38 : const Color(0xFF94A3B8);

        final indicatorColor = isDoneOrPast
            ? mutedColor
            : (task.isSleepTime
                ? Colors.indigoAccent
                : (task.isFlexible 
                    ? (isDark ? SiyaqColors.accentGold : const Color(0xFFD97706)) 
                    : Colors.redAccent));

        return Opacity(
          opacity: isDoneOrPast ? 0.48 : 1.0,
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
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
                  // السطر الأول: خط التمييز اللوني + زر الإنجاز + العنوان (العريض بكامل المساحة) + أزرار الإجراءات (تعديل وحذف)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 3.5,
                        height: 22,
                        decoration: BoxDecoration(
                          color: indicatorColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // زر إنجاز المهمة (فوري وسلس)
                      IconButton(
                        icon: Icon(
                          task.isCompleted ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                          color: task.isCompleted 
                              ? (isDark ? SiyaqColors.accentTeal : const Color(0xFF0D9488))
                              : (isPast ? mutedColor : (isDark ? SiyaqColors.darkTextSecondary : const Color(0xFF94A3B8))),
                          size: 18,
                        ),
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.all(3),
                        tooltip: task.isCompleted ? 'إلغاء الإنجاز' : 'إنهاء المهمة',
                        onPressed: () => _toggleTaskCompletion(context, ref, task),
                      ),
                      const SizedBox(width: 6),
                      // عنوان المهمة المتجاوب
                      Expanded(
                        child: Text(
                          task.title,
                          style: TextStyle(
                            fontWeight: FontWeight.bold, 
                            fontSize: isMobile ? 13.5 : 14.5,
                            color: isDoneOrPast ? mutedColor : (isDark ? Colors.white : const Color(0xFF0F172A)),
                            decoration: isDoneOrPast ? TextDecoration.lineThrough : null,
                            decorationColor: mutedColor,
                            decorationThickness: 2.0,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // زر التعديل (يتاح فقط إذا لم ينته وقت المهمة ولم تكتمل)
                      if (!isDoneOrPast)
                        IconButton(
                          icon: Icon(Icons.edit_outlined, color: isDark ? SiyaqColors.accentGold : const Color(0xFFD97706), size: 17),
                          tooltip: 'تعديل المهمة',
                          constraints: const BoxConstraints(),
                          padding: const EdgeInsets.all(4),
                          onPressed: () => _openEditTask(context, task, date),
                        ),
                      // زر الحذف (يتاح فقط إذا لم ينته وقت المهمة ولم تكتمل)
                      if (!isDoneOrPast)
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 17),
                          tooltip: 'حذف المهمة من هذا اليوم',
                          constraints: const BoxConstraints(),
                          padding: const EdgeInsets.all(4),
                          onPressed: () => _handleDeleteTask(context, ref, task, date),
                        ),
                    ],
                  ),

                  // السطر الثاني: التوقيت والوسوم تترتب بمرونة في الأسفل
                  const SizedBox(height: 5),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      // وقت المهمة
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '$startStr - $endStr',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: isDoneOrPast ? mutedColor : (isDark ? Colors.white70 : const Color(0xFF475569)),
                          ),
                        ),
                      ),
                      // وسم نوع المهمة (نوم / مرن / ثابت)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isDoneOrPast ? (isDark ? Colors.white10 : const Color(0xFFF1F5F9)) : taskBadgeBg,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          task.isSleepTime 
                              ? 'نوم'
                              : (task.isFlexible ? 'مرن' : 'ثابت'),
                          style: TextStyle(
                            fontSize: 10,
                            color: isDoneOrPast ? mutedColor : taskBadgeText,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (task.isCompleted)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isDark ? SiyaqColors.accentTeal.withOpacity(0.15) : const Color(0xFFCCFBF1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'مكتملة ✓',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isDark ? SiyaqColors.accentTeal : const Color(0xFF0F766E),
                            ),
                          ),
                        )
                      else if (isPast)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'انتهت',
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold,
                              color: mutedColor,
                            ),
                          ),
                        ),
                      if (task.isContinuation)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.tealAccent.withOpacity(0.15) : const Color(0xFFCCFBF1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'تكملة',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.tealAccent : const Color(0xFF0F766E),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
