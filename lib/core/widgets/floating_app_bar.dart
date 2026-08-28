import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'solarium_glass_container.dart';
import 'siyaq_toast.dart';
import '../theme/colors.dart';
import 'avatar_widget.dart';
import '../../features/settings/providers/settings_provider.dart';

class FloatingAppBar extends ConsumerStatefulWidget implements PreferredSizeWidget {
  final Widget? title;
  final Widget? leading;
  final List<Widget>? actions;
  final ScrollController scrollController;
  final bool showBackButton;

  const FloatingAppBar({
    super.key,
    this.title,
    this.leading,
    this.actions,
    required this.scrollController,
    this.showBackButton = false,
  });

  @override
  ConsumerState<FloatingAppBar> createState() => _FloatingAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(80.0);
}

class _FloatingAppBarState extends ConsumerState<FloatingAppBar> {
  bool _isFloating = false;

  @override
  void initState() {
    super.initState();
    widget.scrollController.addListener(_scrollListener);
  }

  @override
  void didUpdateWidget(covariant FloatingAppBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.scrollController != oldWidget.scrollController) {
      oldWidget.scrollController.removeListener(_scrollListener);
      widget.scrollController.addListener(_scrollListener);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          final hasClients = widget.scrollController.hasClients;
          final offset = hasClients ? widget.scrollController.offset : 0.0;
          setState(() {
            _isFloating = offset > 5;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(_scrollListener);
    super.dispose();
  }

  void _scrollListener() {
    if (widget.scrollController.hasClients) {
      final offset = widget.scrollController.offset;
      if (offset > 5 && !_isFloating) {
        setState(() {
          _isFloating = true;
        });
      } else if (offset <= 5 && _isFloating) {
        setState(() {
          _isFloating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statusBarHeight = MediaQuery.of(context).padding.top;
    
    const double targetMargin = 16.0;
    const double targetRadius = 24.0;

    // ودجت الجهة اليسرى (Leading)
    Widget? leadingWidget;
    if (widget.showBackButton) {
      leadingWidget = IconButton(
        icon: Icon(
          Icons.arrow_back_ios_new, 
          size: 20,
          color: isDark ? Colors.white : Colors.black87,
        ),
        onPressed: () => Navigator.of(context).pop(),
      );
    } else {
      leadingWidget = widget.leading ?? const Padding(
        padding: EdgeInsets.only(left: 8.0),
        child: AvatarWidget(size: 36),
      );
    }

    // أزرار الجهة اليمنى (Actions)
    List<Widget> actionWidgets = widget.actions ?? [
      IconButton(
        key: const Key('theme_toggle_button'),
        icon: Icon(
          isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
          color: isDark ? Colors.white70 : Colors.black87,
        ),
        tooltip: isDark ? 'الوضع النهاري' : 'الوضع الليلي',
        onPressed: () {
          final nextMode = isDark ? 'light' : 'dark';
          ref.read(settingsProvider.notifier).setThemeMode(nextMode);
        },
      ),
      IconButton(
        icon: Icon(
          Icons.notifications_none_outlined,
          color: isDark ? Colors.white70 : Colors.black87,
        ),
        onPressed: () {
          SiyaqToast.show(
            context,
            'لا توجد إشعارات جديدة حالياً',
            type: SiyaqToastType.info,
          );
        },
      ),
    ];

    return SizedBox(
      height: 80.0 + statusBarHeight,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: targetMargin, vertical: 4.0),
          child: Align(
            alignment: Alignment.topCenter,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 1080.0),
              child: SolariumGlassContainer(
                borderRadius: targetRadius,
                blur: 24.0,
                padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 16.0),
                child: NavigationToolbar(
                  leading: leadingWidget,
                  middle: widget.title != null
                      ? FittedBox(
                          fit: BoxFit.scaleDown,
                          child: widget.title!,
                        )
                      : const SizedBox.shrink(),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: actionWidgets,
                  ),
                  centerMiddle: true,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
