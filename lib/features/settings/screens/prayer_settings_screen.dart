import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/colors.dart';
import '../../../core/widgets/solarium_glass_container.dart';
import '../../../core/widgets/floating_app_bar.dart';
import '../../../core/widgets/siyaq_toast.dart';
import '../../../core/models/prayer_config.dart';
import '../../../core/models/prayer_times.dart';
import '../../dashboard/providers/schedule_provider.dart';
import '../providers/settings_provider.dart';

class PrayerSettingsScreen extends ConsumerStatefulWidget {
  const PrayerSettingsScreen({super.key});

  @override
  ConsumerState<PrayerSettingsScreen> createState() => _PrayerSettingsScreenState();
}

class _PrayerSettingsScreenState extends ConsumerState<PrayerSettingsScreen> {
  final ScrollController _scrollController = ScrollController();

  final Map<String, String> _prayerArabicNames = const {
    'Fajr': 'صلاة الفجر',
    'Dhuhr': 'صلاة الظهر',
    'Asr': 'صلاة العصر',
    'Maghrib': 'صلاة المغرب',
    'Isha': 'صلاة العشاء',
  };

  final Map<String, IconData> _prayerIcons = const {
    'Fajr': Icons.wb_twilight_rounded,
    'Dhuhr': Icons.wb_sunny_rounded,
    'Asr': Icons.wb_cloudy_rounded,
    'Maghrib': Icons.nights_stay_outlined,
    'Isha': Icons.bedtime_outlined,
  };

  final List<Map<String, String>> _methods = const [
    {'id': 'Makkah', 'name': 'أم القرى - مكة المكرمة'},
    {'id': 'MWL', 'name': 'رابطة العالم الإسلامي (MWL)'},
    {'id': 'Egyptian', 'name': 'الهيئة العامة المصرية للمساحة'},
    {'id': 'ISNA', 'name': 'الجمعية الإسلامية لأمريكا الشمالية (ISNA)'},
    {'id': 'Karachi', 'name': 'جامعة العلوم الإسلامية بكراتشي'},
    {'id': 'Kuwait', 'name': 'وزارة الأوقاف والشؤون الإسلامية بالكويت'},
    {'id': 'Qatar', 'name': 'وزارة الأوقاف والشؤون الإسلامية بقطر'},
    {'id': 'UAE', 'name': 'الهيئة العامة للشؤون الإسلامية والأوقاف بالإمارات'},
    {'id': 'Singapore', 'name': 'مجلس أوغاما إسلام سنغافورة (MUIS)'},
    {'id': 'AlAdhanDirect', 'name': 'حساب مباشر دقيق (AlAdhan Direct)'},
  ];

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  DateTime? _getAdhanTimeForPrayer(String prayerKey, PrayerTimes? prayers) {
    if (prayers == null) return null;
    switch (prayerKey.toLowerCase()) {
      case 'fajr':
        return prayers.fajr;
      case 'dhuhr':
        return prayers.dhuhr;
      case 'asr':
        return prayers.asr;
      case 'maghrib':
        return prayers.maghrib;
      case 'isha':
        return prayers.isha;
      default:
        return null;
    }
  }

  String _formatOffsetLabel(int offsetMinutes) {
    if (offsetMinutes < 0) {
      return '${offsetMinutes.abs()} دقيقة قبل الأذان';
    } else if (offsetMinutes == 0) {
      return 'عند الأذان تماماً';
    } else {
      return '$offsetMinutes دقيقة بعد الأذان';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final settings = ref.watch(settingsProvider);
    
    // تطبيع التاريخ لليوم بدون ميكروثواني لتجنب إعادة البناء المتكررة
    final now = DateTime.now();
    final todayNormalized = DateTime(now.year, now.month, now.day);
    final prayers = ref.watch(prayerTimesProvider(todayNormalized)).value;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: FloatingAppBar(
        scrollController: _scrollController,
        showBackButton: true,
        title: const Text(
          'إعدادات أوقات الصلاة',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      body: Container(
        color: Colors.transparent,
        child: SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 900),
              child: ListView(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
                children: [
                  // 1. بطاقة طريقة الحساب الفلكي
                  SolariumGlassContainer(
                    margin: const EdgeInsets.only(bottom: 20.0),
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: SiyaqColors.accentGold.withOpacity(0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.calculate_outlined, color: SiyaqColors.accentGold, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'طريقة حساب أوقات الصلاة',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'الجهة المعتمدة لحساب درجات الشفق وزوايا الصلاة في منطقتك',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark ? SiyaqColors.darkTextSecondary : const Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        DropdownButtonFormField<String>(
                          value: settings.calculationMethod,
                          dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black87,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                          decoration: InputDecoration(
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            filled: true,
                            fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                          ),
                          items: _methods.map((m) => DropdownMenuItem<String>(
                            value: m['id'],
                            child: Text(m['name']!),
                          )).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              ref.read(settingsProvider.notifier).setCalculationMethod(val);
                              SiyaqToast.show(
                                context,
                                'تم تحديث طريقة حساب أوقات الصلاة! 🕌',
                                type: SiyaqToastType.success,
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),

                  // عنوان القسم
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12.0, right: 4.0),
                    child: Text(
                      'تخصيص فترات وبداية/نهاية كل صلاة:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                  ),

                  // بطاقات الصلوات الخمس المباشرة (تظهر فوراً بدون أي تأخير أو تعليق)
                  _buildPrayersList(context, settings, prayers, isDark, isMobile),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPrayersList(BuildContext context, SiyaqSettings settings, PrayerTimes? prayers, bool isDark, bool isMobile) {
    return Column(
      children: settings.prayerConfigs.values.map((config) {
        final prayerKey = config.prayerName;
        final arabicName = _prayerArabicNames[prayerKey] ?? 'صلاة $prayerKey';
        final icon = _prayerIcons[prayerKey] ?? Icons.mosque_outlined;
        final adhanTime = _getAdhanTimeForPrayer(prayerKey, prayers);

        // القيم الحالية
        final startOffset = config.minutesOffsetFromAdhan;
        final endOffset = config.minutesOffsetFromAdhan + config.durationMinutes;
        final totalDuration = config.durationMinutes;

        // حساب الأوقات الفعلية المباشرة
        String timeRangeText = 'المدة المحددة: $totalDuration دقيقة';
        String adhanTimeText = '';
        if (adhanTime != null) {
          final actualStart = adhanTime.add(Duration(minutes: startOffset));
          final actualEnd = adhanTime.add(Duration(minutes: endOffset));
          adhanTimeText = 'الأذان: ${DateFormat('hh:mm a').format(adhanTime)}';
          timeRangeText = 'من ${DateFormat('hh:mm a').format(actualStart)} إلى ${DateFormat('hh:mm a').format(actualEnd)} (المدة: $totalDuration دقيقة)';
        }

        // حدود شريط النهاية
        final minEnd = (startOffset + 10).toDouble();
        final maxEnd = 60.0;
        final clampedEndOffset = endOffset.toDouble().clamp(minEnd, maxEnd);

        return Container(
          margin: const EdgeInsets.only(bottom: 16.0),
          child: SolariumGlassContainer(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // رأس البطاقة: اسم الصلاة + وقت الأذان الفعلي
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: (isDark ? const Color(0xFF2DD4BF) : const Color(0xFF0D9488)).withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(icon, color: isDark ? const Color(0xFF2DD4BF) : const Color(0xFF0D9488), size: 20),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          arabicName,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                    if (adhanTimeText.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          adhanTimeText,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white70 : const Color(0xFF475569),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                // شارة النطاق الزمني المحسوب لليوم
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: (isDark ? SiyaqColors.accentGold : const Color(0xFFB45309)).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: (isDark ? SiyaqColors.accentGold : const Color(0xFFB45309)).withOpacity(0.3),
                      width: 0.8,
                    ),
                  ),
                  child: Text(
                    timeRangeText,
                    style: TextStyle(
                      fontSize: isMobile ? 12.5 : 13.5,
                      fontWeight: FontWeight.bold,
                      color: isDark ? SiyaqColors.accentGold : const Color(0xFFB45309),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 16),

                // --- 1. شريط بداية وقت الصلاة (من 20 دقيقة قبل إلى 40 دقيقة بعد الأذان) ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'بداية وقت الصلاة (بالنسبة للأذان):',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white70 : const Color(0xFF334155),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                      decoration: BoxDecoration(
                        color: (isDark ? Colors.cyanAccent : const Color(0xFF0D9488)).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _formatOffsetLabel(startOffset),
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.cyanAccent : const Color(0xFF0D9488),
                        ),
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: startOffset.toDouble().clamp(-20.0, 40.0),
                  min: -20,
                  max: 40,
                  divisions: 60,
                  activeColor: isDark ? Colors.cyanAccent : const Color(0xFF0D9488),
                  inactiveColor: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                  onChanged: (val) {
                    final newStart = val.toInt();
                    // ضمان أن تكون نهاية الصلاة بعد البداية بـ 10 دقائق على الأقل
                    int newEnd = endOffset;
                    if (newEnd < newStart + 10) {
                      newEnd = (newStart + 10).clamp(-10, 60);
                    }
                    final newDuration = (newEnd - newStart).clamp(10, 80);
                    ref.read(settingsProvider.notifier).updatePrayerConfig(
                      config.copyWith(
                        minutesOffsetFromAdhan: newStart,
                        durationMinutes: newDuration,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 10),

                // --- 2. شريط نهاية وقت الصلاة (من بعد وقت البدء بـ 10 دقائق إلى بعد الأذان بـ 60 دقيقة) ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'نهاية وقت الصلاة (بالنسبة للأذان):',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white70 : const Color(0xFF334155),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                      decoration: BoxDecoration(
                        color: (isDark ? SiyaqColors.accentGold : const Color(0xFFB45309)).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _formatOffsetLabel(endOffset),
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: isDark ? SiyaqColors.accentGold : const Color(0xFFB45309),
                        ),
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: clampedEndOffset,
                  min: minEnd,
                  max: maxEnd,
                  divisions: (maxEnd - minEnd).toInt() > 0 ? (maxEnd - minEnd).toInt() : 1,
                  activeColor: isDark ? SiyaqColors.accentGold : const Color(0xFFD97706),
                  inactiveColor: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                  onChanged: (val) {
                    final newEnd = val.toInt();
                    final newDuration = (newEnd - startOffset).clamp(10, 80);
                    ref.read(settingsProvider.notifier).updatePrayerConfig(
                      config.copyWith(durationMinutes: newDuration),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
