import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/floating_app_bar.dart';
import '../../../core/widgets/floating_bottom_bar.dart';
import '../../../core/widgets/fluid_background.dart';
import '../../../core/widgets/fluid_theme_transition.dart';
import '../../../core/widgets/liquid_orb_fab.dart';
import '../../dashboard/screens/dashboard_screen.dart';
import '../../calendar/screens/calendar_screen.dart';
import '../../assistant/screens/assistant_screen.dart';
import '../../settings/screens/settings_screen.dart';
import '../../settings/providers/settings_provider.dart';
import '../../dashboard/providers/schedule_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  final int initialIndex;
  const HomeScreen({super.key, this.initialIndex = 0});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }
  
  // وحدات التحكم بالتمرير لكل شاشة لتعديل الشريط العلوي ديناميكياً
  final List<ScrollController> _scrollControllers = [
    ScrollController(), // Dashboard
    ScrollController(), // Calendar
    ScrollController(), // Assistant
    ScrollController(), // Settings
  ];

  @override
  void dispose() {
    for (var controller in _scrollControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Widget _buildActiveScreen() {
    switch (_currentIndex) {
      case 0:
        return DashboardScreen(scrollController: _scrollControllers[0]);
      case 1:
        return CalendarScreen(scrollController: _scrollControllers[1]);
      case 2:
        return AssistantScreen(scrollController: _scrollControllers[2]);
      case 3:
        return SettingsScreen(scrollController: _scrollControllers[3]);
      default:
        return DashboardScreen(scrollController: _scrollControllers[0]);
    }
  }

  Widget _buildAppBarTitle() {
    switch (_currentIndex) {
      case 0:
        return const Text(
          'سياق • اليومي',
          style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold),
        );
      case 1:
        return const Text(
          'تقويم سياق',
          style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold),
        );
      case 2:
        return const Text(
          'سياق AI',
          style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold),
        );
      case 3:
        return const Text(
          'الإعدادات',
          style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold),
        );
      default:
        return const Text('سياق');
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedDate = ref.watch(selectedDateProvider);
    
    final currentThemeMode = switch (settings.themeMode) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };

    return FluidThemeTransition(
      themeMode: currentThemeMode,
      child: FluidBackground(
        isDark: isDark,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          extendBody: true,
          body: Stack(
            children: [
              _buildActiveScreen(),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: FloatingAppBar(
                  title: _buildAppBarTitle(),
                  scrollController: _scrollControllers[_currentIndex],
                ),
              ),
              // الزر العائم السائل القابل للسحب والتحريك (يظهر فقط في صفحة التقويم)
              if (_currentIndex == 1)
                LiquidDraggableFab(initialDate: selectedDate),
            ],
          ),
          bottomNavigationBar: FloatingBottomBar(
            selectedIndex: _currentIndex,
            items: [
              FloatingBottomBarItem(icon: Icons.grid_view_rounded, label: 'الرئيسية'),
              FloatingBottomBarItem(icon: Icons.calendar_month_rounded, label: 'التقويم'),
              FloatingBottomBarItem(icon: Icons.assistant_rounded, label: 'المساعد'),
              FloatingBottomBarItem(icon: Icons.settings_rounded, label: 'الإعدادات'),
            ],
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
          ),
        ),
      ),
    );
  }
}
