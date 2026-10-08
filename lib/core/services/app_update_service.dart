import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:ota_update/ota_update.dart';
import '../theme/colors.dart';
import '../widgets/solarium_glass_container.dart';
import '../widgets/siyaq_toast.dart';

class AppUpdateInfo {
  final String version;
  final int buildNumber;
  final String apkUrl;
  final String releaseNotes;
  final bool forceUpdate;

  AppUpdateInfo({
    required this.version,
    required this.buildNumber,
    required this.apkUrl,
    required this.releaseNotes,
    required this.forceUpdate,
  });

  factory AppUpdateInfo.fromJson(Map<String, dynamic> json) {
    return AppUpdateInfo(
      version: json['version'] ?? '1.0.0',
      buildNumber: json['build_number'] ?? 1,
      apkUrl: json['apk_url'] ?? '',
      releaseNotes: json['release_notes'] ?? 'تحديثات وإصلاحات جديدة لتطبيق ميقاف.',
      forceUpdate: json['force_update'] ?? false,
    );
  }
}

class AppUpdateService {
  static const String _primaryConfigUrl =
      'https://raw.githubusercontent.com/ehabzimam10-droid/siyaq/main/version.json';
  static const String _fallbackConfigUrl =
      'https://meeqaf.vercel.app/version.json';

  static bool _hasCheckedThisSession = false;

  /// فحص توفر تحديث جديد لتطبيق ميقاف
  static Future<void> checkForUpdate(
    BuildContext context, {
    bool isManualCheck = false,
  }) async {
    // التحديث عبر الـ APK مخصص لنظام الأندرويد فقط
    if (kIsWeb || !Platform.isAndroid) {
      if (isManualCheck && context.mounted) {
        SiyaqToast.show(
          context,
          'أنت تستخدم نسخة الويب المباشرة، تتحدث تلقائياً مع كل دخول! ✨',
          type: SiyaqToastType.info,
        );
      }
      return;
    }

    if (!isManualCheck && _hasCheckedThisSession) {
      return;
    }
    _hasCheckedThisSession = true;

    try {
      final updateInfo = await _fetchRemoteVersion();
      if (updateInfo == null) {
        if (isManualCheck && context.mounted) {
          SiyaqToast.show(
            context,
            'تعذر التحقق من خادم التحديثات حالياً. تأكد من اتصالك بالإنترنت.',
            type: SiyaqToastType.error,
          );
        }
        return;
      }

      final packageInfo = await PackageInfo.fromPlatform();
      final currentBuild = int.tryParse(packageInfo.buildNumber) ?? 1;

      // مقارنة رقم البناء البرمجي
      if (updateInfo.buildNumber > currentBuild) {
        if (context.mounted) {
          showDialog(
            context: context,
            barrierDismissible: !updateInfo.forceUpdate,
            builder: (ctx) => _AppUpdateDialog(
              currentVersion: packageInfo.version,
              updateInfo: updateInfo,
            ),
          );
        }
      } else {
        if (isManualCheck && context.mounted) {
          SiyaqToast.show(
            context,
            'أنت تستخدم أحدث إصدار من ميقاف (v${packageInfo.version}) ✨',
            type: SiyaqToastType.success,
          );
        }
      }
    } catch (e) {
      debugPrint('AppUpdateService error: $e');
      if (isManualCheck && context.mounted) {
        SiyaqToast.show(
          context,
          'حدث خطأ أثناء فحص التحديثات.',
          type: SiyaqToastType.error,
        );
      }
    }
  }

  static Future<AppUpdateInfo?> _fetchRemoteVersion() async {
    try {
      // 1. محاولة الرابط الرئيسي من GitHub
      final response = await http
          .get(Uri.parse(_primaryConfigUrl))
          .timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return AppUpdateInfo.fromJson(data);
      }
    } catch (_) {}

    try {
      // 2. محاولة الرابط البديل من Vercel
      final response = await http
          .get(Uri.parse(_fallbackConfigUrl))
          .timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return AppUpdateInfo.fromJson(data);
      }
    } catch (_) {}

    return null;
  }
}

class _AppUpdateDialog extends StatefulWidget {
  final String currentVersion;
  final AppUpdateInfo updateInfo;

  const _AppUpdateDialog({
    required this.currentVersion,
    required this.updateInfo,
  });

  @override
  State<_AppUpdateDialog> createState() => _AppUpdateDialogState();
}

class _AppUpdateDialogState extends State<_AppUpdateDialog> {
  bool _isDownloading = false;
  int _downloadProgress = 0;
  String _statusText = '';
  String? _errorMessage;

  void _startOtaUpdate() {
    if (widget.updateInfo.apkUrl.isEmpty) {
      setState(() {
        _errorMessage = 'رابط تحميل ملف التحديث غير متوفر حالياً.';
      });
      return;
    }

    setState(() {
      _isDownloading = true;
      _downloadProgress = 0;
      _statusText = 'بدء تحميل حزمة التحديث...';
      _errorMessage = null;
    });

    try {
      OtaUpdate()
          .execute(
        widget.updateInfo.apkUrl,
        destinationFilename: 'Meeqaf.apk',
      )
          .listen(
        (OtaEvent event) {
          if (!mounted) return;
          switch (event.status) {
            case OtaStatus.DOWNLOADING:
              setState(() {
                _downloadProgress = int.tryParse(event.value ?? '0') ?? 0;
                _statusText = 'جارٍ تحميل التحديث: $_downloadProgress%';
              });
              break;
            case OtaStatus.INSTALLING:
              setState(() {
                _statusText = 'اكتمل التحميل! جارٍ فتح مثبت الحزم... 🚀';
                _isDownloading = false;
              });
              break;
            case OtaStatus.ALREADY_RUNNING_ERROR:
              setState(() {
                _isDownloading = false;
                _errorMessage = 'عملية التحديث قيد التنفيذ بالفعل.';
              });
              break;
            case OtaStatus.PERMISSION_NOT_GRANTED_ERROR:
              setState(() {
                _isDownloading = false;
                _errorMessage =
                    'يرجى منح إذن تثبيت التطبيقات غير المعروفة لمتابعة التحديث.';
              });
              break;
            case OtaStatus.INTERNAL_ERROR:
            case OtaStatus.DOWNLOAD_ERROR:
            case OtaStatus.CHECKSUM_ERROR:
            default:
              setState(() {
                _isDownloading = false;
                _errorMessage =
                    'تعذر إكمال التحديث تلقائياً (${event.status.name}).';
              });
              break;
          }
        },
        onError: (err) {
          if (!mounted) return;
          setState(() {
            _isDownloading = false;
            _errorMessage = 'حدث خطأ أثناء تحميل التحديث: $err';
          });
        },
      );
    } catch (e) {
      setState(() {
        _isDownloading = false;
        _errorMessage = 'تعذر تشغيل التحديث: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: !widget.updateInfo.forceUpdate && !_isDownloading,
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: SolariumGlassContainer(
          borderRadius: 28,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. أيقونة التحديث الفخمة
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      SiyaqColors.accentGold.withOpacity(0.25),
                      SiyaqColors.accentGoldDark.withOpacity(0.10),
                    ],
                  ),
                  border: Border.all(
                    color: SiyaqColors.accentGold.withOpacity(0.5),
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  Icons.system_update_alt_rounded,
                  color: isDark ? SiyaqColors.accentGold : const Color(0xFFB45309),
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),

              // 2. العنوان
              Text(
                'تحديث جديد متوفر لميقاف ✨',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),

              // 3. شارة الإصدارات
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: (isDark ? SiyaqColors.accentGold : const Color(0xFFB45309))
                      .withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'v${widget.currentVersion} ➔ v${widget.updateInfo.version}',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: isDark ? SiyaqColors.accentGold : const Color(0xFFB45309),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 4. ملاحظات التحديث
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.03),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? Colors.white10 : Colors.black12,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ما الجديد في هذا الإصدار:',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white70 : const Color(0xFF334155),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.updateInfo.releaseNotes,
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.45,
                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 5. شريط التقدم أثناء التحميل
              if (_isDownloading) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: _downloadProgress > 0 ? _downloadProgress / 100.0 : null,
                    minHeight: 8,
                    backgroundColor: isDark ? Colors.white12 : Colors.black12,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isDark ? SiyaqColors.accentGold : const Color(0xFFD97706),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  _statusText,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isDark ? SiyaqColors.accentGold : const Color(0xFFB45309),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 14),
              ],

              // 6. رسالة الخطأ إن وُجدت
              if (_errorMessage != null) ...[
                Text(
                  _errorMessage!,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFFEF4444),
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 14),
              ],

              // 7. الأزرار
              Row(
                children: [
                  if (!widget.updateInfo.forceUpdate && !_isDownloading) ...[
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          'لاحقاً',
                          style: TextStyle(
                            color: isDark ? Colors.white60 : const Color(0xFF64748B),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _isDownloading ? null : _startOtaUpdate,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            isDark ? SiyaqColors.accentGold : const Color(0xFFD97706),
                        foregroundColor:
                            isDark ? const Color(0xFF0F172A) : Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        _isDownloading ? 'جارٍ التحميل...' : 'تحديث وتثبيت الآن 🚀',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
