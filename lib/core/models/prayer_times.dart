import 'package:intl/intl.dart';

class PrayerTimes {
  final DateTime fajr;
  final DateTime sunrise;
  final DateTime dhuhr;
  final DateTime asr;
  final DateTime maghrib;
  final DateTime isha;
  final String dateString; // بصيغة DD-MM-YYYY

  PrayerTimes({
    required this.fajr,
    required this.sunrise,
    required this.dhuhr,
    required this.asr,
    required this.maghrib,
    required this.isha,
    required this.dateString,
  });

  factory PrayerTimes.fromJson(Map<String, dynamic> json, String dateStr) {
    final timings = json['data']['timings'];
    
    // الصيغة القادمة من الـ API تكون "HH:mm" (مثلاً "04:12")
    // نحتاج لدمجها مع تاريخ اليوم لإنشاء كائن DateTime كامل
    DateTime parseTime(String timeStr) {
      // إزالة أي زيادات مثل (EEST) أو غيرها إن وجدت
      final cleanTime = timeStr.split(' ')[0];
      final parts = cleanTime.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      
      final dateParts = dateStr.split('-'); // DD-MM-YYYY
      final day = int.parse(dateParts[0]);
      final month = int.parse(dateParts[1]);
      final year = int.parse(dateParts[2]);

      return DateTime(year, month, day, hour, minute);
    }

    return PrayerTimes(
      fajr: parseTime(timings['Fajr']),
      sunrise: parseTime(timings['Sunrise']),
      dhuhr: parseTime(timings['Dhuhr']),
      asr: parseTime(timings['Asr']),
      maghrib: parseTime(timings['Maghrib']),
      isha: parseTime(timings['Isha']),
      dateString: dateStr,
    );
  }

  // الحصول على أوقات الصلاة كقائمة لتسهيل معالجتها
  List<Map<String, dynamic>> toList() {
    return [
      {'name': 'الفجر', 'time': fajr},
      {'name': 'الشروق', 'time': sunrise},
      {'name': 'الظهر', 'time': dhuhr},
      {'name': 'العصر', 'time': asr},
      {'name': 'المغرب', 'time': maghrib},
      {'name': 'العشاء', 'time': isha},
    ];
  }

  // البحث عن الصلاة القادمة والوقت المتبقي لها
  Map<String, dynamic> getNextPrayer(DateTime now) {
    final list = toList();
    for (var prayer in list) {
      if (prayer['time'].isAfter(now)) {
        return {
          'name': prayer['name'],
          'time': prayer['time'],
          'difference': prayer['time'].difference(now),
        };
      }
    }
    // إذا انتهت صلوات اليوم، فالصلاة القادمة هي فجر اليوم التالي (افتراضياً نعيد فجر الغد)
    final tomorrowFajr = fajr.add(const Duration(days: 1));
    return {
      'name': 'الفجر',
      'time': tomorrowFajr,
      'difference': tomorrowFajr.difference(now),
    };
  }
}
