import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:intl/src/date_format_internal.dart';
import 'package:intl/number_symbols_data.dart';
import 'package:intl/number_symbols.dart';
import 'package:siyaq/core/services/prayer_service.dart';
import 'package:siyaq/core/models/prayer_times.dart';
import 'package:siyaq/features/dashboard/providers/schedule_provider.dart';

class MockPrayerService implements PrayerService {
  @override
  Future<PrayerTimes> getPrayerTimes(DateTime date) async {
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

class MockSelectedDateNotifier extends SelectedDateNotifier {
  final DateTime initialDate;
  MockSelectedDateNotifier(this.initialDate);

  @override
  DateTime build() => initialDate;
}

Widget createTestableWidget(Widget child, {List<dynamic> overrides = const []}) {
  return ProviderScope(
    overrides: [
      prayerServiceProvider.overrideWith((ref) => MockPrayerService()),
      ...overrides,
    ],
    child: MaterialApp(
      locale: const Locale('ar'),
      supportedLocales: const [
        Locale('ar'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: child,
    ),
  );
}

Future<void> initTestLocale() async {
  await initializeDateFormatting('ar', null);
  dateTimeSymbols['ar'].ZERODIGIT = '0';
  
  numberFormatSymbols.forEach((key, value) {
    if (key.toString().startsWith('ar')) {
      final sym = value as NumberSymbols;
      if (sym.ZERO_DIGIT != '0') {
        numberFormatSymbols[key] = NumberSymbols(
          NAME: sym.NAME,
          DECIMAL_SEP: sym.DECIMAL_SEP,
          GROUP_SEP: sym.GROUP_SEP,
          PERCENT: sym.PERCENT,
          ZERO_DIGIT: '0',
          PLUS_SIGN: sym.PLUS_SIGN,
          MINUS_SIGN: sym.MINUS_SIGN,
          EXP_SYMBOL: sym.EXP_SYMBOL,
          PERMILL: sym.PERMILL,
          INFINITY: sym.INFINITY,
          NAN: sym.NAN,
          DECIMAL_PATTERN: sym.DECIMAL_PATTERN,
          SCIENTIFIC_PATTERN: sym.SCIENTIFIC_PATTERN,
          PERCENT_PATTERN: sym.PERCENT_PATTERN,
          CURRENCY_PATTERN: sym.CURRENCY_PATTERN,
          DEF_CURRENCY_CODE: sym.DEF_CURRENCY_CODE,
        );
      }
    }
  });
}
