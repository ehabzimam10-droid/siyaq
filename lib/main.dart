import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/theme/theme.dart';
import 'features/home/screens/home_screen.dart';
import 'features/settings/providers/settings_provider.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

void main() async {
  // التأكد من تهيئة الـ bindings قبل أي شيء
  WidgetsFlutterBinding.ensureInitialized();
  
  if (kIsWeb) {
    usePathUrlStrategy();
    // تفعيل شجرة الـ Semantics لتصدير الأزرار والتفاعلات لمتصفحات الاختبار الذكية (TestSprite)
    RendererBinding.instance.ensureSemantics();
  }
  
  // تهيئة تنسيق التاريخ للغة العربية
  await initializeDateFormatting('ar', null);
  
  runApp(
    // تغليف التطبيق بالـ ProviderScope لتشغيل Riverpod
    const ProviderScope(
      child: SiyaqApp(),
    ),
  );
}

class SiyaqApp extends ConsumerWidget {
  const SiyaqApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    
    final themeMode = switch (settings.themeMode) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };

    return MaterialApp(
      title: 'سياق',
      debugShowCheckedModeBanner: false,
      
      // إعدادات التوطين واللغة العربية
      locale: const Locale('ar'),
      supportedLocales: const [
        Locale('ar'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      
      // ربط الثيمات للوضعين الداكن والفاتح
      theme: SiyaqTheme.lightTheme,
      darkTheme: SiyaqTheme.darkTheme,
      themeMode: themeMode, // يتكيف مع خيار المستخدم
      
      onGenerateRoute: (settingsRoute) {
        int initialIndex = 0;
        final name = settingsRoute.name ?? '/';
        if (name.contains('calendar')) initialIndex = 1;
        if (name.contains('assistant')) initialIndex = 2;
        if (name.contains('settings')) initialIndex = 3;
        return MaterialPageRoute(
          settings: settingsRoute,
          builder: (context) => HomeScreen(initialIndex: initialIndex),
        );
      },
    );
  }
}
