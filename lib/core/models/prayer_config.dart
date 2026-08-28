class PrayerConfig {
  final String prayerName; // 'fajr', 'dhuhr', 'asr', 'maghrib', 'isha'
  final int minutesOffsetFromAdhan; // 0 = exactly at adhan, -10 = 10 mins before, 15 = 15 mins after
  final int durationMinutes; // Duration of the prayer block where no tasks can overlap

  PrayerConfig({
    required this.prayerName,
    required this.minutesOffsetFromAdhan,
    required this.durationMinutes,
  });

  PrayerConfig copyWith({
    String? prayerName,
    int? minutesOffsetFromAdhan,
    int? durationMinutes,
  }) {
    return PrayerConfig(
      prayerName: prayerName ?? this.prayerName,
      minutesOffsetFromAdhan: minutesOffsetFromAdhan ?? this.minutesOffsetFromAdhan,
      durationMinutes: durationMinutes ?? this.durationMinutes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'prayerName': prayerName,
      'minutesOffsetFromAdhan': minutesOffsetFromAdhan,
      'durationMinutes': durationMinutes,
    };
  }

  factory PrayerConfig.fromJson(Map<String, dynamic> json) {
    return PrayerConfig(
      prayerName: json['prayerName'],
      minutesOffsetFromAdhan: json['minutesOffsetFromAdhan'] ?? 0,
      durationMinutes: json['durationMinutes'] ?? 20,
    );
  }
}
