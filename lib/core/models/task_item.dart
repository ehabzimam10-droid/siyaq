class TaskItem {
  final String id;
  final String title;
  final String description;
  final DateTime startTime; // Y/M/D is important for single_date, otherwise only Time is used
  final DateTime endTime;
  
  final String taskType; // 'single_date', 'weekly_routine', 'template', 'ramadan'
  final int? weekday; // 1 (Mon) - 7 (Sun). Used for weekly_routine and ramadan
  final String? templateId; // Used if taskType == 'template'

  final bool isSleepTime;
  final String prayerReaction; // 'shift', 'pause', 'cancel'

  final bool isFlexible; 
  final bool isCompleted;
  final int priority;

  final bool isContinuation; // هل هي شريحة تكملة لمهمة بدأت في اليوم السابق؟
  final String? originalTaskId; // معرف المهمة الأصلية إذا كانت تكملة

  TaskItem({
    required this.id,
    required this.title,
    this.description = '',
    required this.startTime,
    required this.endTime,
    this.taskType = 'single_date',
    this.weekday,
    this.templateId,
    this.isSleepTime = false,
    this.prayerReaction = 'shift',
    this.isFlexible = true,
    this.isCompleted = false,
    this.priority = 2,
    this.isContinuation = false,
    this.originalTaskId,
  });

  TaskItem copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? startTime,
    DateTime? endTime,
    String? taskType,
    int? weekday,
    String? templateId,
    bool? isSleepTime,
    String? prayerReaction,
    bool? isFlexible,
    bool? isCompleted,
    int? priority,
    bool? isContinuation,
    String? originalTaskId,
  }) {
    return TaskItem(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      taskType: taskType ?? this.taskType,
      weekday: weekday ?? this.weekday,
      templateId: templateId ?? this.templateId,
      isSleepTime: isSleepTime ?? this.isSleepTime,
      prayerReaction: prayerReaction ?? this.prayerReaction,
      isFlexible: isFlexible ?? this.isFlexible,
      isCompleted: isCompleted ?? this.isCompleted,
      priority: priority ?? this.priority,
      isContinuation: isContinuation ?? this.isContinuation,
      originalTaskId: originalTaskId ?? this.originalTaskId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'taskType': taskType,
      'weekday': weekday,
      'templateId': templateId,
      'isSleepTime': isSleepTime,
      'prayerReaction': prayerReaction,
      'isFlexible': isFlexible,
      'isCompleted': isCompleted,
      'priority': priority,
      'isContinuation': isContinuation,
      'originalTaskId': originalTaskId,
    };
  }

  factory TaskItem.fromJson(Map<String, dynamic> json) {
    return TaskItem(
      id: json['id'],
      title: json['title'],
      description: json['description'] ?? '',
      startTime: DateTime.parse(json['startTime']),
      endTime: DateTime.parse(json['endTime']),
      taskType: json['taskType'] ?? 'single_date',
      weekday: json['weekday'],
      templateId: json['templateId'],
      isSleepTime: json['isSleepTime'] ?? false,
      prayerReaction: json['prayerReaction'] ?? 'shift',
      isFlexible: json['isFlexible'] ?? true,
      isCompleted: json['isCompleted'] ?? false,
      priority: json['priority'] ?? 2,
      isContinuation: json['isContinuation'] ?? false,
      originalTaskId: json['originalTaskId'],
    );
  }
}
