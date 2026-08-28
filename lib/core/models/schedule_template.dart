class ScheduleTemplate {
  final String id;
  final String name; // e.g. "إجازة نهاية الأسبوع", "رمضان"
  final String type; // 'ramadan', 'custom_date_range'
  final DateTime? startDate;
  final DateTime? endDate;

  ScheduleTemplate({
    required this.id,
    required this.name,
    required this.type,
    this.startDate,
    this.endDate,
  });

  ScheduleTemplate copyWith({
    String? id,
    String? name,
    String? type,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return ScheduleTemplate(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
    };
  }

  factory ScheduleTemplate.fromJson(Map<String, dynamic> json) {
    return ScheduleTemplate(
      id: json['id'],
      name: json['name'],
      type: json['type'],
      startDate: json['startDate'] != null ? DateTime.parse(json['startDate']) : null,
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
    );
  }
}
