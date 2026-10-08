import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/colors.dart';
import '../../../core/widgets/solarium_glass_container.dart';
import '../../../core/widgets/siyaq_toast.dart';
import '../providers/settings_provider.dart';
import 'weekly_schedule_manager.dart';
import 'ramadan_schedule_manager.dart';
import 'templates_manager_screen.dart';
import 'api_keys_manager_screen.dart';
import 'prayer_settings_screen.dart';
import '../../../core/services/app_update_service.dart';

class SettingsScreen extends ConsumerWidget {
  final ScrollController scrollController;

  const SettingsScreen({
    super.key,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final settings = ref.watch(settingsProvider);
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
              constraints: const BoxConstraints(maxWidth: 900),
              child: ListView(
                controller: scrollController,
                padding: EdgeInsets.only(
                  top: 90.0,
                  left: isMobile ? 12.0 : 20.0,
                  right: isMobile ? 12.0 : 20.0,
                  bottom: 100.0,
                ),
                children: [
                  // 1. قسم إدارة الجداول والقوالب
                  _buildSectionHeader('إدارة الجداول والروتين', isDark),
                  SolariumGlassContainer(
                    margin: const EdgeInsets.only(bottom: 20.0),
                    padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 4.0),
                    child: Column(
                      children: [
                        // الجدول الأسبوعي
                        _buildNavTile(
                          context: context,
                          icon: Icons.calendar_view_week_rounded,
                          iconColor: isDark ? SiyaqColors.accentGold : const Color(0xFFB45309),
                          iconBgColor: isDark ? SiyaqColors.accentGold.withOpacity(0.15) : const Color(0xFFFEF3C7),
                          title: 'الجدول الأسبوعي الثابت',
                          subtitle: 'تخصيص روتين متكرر لجميع أيام الأسبوع',
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (context) => const WeeklyScheduleManager()),
                          ),
                          isDark: isDark,
                        ),
                        Divider(height: 1, color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),

                        // جدول رمضان
                        _buildNavTile(
                          context: context,
                          icon: Icons.nightlight_round,
                          iconColor: isDark ? SiyaqColors.accentGold : const Color(0xFFB45309),
                          iconBgColor: isDark ? SiyaqColors.accentGold.withOpacity(0.15) : const Color(0xFFFEF3C7),
                          title: 'جدول شهر رمضان المبارك',
                          subtitle: 'تخصيص روتين العبادة والجدول اليومي لشهر رمضان',
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (context) => const RamadanScheduleManager()),
                          ),
                          isDark: isDark,
                        ),
                        Divider(height: 1, color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),

                        // قوالب الأيام المميزة
                        _buildNavTile(
                          context: context,
                          icon: Icons.auto_awesome_rounded,
                          iconColor: isDark ? SiyaqColors.accentGold : const Color(0xFFB45309),
                          iconBgColor: isDark ? SiyaqColors.accentGold.withOpacity(0.15) : const Color(0xFFFEF3C7),
                          title: 'قوالب الأيام المميزة',
                          subtitle: 'تخصيص وتطبيق قوالب لأيام وتواريخ خاصة',
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (context) => const TemplatesManagerScreen()),
                          ),
                          isDark: isDark,
                        ),
                      ],
                    ),
                  ),

                  // 2. قسم المزودين والتخصيص المتقدم
                  _buildSectionHeader('الذكاء الاصطناعي وأوقات الصلاة', isDark),
                  SolariumGlassContainer(
                    margin: const EdgeInsets.only(bottom: 20.0),
                    padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 4.0),
                    child: Column(
                      children: [
                        // مفاتيح ومزودي الذكاء الاصطناعي
                        _buildNavTile(
                          context: context,
                          icon: Icons.psychology_rounded,
                          iconColor: const Color(0xFF3B82F6),
                          iconBgColor: const Color(0xFF3B82F6).withOpacity(isDark ? 0.2 : 0.12),
                          title: 'مزودي الذكاء الاصطناعي (API Keys)',
                          subtitle: 'ربط Gemini, OpenAI, Claude, DeepSeek, Groq...',
                          trailingWidget: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFF3B82F6).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              settings.activeAiProvider.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF3B82F6),
                              ),
                            ),
                          ),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (context) => const ApiKeysManagerScreen()),
                          ),
                          isDark: isDark,
                        ),
                        Divider(height: 1, color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),

                        // إعدادات أوقات الصلاة
                        _buildNavTile(
                          context: context,
                          icon: Icons.mosque_rounded,
                          iconColor: isDark ? Colors.cyanAccent : const Color(0xFF0D9488),
                          iconBgColor: (isDark ? Colors.cyanAccent : const Color(0xFF0D9488)).withOpacity(isDark ? 0.2 : 0.12),
                          title: 'إعدادات أوقات وتنبيهات الصلاة',
                          subtitle: 'تخصيص فترات وبداية/نهاية الصلوات وطرق الحساب',
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (context) => const PrayerSettingsScreen()),
                          ),
                          isDark: isDark,
                        ),
                      ],
                    ),
                  ),

                  // 3. قسم العمليات العامة
                  _buildSectionHeader('إدارة الإعدادات العامة', isDark),
                  SolariumGlassContainer(
                    margin: const EdgeInsets.only(bottom: 20.0),
                    padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 4.0),
                    child: Column(
                      children: [
                        // خيار تأكيد حذف المهام
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF59E0B).withOpacity(isDark ? 0.2 : 0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.notifications_active_outlined, color: Color(0xFFF59E0B), size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'تأكيد حذف المهام',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'إظهار نافذة تنبيه لتأكيد الحذف قبل حذف أي مهمة من الجدول',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isDark ? SiyaqColors.darkTextSecondary : const Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Switch.adaptive(
                                value: settings.confirmDeleteTasks,
                                activeColor: SiyaqColors.accentGold,
                                onChanged: (val) {
                                  ref.read(settingsProvider.notifier).setConfirmDeleteTasks(val);
                                  SiyaqToast.show(
                                    context,
                                    val ? 'تم تفعيل تنبيه تأكيد الحذف 🔔' : 'تم تعطيل تنبيه تأكيد الحذف 🔕',
                                    type: SiyaqToastType.info,
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        Divider(height: 1, color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),

                        // فحص التحديثات الجديدة
                        _buildNavTile(
                          context: context,
                          icon: Icons.system_update_rounded,
                          iconColor: SiyaqColors.accentGold,
                          iconBgColor: SiyaqColors.accentGold.withOpacity(isDark ? 0.2 : 0.1),
                          title: 'التحقق من وجود تحديثات',
                          subtitle: 'البحث عن إصدارات أحدث وتثبيتها مباشرة بضغطة زر',
                          trailingWidget: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: SiyaqColors.accentGold.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'فحص 🔄',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                                color: SiyaqColors.accentGold,
                              ),
                            ),
                          ),
                          onTap: () {
                            AppUpdateService.checkForUpdate(context, isManualCheck: true);
                          },
                          isDark: isDark,
                        ),
                        Divider(height: 1, color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),

                        // إعادة ضبط الإعدادات
                        _buildNavTile(
                          context: context,
                          icon: Icons.restore_rounded,
                          iconColor: const Color(0xFFEF4444),
                          iconBgColor: const Color(0xFFEF4444).withOpacity(isDark ? 0.2 : 0.1),
                          title: 'إعادة ضبط الإعدادات',
                          subtitle: 'مسح التفضيلات واستعادة الوضع الافتراضي للتطبيق',
                          trailingWidget: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEF4444).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'إعادة ضبط',
                              style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFFEF4444)),
                            ),
                          ),
                          onTap: () async {
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('إعادة ضبط الإعدادات'),
                                content: const Text('هل أنت متأكد من رغبتك في إعادة ضبط جميع الإعدادات للوضع الافتراضي؟'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('إلغاء')),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444), foregroundColor: Colors.white),
                                    onPressed: () => Navigator.of(ctx).pop(true),
                                    child: const Text('إعادة الضبط'),
                                  ),
                                ],
                              ),
                            );

                            if (confirmed == true) {
                              await ref.read(settingsProvider.notifier).resetSettings();
                              SiyaqToast.show(context, 'تمت استعادة الإعدادات الافتراضية بنجاح! 🔄', type: SiyaqToastType.info);
                            }
                          },
                          isDark: isDark,
                        ),
                      ],
                    ),
                  ),

                  // كارت معلومات التطبيق والحقوق
                  SolariumGlassContainer(
                    padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
                    child: Column(
                      children: [
                        Icon(
                          Icons.auto_awesome_rounded, 
                          color: isDark ? SiyaqColors.accentGold : const Color(0xFFB45309), 
                          size: 32,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'تطبيق ميقاف (Meeqaf)',
                          style: TextStyle(
                            fontWeight: FontWeight.bold, 
                            fontSize: 17,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'الإصدار 2.5.0 • النسخة الفخمة متعددة النماذج',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark ? SiyaqColors.accentGold : const Color(0xFFB45309),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'صُنع بكل حب بواسطة EHABOOO © جميع الحقوق محفوظة',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white70 : const Color(0xFF64748B),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0, right: 4.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 15.5, 
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.white : const Color(0xFF0F172A),
        ),
      ),
    );
  }

  Widget _buildNavTile({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required bool isDark,
    Widget? trailingWidget,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title, 
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? SiyaqColors.darkTextSecondary : const Color(0xFF64748B),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (trailingWidget != null) ...[
              trailingWidget,
              const SizedBox(width: 6),
            ],
            Icon(Icons.arrow_forward_ios_rounded, size: 14, color: isDark ? Colors.white38 : const Color(0xFF94A3B8)),
          ],
        ),
      ),
    );
  }
}
