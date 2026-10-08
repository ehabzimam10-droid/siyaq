import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/widgets/floating_app_bar.dart';
import '../../../core/widgets/floating_bottom_bar.dart';
import '../../../core/widgets/fluid_background.dart';
import '../../../core/widgets/fluid_theme_transition.dart';
import '../../../core/widgets/liquid_orb_fab.dart';
import '../../../core/services/app_update_service.dart';
import '../../dashboard/screens/dashboard_screen.dart';
import '../../calendar/screens/calendar_screen.dart';
import '../../assistant/screens/assistant_screen.dart';
import '../../settings/screens/settings_screen.dart';
import '../../settings/providers/settings_provider.dart';
import '../../dashboard/providers/schedule_provider.dart';
import '../../dashboard/widgets/task_addition_sheet.dart';

class HomeScreen extends ConsumerStatefulWidget {
  final int initialIndex;
  const HomeScreen({super.key, this.initialIndex = 0});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late int _currentIndex;
  Offset? _fabPosition;
  bool _isFabDragging = false;
  double _fabDragDistance = 0;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _restoreActiveTab();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        AppUpdateService.checkForUpdate(context);
      }
    });
  }

  // فتح ورقة إضافة المهمة
  void _openTaskSheet(BuildContext context, DateTime date) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        return TaskAdditionSheet(
          initialDate: date,
          allowedTaskType: 'single_date',
        );
      },
    );
  }

  // استعادة التبويب النشط بعد إعادة تحميل أو تحديث الصفحة
  Future<void> _restoreActiveTab() async {
    try {
      final uri = Uri.base;
      if (uri.hasFragment && uri.fragment.isNotEmpty) {
        final fragment = uri.fragment.toLowerCase();
        if (fragment.contains('calendar') || fragment.contains('تقويم')) {
          if (mounted) setState(() => _currentIndex = 1);
          return;
        } else if (fragment.contains('assistant') || fragment.contains('ai') || fragment.contains('مساعد')) {
          if (mounted) setState(() => _currentIndex = 2);
          return;
        } else if (fragment.contains('settings') || fragment.contains('إعدادات')) {
          if (mounted) setState(() => _currentIndex = 3);
          return;
        } else if (fragment.contains('home') || fragment.contains('dashboard') || fragment.contains('رئيسية')) {
          if (mounted) setState(() => _currentIndex = 0);
          return;
        }
      }

      final prefs = await SharedPreferences.getInstance();
      final savedTab = prefs.getInt('meeqaf_active_tab_index');
      if (savedTab != null && savedTab >= 0 && savedTab <= 3 && mounted) {
        setState(() {
          _currentIndex = savedTab;
        });
      }
    } catch (_) {}
  }

  void _onTabChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
    SharedPreferences.getInstance().then((prefs) {
      prefs.setInt('meeqaf_active_tab_index', index);
    });
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
          'ميقاف • اليومي',
          style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold),
        );
      case 1:
        return const Text(
          'تقويم ميقاف',
          style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold),
        );
      case 2:
        return const Text(
          'ميقاف AI',
          style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold),
        );
      case 3:
        return const Text(
          'الإعدادات',
          style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold),
        );
      default:
        return const Text('ميقاف');
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
          body: LayoutBuilder(
            builder: (context, constraints) {
              final screenWidth = constraints.maxWidth;
              final screenHeight = constraints.maxHeight;
              const fabSize = 58.0;

              // حدود الأمان: تمنع الخروج عن الشاشة أو الدخول تحت الشريط العلوي أو السفلي
              final minX = 16.0;
              final maxX = math.max(minX, screenWidth - fabSize - 16.0);
              final minY = 80.0; // أسفل الشريط العلوي
              final maxY = math.max(minY, screenHeight - 95.0 - fabSize); // أعلى الشريط السفلي

              // الموضع المبدئي: أسفل يمين الشاشة (فوق الشريط السفلي)
              final defaultPos = Offset(maxX - 8.0, maxY - 8.0);
              final curX = (_fabPosition?.dx ?? defaultPos.dx).clamp(minX, maxX);
              final curY = (_fabPosition?.dy ?? defaultPos.dy).clamp(minY, maxY);
              final clampedPos = Offset(curX, curY);

              return Stack(
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
                  // الزر العائم السائل: كعنصر Positioned مباشر داخل الـ Stack لضمان الاستجابة التامة لكافة الاتجاهات
                  if (_currentIndex == 0 || _currentIndex == 1)
                    Positioned(
                      left: clampedPos.dx,
                      top: clampedPos.dy,
                      child: LiquidDraggableFab(
                        key: const PageStorageKey('liquid_fab'),
                        initialDate: selectedDate,
                        fabSize: fabSize,
                        isDragging: _isFabDragging,
                        onPanStart: (_) {
                          _fabDragDistance = 0;
                          setState(() {
                            _isFabDragging = true;
                            _fabPosition = clampedPos;
                          });
                        },
                        onPanUpdate: (details) {
                          _fabDragDistance += details.delta.distance;
                          final nextX = (clampedPos.dx + details.delta.dx).clamp(minX, maxX);
                          final nextY = (clampedPos.dy + details.delta.dy).clamp(minY, maxY);
                          setState(() {
                            _fabPosition = Offset(nextX, nextY);
                          });
                        },
                        onPanEnd: (_) {
                          final wasDragging = _isFabDragging;
                          setState(() {
                            _isFabDragging = false;
                          });
                          if (wasDragging && _fabDragDistance < 8) {
                            _openTaskSheet(context, selectedDate);
                          }
                        },
                        onTap: () {
                          _openTaskSheet(context, selectedDate);
                        },
                      ),
                    ),
                ],
              );
            },
          ),
          bottomNavigationBar: FloatingBottomBar(
            selectedIndex: _currentIndex,
            items: [
              FloatingBottomBarItem(icon: Icons.grid_view_rounded, label: 'الرئيسية'),
              FloatingBottomBarItem(icon: Icons.calendar_month_rounded, label: 'التقويم'),
              FloatingBottomBarItem(icon: Icons.assistant_rounded, label: 'المساعد'),
              FloatingBottomBarItem(icon: Icons.settings_rounded, label: 'الإعدادات'),
            ],
            onTap: _onTabChanged,
          ),
        ),
      ),
    );
  }
}
