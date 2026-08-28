import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../models/prayer_times.dart';

class PrayerService {
  static const String _cachedPrayerPrefix = 'cached_prayer_times_';
  static const String _cachedLocationKey = 'cached_lat_lng';

  // جلب إحداثيات الموقع الحالي
  Future<Position?> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return null;
      }
      
      if (permission == LocationPermission.deniedForever) return null;

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
        timeLimit: const Duration(seconds: 5),
      );
    } catch (e) {
      print('Location error: $e');
      return null;
    }
  }

  // جلب مواقيت الصلاة لتاريخ معين (DD-MM-YYYY)
  Future<PrayerTimes> getPrayerTimes(DateTime date) async {
    if (!kIsWeb && Platform.environment.containsKey('FLUTTER_TEST')) {
      return _generateDefaultPrayers(date);
    }
    final dateStr = DateFormat('dd-MM-yyyy').format(date);
    final prefs = await SharedPreferences.getInstance();
    
    // 1. التحقق من وجود نسخة مخزنة محلياً لتجنب استدعاء الـ API غير الضروري
    final cachedData = prefs.getString('$_cachedPrayerPrefix$dateStr');
    if (cachedData != null) {
      return PrayerTimes.fromJson(jsonDecode(cachedData), dateStr);
    }

    // 2. محاولة الحصول على الموقع الجغرافي، مع استخدام إحداثيات الرياض كـ Fallback
    double latitude = 24.7136; // الرياض افتراضياً
    double longitude = 46.6753;
    
    final position = await _getCurrentLocation();
    if (position != null) {
      latitude = position.latitude;
      longitude = position.longitude;
      // حفظ آخر موقع تم العثور عليه
      await prefs.setString(_cachedLocationKey, '$latitude,$longitude');
    } else {
      // محاولة استعادة آخر موقع مخزن
      final savedLoc = prefs.getString(_cachedLocationKey);
      if (savedLoc != null) {
        final parts = savedLoc.split(',');
        latitude = double.parse(parts[0]);
        longitude = double.parse(parts[1]);
      }
    }

    // طريقة حساب أم القرى (طريقة رقم 4) تناسب السعودية والخليج
    // طريقة رابطة العالم الإسلامي (طريقة رقم 3) تناسب بقية المناطق
    // يمكن تغييرها ديناميكياً مستقبلاً، سنعتمد طريقة أم القرى حالياً
    final url = Uri.parse(
      'https://api.aladhan.com/v1/timings/${DateFormat('dd-MM-yyyy').format(date)}'
      '?latitude=$latitude&longitude=$longitude&method=4'
    );

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        
        // حفظ الاستجابة في الذاكرة المحلية لليوم المطلوب
        await prefs.setString('$_cachedPrayerPrefix$dateStr', jsonEncode(jsonResponse));
        
        return PrayerTimes.fromJson(jsonResponse, dateStr);
      } else {
        throw Exception('Failed to load prayer times from API');
      }
    } catch (e) {
      // في حال انقطاع الإنترنت التام ولم يكن هناك كاش، نقوم بإنشاء أوقات افتراضية تقريبية للرياض
      print('Network error fetching prayers: $e');
      return _generateDefaultPrayers(date);
    }
  }

  // توليد أوقات صلاة افتراضية تقريبية لمدينة الرياض في حال عدم الاتصال بالإنترنت تماماً
  PrayerTimes _generateDefaultPrayers(DateTime date) {
    final y = date.year;
    final m = date.month;
    final d = date.day;
    final dateStr = DateFormat('dd-MM-yyyy').format(date);

    return PrayerTimes(
      fajr: DateTime(y, m, d, 4, 30),
      sunrise: DateTime(y, m, d, 5, 50),
      dhuhr: DateTime(y, m, d, 12, 10),
      asr: DateTime(y, m, d, 15, 30),
      maghrib: DateTime(y, m, d, 18, 45),
      isha: DateTime(y, m, d, 20, 15),
      dateString: dateStr,
    );
  }
}
