import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../core/models/task_item.dart';
import '../../../core/theme/colors.dart';
import '../../../core/widgets/solarium_glass_container.dart';
import '../../../core/widgets/siyaq_time_picker.dart';
import '../../../core/widgets/siyaq_toast.dart';
import '../providers/schedule_provider.dart';

class TaskAdditionSheet extends ConsumerStatefulWidget {
  final DateTime initialDate;
  final TimeOfDay? initialStartTime;
  final TimeOfDay? initialEndTime;
  final String allowedTaskType; // 'single_date', 'weekly_routine', 'ramadan', 'special_day'
  final int? fixedWeekday; // 1 (Mon) - 7 (Sun)
  final TaskItem? taskToEdit;
  final bool isFromCalendar;

  const TaskAdditionSheet({
    super.key,
    required this.initialDate,
    this.initialStartTime,
    this.initialEndTime,
    this.allowedTaskType = 'single_date',
    this.fixedWeekday,
    this.taskToEdit,
    this.isFromCalendar = false,
  });

  @override
  ConsumerState<TaskAdditionSheet> createState() => _TaskAdditionSheetState();
}

class _TaskAdditionSheetState extends ConsumerState<TaskAdditionSheet> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  
  late String _taskType;
  late int _weekday; // 1 (Mon) - 7 (Sun)
  bool _isSleepTime = false;
  String _prayerReaction = 'shift'; // 'shift', 'shift_before', 'pause', 'cancel', 'none'
  int _priority = 2; // 1 = low, 2 = medium, 3 = high
  bool _applyToWeeklyRoutine = false;

  @override
  void initState() {
    super.initState();
    if (widget.taskToEdit != null) {
      final t = widget.taskToEdit!;
      // تنظيف العنوان من شارات التكملة
      _titleController.text = t.title.replaceAll(RegExp(r'\s*\((تكملة من أمس|تكملة من روتين أمس|جزء \d+)\)'), '');
      _descController.text = t.description;
      _startTime = TimeOfDay(hour: t.startTime.hour, minute: t.startTime.minute);
      _endTime = TimeOfDay(hour: t.endTime.hour, minute: t.endTime.minute);
      _taskType = t.taskType;
      _weekday = t.weekday ?? widget.initialDate.weekday;
      _isSleepTime = t.isSleepTime;
      _prayerReaction = t.prayerReaction;
      _priority = t.priority;
      _applyToWeeklyRoutine = widget.allowedTaskType == 'weekly_routine';
    } else {
      _startTime = widget.initialStartTime ?? const TimeOfDay(hour: 9, minute: 0);
      _endTime = widget.initialEndTime ?? const TimeOfDay(hour: 10, minute: 0);
      _taskType = widget.allowedTaskType;
      _weekday = widget.fixedWeekday ?? widget.initialDate.weekday;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  // تحويل الوقت إلى صيغة 12 ساعة بالعربية (ص / م)
  String _format12HourArabic(TimeOfDay time) {
    final hour = time.hour;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = hour < 12 ? 'ص' : 'م';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '$displayHour:$minute $period';
  }

  // فتح نافذة اختيار الوقت بنظام 12 ساعة مع خيارات صباحاً ومساءً
  Future<void> _selectTime(BuildContext context, bool isStart) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final initial = isStart ? _startTime : _endTime;

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initial,
      helpText: isStart ? 'اختر وقت البدء' : 'اختر وقت الانتهاء',
      confirmText: 'موافق',
      cancelText: 'إلغاء',
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
                  timePickerTheme: TimePickerThemeData(
                    backgroundColor: const Color(0xFF0F172A),
                    hourMinuteColor: const Color(0xFF1E293B),
                    hourMinuteTextColor: Colors.white,
                    dialBackgroundColor: const Color(0xFF1E293B),
                    dialHandColor: SiyaqColors.accentGold,
                    dialTextColor: Colors.white,
                    dayPeriodColor: const Color(0xFF1E293B),
                    dayPeriodTextColor: Colors.white,
                    helpTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  ),
                )
              : ThemeData.light().copyWith(
                  colorScheme: const ColorScheme.light(
                    primary: SiyaqColors.accentGoldDark,
                    onPrimary: Colors.white,
                    surface: Colors.white,
                    onSurface: Color(0xFF0F172A),
                  ),
                  timePickerTheme: TimePickerThemeData(
                    backgroundColor: Colors.white,
                    hourMinuteColor: const Color(0xFFF1F5F9),
                    hourMinuteTextColor: const Color(0xFF0F172A),
                    dialBackgroundColor: const Color(0xFFF8FAFC),
                    dialHandColor: SiyaqColors.accentGold,
                    dialTextColor: const Color(0xFF0F172A),
                    dayPeriodColor: const Color(0xFFF1F5F9),
                    dayPeriodTextColor: const Color(0xFF0F172A),
                    helpTextStyle: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  ),
                ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  void _extendDurationBy(int minutesToAdd) {
    setState(() {
      final currentEndMinutes = _endTime.hour * 60 + _endTime.minute;
      final newEndMinutes = (currentEndMinutes + minutesToAdd) % (24 * 60);
      _endTime = TimeOfDay(hour: newEndMinutes ~/ 60, minute: newEndMinutes % 60);
    });
  }

  String _getCalculatedDurationString() {
    final startMin = _startTime.hour * 60 + _startTime.minute;
    var endMin = _endTime.hour * 60 + _endTime.minute;
    if (endMin <= startMin) {
      endMin += 24 * 60; // دعم عبور منتصف الليل بسلاسة
    }
    final diff = endMin - startMin;
    final hours = diff ~/ 60;
    final mins = diff % 60;

    if (hours > 0 && mins > 0) {
      return '$hours س و $mins د';
    } else if (hours > 0) {
      return '$hours س';
    } else {
      return '$mins د';
    }
  }

  Future<void> _saveTask({bool saveForTodayOnly = false}) async {
    if (_titleController.text.isEmpty) {
      SiyaqToast.show(
        context,
        'الرجاء إدخال عنوان المهمة',
        type: SiyaqToastType.warning,
      );
      return;
    }

    if (_startTime.hour == _endTime.hour && _startTime.minute == _endTime.minute) {
      SiyaqToast.show(
        context,
        'وقت البدء والانتهاء متطابقان (المدة 0 دقيقة)، يرجى تحديد فترة زمنية للمهمة',
        type: SiyaqToastType.warning,
      );
      return;
    }

    final startDateTime = DateTime(
      widget.initialDate.year,
      widget.initialDate.month,
      widget.initialDate.day,
      _startTime.hour,
      _startTime.minute,
    );

    var endDateTime = DateTime(
      widget.initialDate.year,
      widget.initialDate.month,
      widget.initialDate.day,
      _endTime.hour,
      _endTime.minute,
    );

    // دعم المهام وأوقات النوم التي تعبر منتصف الليل (مثل من 10:00 مساءً حتى 3:30 صباحاً)
    if (endDateTime.isBefore(startDateTime)) {
      endDateTime = endDateTime.add(const Duration(days: 1));
    }

    final scheduleNotifier = ref.read(scheduleProvider.notifier);

    // حالة 1: تعديل مهمة موجودة مسبقاً (مع خيار تطبيق التعديل على الروتين أو اليوم فقط)
    if (widget.taskToEdit != null) {
      final updatedTask = widget.taskToEdit!.copyWith(
        title: _titleController.text,
        description: _descController.text,
        startTime: startDateTime,
        endTime: endDateTime,
        isSleepTime: _isSleepTime,
        prayerReaction: _prayerReaction,
        isFlexible: !_isSleepTime,
        priority: _priority,
      );

      await scheduleNotifier.updateTaskForDate(
        originalTask: widget.taskToEdit!,
        updatedTask: updatedTask,
        date: widget.initialDate,
        applyToWeeklyRoutine: _applyToWeeklyRoutine,
      );

      if (mounted) {
        Navigator.of(context).pop();
        SiyaqToast.show(
          context,
          _applyToWeeklyRoutine
              ? 'تم حفظ التعديل وتطبيقه على الروتين الأسبوعي بنجاح! 🔄'
              : 'تم حفظ التعديل لهذا اليوم المحدد فقط بنجاح! 📅',
          type: SiyaqToastType.success,
        );
      }
      return;
    }

    // حالة 3: إضافة مهمة جديدة لأول مرة
    final newTask = TaskItem(
      id: const Uuid().v4(),
      title: _titleController.text,
      description: _descController.text,
      startTime: startDateTime,
      endTime: endDateTime,
      taskType: _taskType,
      weekday: _taskType == 'weekly_routine' || _taskType == 'ramadan' ? _weekday : null,
      isSleepTime: _isSleepTime,
      prayerReaction: _prayerReaction,
      isFlexible: !_isSleepTime,
      priority: _priority,
    );

    if (_taskType == 'single_date' || _taskType == 'special_day') {
      final conflicts = scheduleNotifier.checkOverlappingTasks(newTask);
      if (conflicts.isNotEmpty) {
        _showConflictDialog(newTask, conflicts);
        return;
      }
    }

    scheduleNotifier.addTask(newTask);
    Navigator.of(context).pop();
    
    SiyaqToast.show(
      context,
      'تمت إضافة المهمة بنجاح في سياق ✨',
      type: SiyaqToastType.success,
    );
  }

  void _showConflictDialog(TaskItem newTask, List<TaskItem> conflicts) {
    showDialog(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Dialog(
          backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent, size: 28),
                    const SizedBox(width: 8),
                    Text(
                      'تعارض في المواعيد!',
                      style: TextStyle(
                        fontSize: 18, 
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'المهمة الجديدة تتقاطع مع ${conflicts.length} مهمة في جدولك:\n'
                  '${conflicts.map((c) => "• ${c.title}").join("\n")}\n\n'
                  'ماذا تريد أن تفعل؟',
                  style: TextStyle(
                    color: isDark ? Colors.white70 : const Color(0xFF475569),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    ref.read(scheduleProvider.notifier).resolveConflictingTasks(newTask, conflicts, 'trim');
                    Navigator.of(context).pop();
                    Navigator.of(this.context).pop();
                  },
                  icon: const Icon(Icons.cut_rounded, size: 18),
                  label: const Text('قص واقتطاع أوقات المهام المتعارضة'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: SiyaqColors.accentGold,
                    foregroundColor: Colors.black87,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: () {
                    ref.read(scheduleProvider.notifier).resolveConflictingTasks(newTask, conflicts, 'delete');
                    Navigator.of(context).pop();
                    Navigator.of(this.context).pop();
                  },
                  icon: const Icon(Icons.delete_outline_rounded, size: 18),
                  label: const Text('حذف واستبدال المهام المتعارضة تماماً'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'إلغاء الإضافة',
                    style: TextStyle(color: isDark ? Colors.white60 : const Color(0xFF64748B)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFA0E1524) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32.0)),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.18) : const Color(0xFFE2E8F0),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withOpacity(0.5) : const Color(0x200F172A),
            blurRadius: 36,
            spreadRadius: 4,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24.0),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'إضافة مهمة في سياق',
                  style: TextStyle(
                    fontSize: 18, 
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close_rounded, color: isDark ? Colors.white70 : const Color(0xFF475569)),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),

            _buildTaskTypeContextBadge(isDark),
            const SizedBox(height: 16),

            if ((_taskType == 'weekly_routine' || _taskType == 'ramadan') && widget.fixedWeekday == null) ...[
              Text(
                'يوم التكرار', 
                style: TextStyle(
                  fontWeight: FontWeight.bold, 
                  fontSize: 13,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<int>(
                value: _weekday,
                isExpanded: true,
                dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A), fontSize: 14),
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                items: const [
                  DropdownMenuItem(value: 1, child: Text('الاثنين')),
                  DropdownMenuItem(value: 2, child: Text('الثلاثاء')),
                  DropdownMenuItem(value: 3, child: Text('الأربعاء')),
                  DropdownMenuItem(value: 4, child: Text('الخميس')),
                  DropdownMenuItem(value: 5, child: Text('الجمعة')),
                  DropdownMenuItem(value: 6, child: Text('السبت')),
                  DropdownMenuItem(value: 7, child: Text('الأحد')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _weekday = val;
                    });
                  }
                },
              ),
              const SizedBox(height: 12),
            ],

            TextField(
              controller: _titleController,
              style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A)),
              decoration: const InputDecoration(
                labelText: 'عنوان المهمة',
              ),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _descController,
              style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A)),
              decoration: const InputDecoration(
                labelText: 'تفاصيل إضافية (اختياري)',
              ),
            ),
            const SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'توقيت المهمة والمدة', 
                  style: TextStyle(
                    fontWeight: FontWeight.bold, 
                    fontSize: 13,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark ? SiyaqColors.accentGold.withOpacity(0.18) : const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? SiyaqColors.accentGold.withOpacity(0.35) : const Color(0xFFFCD34D),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.timer_outlined, 
                        size: 14, 
                        color: isDark ? SiyaqColors.accentGold : const Color(0xFFB45309),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'المدة: ${_getCalculatedDurationString()}',
                        style: TextStyle(
                          fontSize: 12, 
                          fontWeight: FontWeight.bold, 
                          color: isDark ? SiyaqColors.accentGold : const Color(0xFF92400E),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _selectTime(context, true),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark ? SiyaqColors.accentGold.withOpacity(0.45) : const Color(0xFFE2E8F0), 
                          width: 1.3,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'وقت البدء', 
                            style: TextStyle(
                              fontSize: 11, 
                              color: isDark ? Colors.white60 : const Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _format12HourArabic(_startTime),
                                style: TextStyle(
                                  fontSize: 15, 
                                  fontWeight: FontWeight.bold, 
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                              ),
                              const Icon(Icons.access_time_filled_rounded, size: 18, color: SiyaqColors.accentGold),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: () => _selectTime(context, false),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark ? const Color(0xFF0EA5E9).withOpacity(0.45) : const Color(0xFFE2E8F0), 
                          width: 1.3,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'وقت الانتهاء', 
                            style: TextStyle(
                              fontSize: 11, 
                              color: isDark ? Colors.white60 : const Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _format12HourArabic(_endTime),
                                style: TextStyle(
                                  fontSize: 15, 
                                  fontWeight: FontWeight.bold, 
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                              ),
                              const Icon(Icons.access_time_filled_rounded, size: 18, color: Color(0xFF0EA5E9)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _buildQuickDurationChip('+15 د', 15, isDark),
                _buildQuickDurationChip('+30 د', 30, isDark),
                _buildQuickDurationChip('+45 د', 45, isDark),
                _buildQuickDurationChip('+1 ساعة', 60, isDark),
                _buildQuickDurationChip('+1.5 س', 90, isDark),
                _buildQuickDurationChip('+2 ساعة', 120, isDark),
              ],
            ),
            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B).withOpacity(0.5) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
              ),
              child: SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  'هذه المهمة تمثل وقت النوم', 
                  style: TextStyle(
                    fontSize: 14, 
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                subtitle: Text(
                  'سيقوم التطبيق بكتم الإشعارات وتلوينها بلون نوم مخصص', 
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white60 : const Color(0xFF64748B),
                  ),
                ),
                value: _isSleepTime,
                activeColor: Colors.indigoAccent,
                onChanged: (val) {
                  setState(() {
                    _isSleepTime = val;
                  });
                },
              ),
            ),

            if (_isSleepTime) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.redAccent.withOpacity(0.4)),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 24),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '⚠️ تنبيه حرج: يرجى التأكد من عدم النوم عن أداء الصلاة المكتوبة في وقتها!',
                        style: TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),
            Text(
              'التفاعل مع أوقات الصلاة المتقاطعة', 
              style: TextStyle(
                fontWeight: FontWeight.bold, 
                fontSize: 13,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            Column(
              children: [
                _buildPrayerReactionCard('shift', '⏩ إزاحة المهمة بعد الصلاة', 'تبدأ المهمة فور انتهاء وقت الصلاة المحدد', isDark),
                const SizedBox(height: 6),
                _buildPrayerReactionCard('shift_before', '⏪ إزاحة المهمة قبل الصلاة', 'يتم تقديم المهمة لتنتهي قبل دخول وقت الصلاة', isDark),
                const SizedBox(height: 6),
                _buildPrayerReactionCard('pause', '⏸️ تقطيع المهمة (إيقاف مؤقت)', 'أداء جزء قبل الصلاة وتكملة الباقي بعدها', isDark),
                const SizedBox(height: 6),
                _buildPrayerReactionCard('cancel', '✂️ إلغاء الجزء المتعارض فقط', 'تقليص المهمة بما يغطي وقت الصلاة فقط', isDark),
                const SizedBox(height: 6),
                _buildPrayerReactionCard('none', '⏺️ إبقاء كما هي (بدون تغيير)', 'المحافظة على موعد المهمة الأصلي بدون تعديل', isDark),
              ],
            ),
            const SizedBox(height: 24),

            if (widget.taskToEdit != null) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: _applyToWeeklyRoutine 
                      ? (isDark ? SiyaqColors.accentGold.withOpacity(0.15) : const Color(0xFFFEF3C7))
                      : (isDark ? const Color(0xFF1E293B).withOpacity(0.5) : const Color(0xFFF8FAFC)),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _applyToWeeklyRoutine 
                        ? (isDark ? SiyaqColors.accentGold.withOpacity(0.5) : const Color(0xFFF59E0B))
                        : (isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
                  ),
                ),
                child: SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  activeColor: SiyaqColors.accentGold,
                  title: Text(
                    'اعتماد التعديل على الروتين الأسبوعي',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  subtitle: Text(
                    _applyToWeeklyRoutine
                        ? 'سيتم تطبيق التعديل على هذا اليوم وكافة الأسابيع القادمة في الروتين الأسبوعي 🔄'
                        : 'سيتم تطبيق التعديل على جدول هذا اليوم فقط دون التأثير على باقي الأسابيع 📅',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: isDark ? SiyaqColors.darkTextSecondary : const Color(0xFF64748B),
                    ),
                  ),
                  value: _applyToWeeklyRoutine,
                  onChanged: (val) {
                    setState(() {
                      _applyToWeeklyRoutine = val;
                    });
                  },
                ),
              ),
            ],

            ElevatedButton(
              onPressed: () => _saveTask(),
              style: ElevatedButton.styleFrom(
                backgroundColor: SiyaqColors.accentGold,
                foregroundColor: Colors.black87,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(
                widget.taskToEdit != null ? 'حفظ التعديلات' : 'حفظ المهمة في سياق',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskTypeContextBadge(bool isDark) {
    IconData icon;
    String title;
    String subtitle;
    Color accentColor = SiyaqColors.accentGold;

    switch (_taskType) {
      case 'weekly_routine':
        icon = Icons.calendar_view_week_rounded;
        title = 'روتين أسبوعي متكرر';
        subtitle = '📌 يتكرر تلقائياً كل أسبوع في يوم ${_getWeekdayArabicName(_weekday)}';
        break;
      case 'ramadan':
        icon = Icons.nightlight_round;
        title = 'خاص بجدول شهر رمضان المبارك';
        subtitle = '🌙 يتكرر في رمضان كل يوم ${_getWeekdayArabicName(_weekday)}';
        break;
      case 'special_day':
        icon = Icons.auto_awesome_rounded;
        title = 'يوم مميز وقالب خاص';
        subtitle = '⭐ خاص بتاريخ ${DateFormat('yyyy/MM/dd', 'ar').format(widget.initialDate)}';
        break;
      case 'single_date':
      default:
        icon = Icons.today_rounded;
        title = 'مهمة مؤقتة (لتاريخ محدد)';
        subtitle = '📅 ${DateFormat('EEEE، d MMMM yyyy', 'ar').format(widget.initialDate)}';
        break;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? accentColor.withOpacity(0.35) : const Color(0xFFE2E8F0),
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: isDark ? accentColor : const Color(0xFFB45309), size: 22),
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
                    fontSize: 14,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white70 : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickDurationChip(String label, int minutes, bool isDark) {
    return ActionChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.white70 : const Color(0xFF334155),
        ),
      ),
      backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: isDark ? Colors.white12 : const Color(0xFFCBD5E1),
        ),
      ),
      onPressed: () => _extendDurationBy(minutes),
    );
  }

  Widget _buildPrayerReactionCard(String key, String title, String subtitle, bool isDark) {
    final isSelected = _prayerReaction == key;

    return InkWell(
      onTap: () {
        setState(() {
          _prayerReaction = key;
        });
      },
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? SiyaqColors.accentGold.withOpacity(0.18) : const Color(0xFFFFFBEB))
              : (isDark ? const Color(0xFF1E293B).withOpacity(0.4) : const Color(0xFFF8FAFC)),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? (isDark ? SiyaqColors.accentGold : const Color(0xFFD97706))
                : (isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
            width: isSelected ? 1.5 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: isDark ? SiyaqColors.accentGold.withOpacity(0.12) : const Color(0x1ADB7706),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
              color: isSelected 
                  ? (isDark ? SiyaqColors.accentGold : const Color(0xFFD97706)) 
                  : (isDark ? Colors.white24 : const Color(0xFF94A3B8)),
              size: 20,
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
                      color: isSelected
                          ? (isDark ? Colors.white : const Color(0xFF92400E))
                          : (isDark ? Colors.white70 : const Color(0xFF1E293B)),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: isSelected
                          ? (isDark ? Colors.white70 : const Color(0xFF78350F))
                          : (isDark ? Colors.white38 : const Color(0xFF64748B)),
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

  String _getWeekdayArabicName(int weekday) {
    switch (weekday) {
      case 1:
        return 'الاثنين';
      case 2:
        return 'الثلاثاء';
      case 3:
        return 'الأربعاء';
      case 4:
        return 'الخميس';
      case 5:
        return 'الجمعة';
      case 6:
        return 'السبت';
      case 7:
        return 'الأحد';
      default:
        return '';
    }
  }
}
