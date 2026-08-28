import '../models/prayer_times.dart';
import '../models/task_item.dart';
import '../models/prayer_config.dart';

class ScheduleAdjuster {
  final Map<String, PrayerConfig> prayerConfigs;

  ScheduleAdjuster({required this.prayerConfigs});

  PrayerConfig? _findPrayerConfig(String prayerName) {
    if (prayerConfigs.containsKey(prayerName)) {
      return prayerConfigs[prayerName];
    }
    final cleanName = prayerName.replaceAll('صلاة', '').trim().toLowerCase();
    for (var entry in prayerConfigs.entries) {
      final k = entry.key.toLowerCase();
      if (k == cleanName) return entry.value;
      if ((cleanName == 'الفجر' || cleanName == 'فجر') && k == 'fajr') return entry.value;
      if ((cleanName == 'الظهر' || cleanName == 'ظهر') && k == 'dhuhr') return entry.value;
      if ((cleanName == 'العصر' || cleanName == 'عصر') && k == 'asr') return entry.value;
      if ((cleanName == 'المغرب' || cleanName == 'مغرب') && k == 'maghrib') return entry.value;
      if ((cleanName == 'العشاء' || cleanName == 'عشاء') && k == 'isha') return entry.value;
    }
    // Fallback default config if not found
    return PrayerConfig(
      prayerName: prayerName,
      minutesOffsetFromAdhan: 0,
      durationMinutes: cleanName.contains('مغرب') ? 15 : (cleanName.contains('عشاء') ? 25 : 20),
    );
  }

  // حساب النطاق المخصص لكل صلاة بناءً على الإعدادات والأذان
  Map<String, DateTime>? getPrayerBlock(String prayerName, DateTime adhanTime) {
    final config = _findPrayerConfig(prayerName);
    if (config == null) return null;

    final start = adhanTime.add(Duration(minutes: config.minutesOffsetFromAdhan));
    final end = start.add(Duration(minutes: config.durationMinutes));
    return {'start': start, 'end': end};
  }

  // التحقق من تعارض أي مهمة مع الصلوات
  Map<String, dynamic>? getConflictingPrayerBlock(
      DateTime start, DateTime end, PrayerTimes prayers) {
    for (var prayer in prayers.toList()) {
      final name = prayer['name'] as String;
      if (name == 'الشروق') continue; // الشروق ليس صلاة مفروضة

      final adhanTime = prayer['time'] as DateTime;
      final block = getPrayerBlock(name, adhanTime);
      if (block == null) continue;

      final prayerStart = block['start']!;
      final prayerEnd = block['end']!;

      // شرط تداخل فترتين زمنيتين
      if (start.isBefore(prayerEnd) && end.isAfter(prayerStart)) {
        return {
          'name': name,
          'start': prayerStart,
          'end': prayerEnd,
        };
      }
    }
    return null;
  }

  // محرك الضبط الذكي والتكيف مع الصلوات ووقت النوم ووقت الفراغ
  List<TaskItem> adjustSchedule(List<TaskItem> tasks, PrayerTimes prayers) {
    if (tasks.isEmpty) return [];

    // 1. فرز المهام وتحديد وقت النوم
    List<TaskItem> sleepTasks = tasks.where((t) => t.isSleepTime).toList();
    List<TaskItem> regularTasks = tasks.where((t) => !t.isSleepTime).toList();

    // فرز المهام العادية بحسب وقت البدء
    regularTasks.sort((a, b) => a.startTime.compareTo(b.startTime));

    List<TaskItem> processedTasks = [];

    // 2. معالجة التعارضات مع الصلوات للمهام العادية
    for (var task in regularTasks) {
      var conflict = getConflictingPrayerBlock(task.startTime, task.endTime, prayers);

      if (conflict == null) {
        processedTasks.add(task);
        continue;
      }

      final prayerStart = conflict['start'] as DateTime;
      final prayerEnd = conflict['end'] as DateTime;
      final duration = task.endTime.difference(task.startTime);

      switch (task.prayerReaction) {
        case 'shift':
          // إزاحة المهمة بالكامل لتكون بعد الصلاة
          final newStart = prayerEnd;
          final newEnd = newStart.add(duration);
          processedTasks.add(task.copyWith(startTime: newStart, endTime: newEnd));
          break;

        case 'shift_before':
          // إزاحة المهمة بالكامل لتنتهي قبل دخول وقت الصلاة
          final newEnd = prayerStart;
          final newStart = newEnd.subtract(duration);
          processedTasks.add(task.copyWith(startTime: newStart, endTime: newEnd));
          break;

        case 'pause':
          // تقطيع المهمة إلى قسمين: قبل الصلاة وبعدها
          final part1Duration = prayerStart.difference(task.startTime);
          if (part1Duration.inMinutes > 5) {
            processedTasks.add(task.copyWith(
              id: '${task.id}_p1',
              title: '${task.title} (جزء 1)',
              endTime: prayerStart,
            ));
          }

          final part2Duration = duration - part1Duration;
          if (part2Duration.inMinutes > 5) {
            processedTasks.add(task.copyWith(
              id: '${task.id}_p2',
              title: '${task.title} (جزء 2)',
              startTime: prayerEnd,
              endTime: prayerEnd.add(part2Duration),
            ));
          }
          break;

        case 'cancel':
          // إلغاء الجزء المتعارض فقط
          if (task.startTime.isBefore(prayerStart)) {
            processedTasks.add(task.copyWith(
              endTime: prayerStart,
            ));
          }
          if (task.endTime.isAfter(prayerEnd)) {
            processedTasks.add(task.copyWith(
              startTime: prayerEnd,
            ));
          }
          break;

        default:
          processedTasks.add(task);
      }
    }

    // 3. دمج الصلوات ككتل زمنية حقيقية في الجدول لتلوينها وتجنب حجزها
    for (var prayer in prayers.toList()) {
      final name = prayer['name'] as String;
      if (name == 'الشروق') continue;

      final adhanTime = prayer['time'] as DateTime;
      final block = getPrayerBlock(name, adhanTime);
      if (block != null) {
        processedTasks.add(TaskItem(
          id: 'prayer_${name}_${adhanTime.millisecondsSinceEpoch}',
          title: 'صلاة $name',
          startTime: block['start']!,
          endTime: block['end']!,
          isFlexible: false,
          taskType: 'prayer_block', // نوع خاص لكتل الصلاة
          description: 'وقت الصلاة المفروضة وتجهيزاتها',
        ));
      }
    }

    // دمج مهام النوم (لا يتم إزاحتها أو تغييرها بالصلوات)
    processedTasks.addAll(sleepTasks);

    // إعادة الترتيب بعد التعديلات
    processedTasks.sort((a, b) => a.startTime.compareTo(b.startTime));

    // 4. ملء الفراغات بـ "وقت فراغ" وحل تداخل المهام المتتالية
    List<TaskItem> finalTimeline = [];
    for (int i = 0; i < processedTasks.length; i++) {
      final current = processedTasks[i];

      if (finalTimeline.isEmpty) {
        finalTimeline.add(current);
        continue;
      }

      final previous = finalTimeline.last;

      // أ) التحقق من وجود وقت فراغ بين السابقة والحالية
      if (current.startTime.isAfter(previous.endTime)) {
        final freeStart = previous.endTime;
        final freeEnd = current.startTime;
        if (freeEnd.difference(freeStart).inMinutes >= 5) {
          finalTimeline.add(TaskItem(
            id: 'free_time_${freeStart.millisecondsSinceEpoch}',
            title: 'وقت فراغ',
            startTime: freeStart,
            endTime: freeEnd,
            isFlexible: true,
            taskType: 'free_time',
            description: 'وقت متاح لإضافة مهام أو الاسترخاء',
          ));
        }
        finalTimeline.add(current);
      } 
      // ب) التحقق من تداخل المهام العادية (إذا تداخلت مهمتان)
      else if (current.startTime.isBefore(previous.endTime)) {
        // إذا كانت المهمة الحالية صلاة أو نوم، فلها الأولوية المطلقة، ونزيح السابقة أو نقص منها
        if (current.taskType == 'prayer_block' || current.isSleepTime) {
          finalTimeline.removeLast();
          if (previous.startTime.isBefore(current.startTime)) {
            // نقص من المهمة السابقة لتنتهي عند بدء الصلاة/النوم
            finalTimeline.add(previous.copyWith(endTime: current.startTime));
          }
          finalTimeline.add(current);
        } else {
          // إزاحة المهمة الحالية لتكون بعد السابقة
          final duration = current.endTime.difference(current.startTime);
          final newStart = previous.endTime;
          final newEnd = newStart.add(duration);
          finalTimeline.add(current.copyWith(startTime: newStart, endTime: newEnd));
        }
      } else {
        finalTimeline.add(current);
      }
    }

    return finalTimeline;
  }
}
