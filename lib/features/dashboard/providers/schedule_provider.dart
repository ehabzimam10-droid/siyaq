import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../../../core/models/prayer_times.dart';
import '../../../core/models/task_item.dart';
import '../../../core/models/schedule_template.dart';
import '../../../core/services/prayer_service.dart';
import '../../../core/services/schedule_adjuster.dart';
import '../../settings/providers/settings_provider.dart';

// مخزن لتاريخ اليوم المحدد في شاشة العرض
class SelectedDateNotifier extends Notifier<DateTime> {
  @override
  DateTime build() => DateTime.now();

  void setDate(DateTime date) {
    state = date;
  }
}

final selectedDateProvider = NotifierProvider<SelectedDateNotifier, DateTime>(SelectedDateNotifier.new);

// خدمة مواقيت الصلاة
final prayerServiceProvider = Provider<PrayerService>((ref) => PrayerService());

// مخزن أوقات الصلاة المجلوبة للتاريخ المحدد
final prayerTimesProvider = FutureProvider.family<PrayerTimes, DateTime>((ref, date) async {
  final service = ref.watch(prayerServiceProvider);
  return service.getPrayerTimes(date);
});

// الحالة الخاصة بمدير الجداول
class ScheduleState {
  final List<TaskItem> allTasks; // كل المهام (شاملة الروتينية واليومية)
  final List<ScheduleTemplate> templates; // قوالب الجداول المحفوظة
  final bool isLoading;

  ScheduleState({
    required this.allTasks,
    required this.templates,
    this.isLoading = false,
  });

  ScheduleState copyWith({
    List<TaskItem>? allTasks,
    List<ScheduleTemplate>? templates,
    bool? isLoading,
  }) {
    return ScheduleState(
      allTasks: allTasks ?? this.allTasks,
      templates: templates ?? this.templates,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

// مدير الجداول والتحكم بالمهام وتعديلها
class ScheduleNotifier extends Notifier<ScheduleState> {
  static const String _tasksPrefsKey = 'siyaq_tasks_v2';
  static const String _templatesPrefsKey = 'siyaq_templates_v2';

  @override
  ScheduleState build() {
    _loadData();
    return ScheduleState(allTasks: [], templates: [], isLoading: true);
  }

  // تحميل البيانات المخزنة محلياً
  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    
    // تحميل المهام
    final jsonTasks = prefs.getString(_tasksPrefsKey);
    List<TaskItem> tasks = [];
    if (jsonTasks != null) {
      try {
        final List<dynamic> decoded = jsonDecode(jsonTasks);
        tasks = decoded.map((item) => TaskItem.fromJson(item)).toList();
      } catch (e) {
        // خطأ فك التشفير
      }
    }

    // تحميل القوالب
    final jsonTemplates = prefs.getString(_templatesPrefsKey);
    List<ScheduleTemplate> templates = [];
    if (jsonTemplates != null) {
      try {
        final List<dynamic> decoded = jsonDecode(jsonTemplates);
        templates = decoded.map((item) => ScheduleTemplate.fromJson(item)).toList();
      } catch (e) {
        // خطأ فك التشفير
      }
    }

    state = ScheduleState(allTasks: tasks, templates: templates, isLoading: false);
  }

  // حفظ المهام والقوالب
  Future<void> _saveTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = jsonEncode(state.allTasks.map((t) => t.toJson()).toList());
    await prefs.setString(_tasksPrefsKey, jsonStr);
  }

  Future<void> _saveTemplates() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = jsonEncode(state.templates.map((t) => t.toJson()).toList());
    await prefs.setString(_templatesPrefsKey, jsonStr);
  }

  // إضافة مهمة جديدة
  Future<void> addTask(TaskItem task) async {
    state = state.copyWith(allTasks: [...state.allTasks, task]);
    await _saveTasks();
  }

  // حذف مهمة
  Future<void> deleteTask(String taskId) async {
    state = state.copyWith(
      allTasks: state.allTasks.where((t) => t.id != taskId && t.originalTaskId != taskId).toList(),
    );
    await _saveTasks();
  }

  // حذف مهمة لتاريخ محدد فقط (دون التأثير على الروتين الأسبوعي في باقي الأيام)
  Future<void> deleteTaskForDate(TaskItem task, DateTime date) async {
    // 1. إذا كانت المهمة مخصصة ليوم واحد فقط (single_date أو special_day)
    if (task.taskType == 'single_date' || task.taskType == 'special_day') {
      final deleteId = task.originalTaskId ?? task.id;
      state = state.copyWith(
        allTasks: state.allTasks.where((t) => t.id != deleteId && t.id != task.id && t.originalTaskId != deleteId).toList(),
      );
      await _saveTasks();
      return;
    }

    // 2. إذا كانت المهمة قادمة من الروتين الأسبوعي أو رمضان:
    // نقوم بتخصيص هذا اليوم كـ special_day يحتوي على باقي مهام اليوم باستثناء المهمة المحذوفة
    final weekday = date.weekday;
    final settings = ref.read(settingsProvider);
    
    // جلب المهام الروتينية لليوم
    List<TaskItem> routineTasks = [];
    if (settings.isRamadanModeEnabled) {
      routineTasks = state.allTasks.where((t) => t.taskType == 'ramadan' && (t.weekday == weekday || t.weekday == null)).toList();
    } else {
      routineTasks = state.allTasks.where((t) => t.taskType == 'weekly_routine' && t.weekday == weekday).toList();
    }

    // استبعاد المهمة المراد حذفها
    final targetId = task.originalTaskId ?? task.id;
    final remainingRoutine = routineTasks.where((t) => t.id != targetId && t.id != task.id).toList();

    // تحويل المهام الروتينية المتبقية إلى مهام special_day لهذا اليوم
    final newSpecialDayTasks = remainingRoutine.map((src) {
      final start = DateTime(date.year, date.month, date.day, src.startTime.hour, src.startTime.minute);
      var end = DateTime(date.year, date.month, date.day, src.endTime.hour, src.endTime.minute);
      if (end.isBefore(start)) end = end.add(const Duration(days: 1));

      return TaskItem(
        id: const Uuid().v4(),
        title: src.title,
        description: src.description,
        startTime: start,
        endTime: end,
        taskType: 'special_day',
        weekday: weekday,
        isSleepTime: src.isSleepTime,
        prayerReaction: src.prayerReaction,
        isFlexible: src.isFlexible,
        priority: src.priority,
      );
    }).toList();

    // إزالة أي مهام قديمة لنفس التاريخ المخصص
    final otherTasks = state.allTasks.where((t) {
      if (t.taskType == 'special_day' &&
          t.startTime.year == date.year &&
          t.startTime.month == date.month &&
          t.startTime.day == date.day) {
        return false;
      }
      return true;
    }).toList();

    state = state.copyWith(allTasks: [...otherTasks, ...newSpecialDayTasks]);
    await _saveTasks();
  }

  // تحديث مهمة
  Future<void> updateTask(TaskItem updatedTask) async {
    final targetId = updatedTask.originalTaskId ?? updatedTask.id;
    final index = state.allTasks.indexWhere((t) => t.id == updatedTask.id || t.id == targetId);

    if (index != -1) {
      final updatedList = List<TaskItem>.from(state.allTasks);
      updatedList[index] = updatedTask.copyWith(id: state.allTasks[index].id);
      state = state.copyWith(allTasks: updatedList);
    } else {
      // إذا كانت مهمة روتينية مولدة ديناميكياً ليوم معين، نضيف نسخة مخصصة لهذا اليوم
      state = state.copyWith(allTasks: [...state.allTasks, updatedTask]);
    }
    await _saveTasks();
  }

  // تعديل مهمة مع خيار تطبيق التعديل على الروتين الأسبوعي أو اليوم المحدد فقط
  Future<void> updateTaskForDate({
    required TaskItem originalTask,
    required TaskItem updatedTask,
    required DateTime date,
    required bool applyToWeeklyRoutine,
  }) async {
    final originalId = originalTask.originalTaskId ?? originalTask.id;

    if (applyToWeeklyRoutine) {
      // 1. تطبيق التعديل على القالب العام في الروتين الأسبوعي
      final index = state.allTasks.indexWhere((t) => t.id == originalId || t.id == originalTask.id);
      if (index != -1) {
        final updatedList = List<TaskItem>.from(state.allTasks);
        updatedList[index] = updatedTask.copyWith(
          id: state.allTasks[index].id,
          taskType: state.allTasks[index].taskType,
          weekday: state.allTasks[index].weekday,
        );
        state = state.copyWith(allTasks: updatedList);
      } else {
        state = state.copyWith(allTasks: [...state.allTasks, updatedTask]);
      }
      await _saveTasks();
      return;
    }

    // 2. تطبيق التعديل على هذا اليوم المحدد فقط:
    // إذا كانت المهمة مخصصة لليوم فقط (single_date أو special_day)
    if (originalTask.taskType == 'single_date' || originalTask.taskType == 'special_day') {
      final index = state.allTasks.indexWhere((t) => t.id == originalTask.id || t.id == originalId);
      if (index != -1) {
        final updatedList = List<TaskItem>.from(state.allTasks);
        updatedList[index] = updatedTask.copyWith(id: state.allTasks[index].id);
        state = state.copyWith(allTasks: updatedList);
      } else {
        state = state.copyWith(allTasks: [...state.allTasks, updatedTask]);
      }
      await _saveTasks();
      return;
    }

    // إذا كانت المهمة قادمة من الروتين الأسبوعي: نخصص هذا اليوم كـ special_day
    final weekday = date.weekday;
    final settings = ref.read(settingsProvider);
    List<TaskItem> routineTasks = [];
    if (settings.isRamadanModeEnabled) {
      routineTasks = state.allTasks.where((t) => t.taskType == 'ramadan' && (t.weekday == weekday || t.weekday == null)).toList();
    } else {
      routineTasks = state.allTasks.where((t) => t.taskType == 'weekly_routine' && t.weekday == weekday).toList();
    }

    final newSpecialDayTasks = routineTasks.map((src) {
      if (src.id == originalId || src.id == originalTask.id) {
        return updatedTask.copyWith(
          id: const Uuid().v4(),
          taskType: 'special_day',
          weekday: weekday,
        );
      }
      final start = DateTime(date.year, date.month, date.day, src.startTime.hour, src.startTime.minute);
      var end = DateTime(date.year, date.month, date.day, src.endTime.hour, src.endTime.minute);
      if (end.isBefore(start)) end = end.add(const Duration(days: 1));

      return TaskItem(
        id: const Uuid().v4(),
        title: src.title,
        description: src.description,
        startTime: start,
        endTime: end,
        taskType: 'special_day',
        weekday: weekday,
        isSleepTime: src.isSleepTime,
        prayerReaction: src.prayerReaction,
        isFlexible: src.isFlexible,
        priority: src.priority,
      );
    }).toList();

    // إزالة أي مهام مخصصة قديمة لنفس التاريخ
    final otherTasks = state.allTasks.where((t) {
      if (t.taskType == 'special_day' &&
          t.startTime.year == date.year &&
          t.startTime.month == date.month &&
          t.startTime.day == date.day) {
        return false;
      }
      return true;
    }).toList();

    state = state.copyWith(allTasks: [...otherTasks, ...newSpecialDayTasks]);
    await _saveTasks();
  }

  // إضافة قالب جديد
  Future<void> addTemplate(ScheduleTemplate template) async {
    state = state.copyWith(templates: [...state.templates, template]);
    await _saveTemplates();
  }

  // حذف قالب
  Future<void> deleteTemplate(String templateId) async {
    // احذف المهام المرتبطة بالقالب أيضاً
    state = state.copyWith(
      templates: state.templates.where((t) => t.id != templateId).toList(),
      allTasks: state.allTasks.where((t) => t.templateId != templateId).toList(),
    );
    await _saveTemplates();
    await _saveTasks();
  }

  // تحليل الاستنساخ: جلب المهام المستوردة وفحص التعارضات مع استبعاد المتطابقة تماماً تلقائياً
  Map<String, dynamic> analyzeCloneOperation({
    required List<TaskItem> incomingTasks,
    required String targetTaskType,
    int? targetWeekday,
    DateTime? targetDate,
  }) {
    // 1. تحديد المهام الموجودة مسبقاً في الوجهة
    final existingTargetTasks = state.allTasks.where((t) {
      if (t.taskType != targetTaskType) return false;
      if (targetWeekday != null && t.weekday != targetWeekday) return false;
      if (targetDate != null) {
        final isSameDate = t.startTime.year == targetDate.year &&
            t.startTime.month == targetDate.month &&
            t.startTime.day == targetDate.day;
        if (!isSameDate) return false;
      }
      return true;
    }).toList();

    // 2. استبعاد المهام المتطابقة تماماً (Exact Duplicates) بغض النظر عن الاختيار
    final nonDuplicateIncoming = incomingTasks.where((src) {
      return !existingTargetTasks.any((dest) =>
          src.title.trim() == dest.title.trim() &&
          src.startTime.hour == dest.startTime.hour &&
          src.startTime.minute == dest.startTime.minute &&
          src.endTime.hour == dest.endTime.hour &&
          src.endTime.minute == dest.endTime.minute &&
          src.isSleepTime == dest.isSleepTime);
    }).toList();

    // 3. فحص المهام التي تتعارض في الوقت مع المهام الموجودة
    final conflictingIncoming = nonDuplicateIncoming.where((src) {
      return existingTargetTasks.any((dest) => _hasTimeConflict(src, dest));
    }).toList();

    return {
      'existingTargetTasks': existingTargetTasks,
      'nonDuplicateIncoming': nonDuplicateIncoming,
      'conflictingIncoming': conflictingIncoming,
      'hasConflicts': conflictingIncoming.isNotEmpty,
    };
  }

  // تنفيذ استنساخ المهام بحسب الوضع المختار ('replace', 'skip_conflicts', 'add_all')
  Future<int> executeCloneTasks({
    required List<TaskItem> nonDuplicateIncoming,
    required List<TaskItem> existingTargetTasks,
    required String targetTaskType,
    int? targetWeekday,
    DateTime? targetDate,
    required String mode, // 'replace', 'skip_conflicts', 'add_all'
  }) async {
    if (nonDuplicateIncoming.isEmpty) {
      return 0;
    }

    List<TaskItem> tasksToAdd = [];

    if (mode == 'replace') {
      final targetTaskIds = existingTargetTasks.map((t) => t.id).toSet();
      final remainingTasks = state.allTasks.where((t) => !targetTaskIds.contains(t.id)).toList();

      for (final src in nonDuplicateIncoming) {
        tasksToAdd.add(_createClonedTask(src, targetTaskType, targetWeekday, targetDate));
      }

      state = state.copyWith(allTasks: [...remainingTasks, ...tasksToAdd]);
      await _saveTasks();
      return tasksToAdd.length;
    }

    if (mode == 'skip_conflicts') {
      for (final src in nonDuplicateIncoming) {
        final hasConflict = existingTargetTasks.any((dest) => _hasTimeConflict(src, dest));
        if (!hasConflict) {
          tasksToAdd.add(_createClonedTask(src, targetTaskType, targetWeekday, targetDate));
        }
      }

      if (tasksToAdd.isEmpty) {
        return 0;
      }

      state = state.copyWith(allTasks: [...state.allTasks, ...tasksToAdd]);
      await _saveTasks();
      return tasksToAdd.length;
    }

    // mode == 'add_all'
    for (final src in nonDuplicateIncoming) {
      tasksToAdd.add(_createClonedTask(src, targetTaskType, targetWeekday, targetDate));
    }

    state = state.copyWith(allTasks: [...state.allTasks, ...tasksToAdd]);
    await _saveTasks();
    return tasksToAdd.length;
  }

  bool _hasTimeConflict(TaskItem a, TaskItem b) {
    final aStart = a.startTime.hour * 60 + a.startTime.minute;
    var aEnd = a.endTime.hour * 60 + a.endTime.minute;
    if (aEnd <= aStart) aEnd += 24 * 60;

    final bStart = b.startTime.hour * 60 + b.startTime.minute;
    var bEnd = b.endTime.hour * 60 + b.endTime.minute;
    if (bEnd <= bStart) bEnd += 24 * 60;

    return aStart < bEnd && aEnd > bStart;
  }

  TaskItem _createClonedTask(TaskItem src, String targetTaskType, int? targetWeekday, DateTime? targetDate) {
    DateTime start;
    DateTime end;

    if (targetDate != null) {
      start = DateTime(targetDate.year, targetDate.month, targetDate.day, src.startTime.hour, src.startTime.minute);
      end = DateTime(targetDate.year, targetDate.month, targetDate.day, src.endTime.hour, src.endTime.minute);
      if (end.isBefore(start)) end = end.add(const Duration(days: 1));
    } else {
      start = src.startTime;
      end = src.endTime;
    }

    return TaskItem(
      id: const Uuid().v4(),
      title: src.title,
      description: src.description,
      startTime: start,
      endTime: end,
      taskType: targetTaskType,
      weekday: targetWeekday,
      isSleepTime: src.isSleepTime,
      prayerReaction: src.prayerReaction,
      isFlexible: src.isFlexible,
      priority: src.priority,
    );
  }

  // نسخ روتين يوم معين من أيام الأسبوع إلى يوم مميز كنسخة قابلة للتعديل
  Future<void> copyWeekdayToSpecialDay(int fromWeekday, DateTime targetDate) async {
    final weeklyTasks = state.allTasks.where((t) => t.taskType == 'weekly_routine' && t.weekday == fromWeekday).toList();
    final analysis = analyzeCloneOperation(
      incomingTasks: weeklyTasks,
      targetTaskType: 'special_day',
      targetDate: targetDate,
    );
    await executeCloneTasks(
      nonDuplicateIncoming: analysis['nonDuplicateIncoming'],
      existingTargetTasks: analysis['existingTargetTasks'],
      targetTaskType: 'special_day',
      targetDate: targetDate,
      mode: 'replace',
    );
  }

  // جلب المهام وتكييفها ديناميكياً ليوم معين مع دعم المهام الممتدة عبر منتصف الليل
  List<TaskItem> getAdjustedTasksForDate(DateTime date, PrayerTimes prayers) {
    final settings = ref.read(settingsProvider);
    final weekday = date.weekday; // 1 (الاثنين) - 7 (الأحد) فلاتر الافتراضي
    final yesterday = date.subtract(const Duration(days: 1));
    final yesterdayWeekday = yesterday.weekday;

    // 1. فحص وجود مهام "special_day" (يوم مخصص ومعدل خصيصاً لهذا التاريخ)
    List<TaskItem> dayTasks = state.allTasks.where((t) {
      return t.taskType == 'special_day' &&
          t.startTime.year == date.year &&
          t.startTime.month == date.month &&
          t.startTime.day == date.day;
    }).toList();

    // 2. إذا لم يكن هناك جدول مخصص لهذا التاريخ، نعتمد الروتين الأسبوعي أو جدول رمضان
    if (dayTasks.isEmpty) {
      if (settings.isRamadanModeEnabled) {
        // تصفية مهام رمضان
        final ramadanTasks = state.allTasks.where((t) {
          return t.taskType == 'ramadan' && (t.weekday == weekday || t.weekday == null);
        }).toList();
        
        dayTasks = _mapTasksToDate(ramadanTasks, date);
      } else {
        // تصفية مهام الروتين الأسبوعي الثابت
        final weeklyTasks = state.allTasks.where((t) {
          return t.taskType == 'weekly_routine' && t.weekday == weekday;
        }).toList();
        
        dayTasks = _mapTasksToDate(weeklyTasks, date);
      }
    }

    // 3. جلب ودمج المهام العادية المؤقتة (single_date) لهذا اليوم المحدد
    final singleTasks = state.allTasks.where((t) {
      return t.taskType == 'single_date' &&
          t.startTime.year == date.year &&
          t.startTime.month == date.month &&
          t.startTime.day == date.day;
    }).toList();

    List<TaskItem> mergedTasks = [...dayTasks, ...singleTasks];

    // 4. الذكاء الفائق: جلب تكملة المهام الممتدة من الأمس عبر منتصف الليل (Overnight Task Continuation)
    final startOfToday = DateTime(date.year, date.month, date.day, 0, 0);

    // أ) فحص المهام المؤقتة أو الخاصة بيوم أمس التي تمتد لليوم
    final yesterdayAdhocTasks = state.allTasks.where((t) {
      final isYesterday = t.startTime.year == yesterday.year &&
          t.startTime.month == yesterday.month &&
          t.startTime.day == yesterday.day;
      return isYesterday && t.endTime.isAfter(startOfToday);
    }).toList();

    for (final task in yesterdayAdhocTasks) {
      final continuationEnd = DateTime(date.year, date.month, date.day, task.endTime.hour, task.endTime.minute);
      if (continuationEnd.isAfter(startOfToday)) {
        mergedTasks.add(task.copyWith(
          id: 'continuation_${task.id}',
          title: task.title,
          description: task.description.isNotEmpty ? task.description : 'مهمة ممتدة عبر منتصف الليل من اليوم السابق',
          startTime: startOfToday,
          endTime: continuationEnd,
          isContinuation: true,
          originalTaskId: task.id,
        ));
      }
    }

    // ب) فحص المهام الروتينية ليوم أمس إن لم تكن هناك مهام خاصة واستمر روتينها لصباح اليوم
    final yesterdaySpecialTasks = state.allTasks.where((t) {
      return t.taskType == 'special_day' &&
          t.startTime.year == yesterday.year &&
          t.startTime.month == yesterday.month &&
          t.startTime.day == yesterday.day;
    }).toList();

    if (yesterdaySpecialTasks.isEmpty) {
      List<TaskItem> yesterdayRoutine = [];
      if (settings.isRamadanModeEnabled) {
        yesterdayRoutine = state.allTasks.where((t) => t.taskType == 'ramadan' && (t.weekday == yesterdayWeekday || t.weekday == null)).toList();
      } else {
        yesterdayRoutine = state.allTasks.where((t) => t.taskType == 'weekly_routine' && t.weekday == yesterdayWeekday).toList();
      }

      for (final rTask in yesterdayRoutine) {
        final rStart = rTask.startTime;
        final rEnd = rTask.endTime;
        final crossesMidnight = rEnd.isBefore(rStart) || (rEnd.day != rStart.day) || (rEnd.hour < rStart.hour);
        if (crossesMidnight) {
          final continuationEnd = DateTime(date.year, date.month, date.day, rEnd.hour, rEnd.minute);
          if (continuationEnd.isAfter(startOfToday)) {
            mergedTasks.add(rTask.copyWith(
              id: 'routine_continuation_${rTask.id}_${date.day}',
              title: rTask.title,
              description: rTask.description.isNotEmpty ? rTask.description : 'روتين ممتد عبر منتصف الليل من اليوم السابق',
              startTime: startOfToday,
              endTime: continuationEnd,
              isContinuation: true,
              originalTaskId: rTask.id,
            ));
          }
        }
      }
    }

    // 5. تطبيق خوارزمية التكيف والتزامن مع أوقات الصلاة المخصصة لكل صلاة
    final adjuster = ScheduleAdjuster(prayerConfigs: settings.prayerConfigs);
    return adjuster.adjustSchedule(mergedTasks, prayers);
  }

  // دالة مساعدة لنسخ المهام الروتينية لليوم المستهدف مع مراعاة عبور منتصف الليل
  List<TaskItem> _mapTasksToDate(List<TaskItem> tasks, DateTime targetDate) {
    return tasks.map((t) {
      final start = DateTime(targetDate.year, targetDate.month, targetDate.day, t.startTime.hour, t.startTime.minute);
      var end = DateTime(targetDate.year, targetDate.month, targetDate.day, t.endTime.hour, t.endTime.minute);
      if (end.isBefore(start) || (t.endTime.day != t.startTime.day) || (t.endTime.hour < t.startTime.hour)) {
        end = end.add(const Duration(days: 1));
      }
      return t.copyWith(startTime: start, endTime: end);
    }).toList();
  }

  // فحص التعارضات عند إضافة مهمة مؤقتة جديدة
  List<TaskItem> checkOverlappingTasks(TaskItem newTask) {
    return state.allTasks.where((t) {
      // فقط نفحص المهام المقررة في نفس التاريخ والمستقبلية وغير المنتهية
      if (t.startTime.year == newTask.startTime.year &&
          t.startTime.month == newTask.startTime.month &&
          t.startTime.day == newTask.startTime.day &&
          t.id != newTask.id) {
        
        // شرط التقاطع
        return newTask.startTime.isBefore(t.endTime) && newTask.endTime.isAfter(t.startTime);
      }
      return false;
    }).toList();
  }

  // حل التعارضات بالقص أو الحذف
  Future<void> resolveConflictingTasks(TaskItem newTask, List<TaskItem> conflicts, String action) async {
    List<TaskItem> updatedTasks = List.from(state.allTasks);

    if (action == 'delete') {
      // حذف المهام المتعارضة تماماً
      final idsToDelete = conflicts.map((c) => c.id).toSet();
      updatedTasks = updatedTasks.where((t) => !idsToDelete.contains(t.id)).toList();
    } else if (action == 'trim') {
      // قص المهام المتعارضة
      for (var conflict in conflicts) {
        final index = updatedTasks.indexWhere((t) => t.id == conflict.id);
        if (index != -1) {
          final task = updatedTasks[index];
          // إذا كانت المهمة المتعارضة تبدأ قبل المهمة الجديدة
          if (task.startTime.isBefore(newTask.startTime)) {
            // نقص نهايتها لتنتهي عند بدء الجديدة
            updatedTasks[index] = task.copyWith(endTime: newTask.startTime);
          } 
          // إذا كانت تبدأ في منتصف أو بعد المهمة الجديدة وتطول بعدها
          else if (task.endTime.isAfter(newTask.endTime)) {
            // نقص بدايتها لتبدأ فور انتهاء الجديدة
            updatedTasks[index] = task.copyWith(startTime: newTask.endTime);
          }
        }
      }
    }

    // إضافة المهمة الجديدة
    updatedTasks.add(newTask);
    state = state.copyWith(allTasks: updatedTasks);
    await _saveTasks();
  }
}

// الموفر العام لمدير الجدولة
final scheduleProvider = NotifierProvider<ScheduleNotifier, ScheduleState>(ScheduleNotifier.new);
