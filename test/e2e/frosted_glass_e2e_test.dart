import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:siyaq/core/widgets/floating_app_bar.dart';
import 'package:siyaq/core/widgets/solarium_glass_container.dart';
import 'package:siyaq/features/dashboard/screens/dashboard_screen.dart';
import 'helpers/test_helper.dart';

void main() {
  setUpAll(() async {
    await initTestLocale();
  });

  group('Frosted Glass Effect E2E Tests', () {
    // ==========================================
    // Tier 1 - Feature Coverage
    // ==========================================

    testWidgets('T1.F3.1: Verify FloatingAppBar utilizes a BackdropFilter widget', (WidgetTester tester) async {
      final controller = ScrollController();
      await tester.pumpWidget(
        createTestableWidget(
          Scaffold(
            appBar: FloatingAppBar(scrollController: controller),
            body: ListView(
              controller: controller,
              children: const [SizedBox(height: 1000)],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final backdropFilter = find.descendant(
        of: find.byType(FloatingAppBar),
        matching: find.byType(BackdropFilter),
      );
      expect(backdropFilter, findsOneWidget);
    });

    testWidgets('T1.F3.2: BackdropFilter has sigmaX and sigmaY blur values matching the target state', (WidgetTester tester) async {
      final controller = ScrollController();
      await tester.pumpWidget(
        createTestableWidget(
          Scaffold(
            appBar: FloatingAppBar(scrollController: controller),
            body: ListView(
              controller: controller,
              children: const [SizedBox(height: 1000)],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Scrolled state
      controller.jumpTo(10.0);
      await tester.pump(); // Trigger setState in scroll listener
      await tester.pumpAndSettle(); // Settle the AnimatedContainer animation

      final backdropFilterFinder = find.descendant(
        of: find.byType(FloatingAppBar),
        matching: find.byType(BackdropFilter),
      );
      final backdropFilter = tester.widget<BackdropFilter>(backdropFilterFinder);
      expect(backdropFilter.filter.toString(), contains('25.0'));
    });

    testWidgets('T1.F3.3: Scroll offset at 0.0 results in zero blur (completely transparent/no glass style)', (WidgetTester tester) async {
      final controller = ScrollController();
      await tester.pumpWidget(
        createTestableWidget(
          Scaffold(
            appBar: FloatingAppBar(scrollController: controller),
            body: ListView(
              controller: controller,
              children: const [SizedBox(height: 1000)],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final glassContainerFinder = find.descendant(
        of: find.byType(FloatingAppBar),
        matching: find.byType(SolariumGlassContainer),
      );
      final glassContainer = tester.widget<SolariumGlassContainer>(glassContainerFinder);
      expect(glassContainer.blur, equals(0.0));
      expect(glassContainer.customBgColor, equals(Colors.transparent));
    });

    testWidgets('T1.F3.4: Scroll offset greater than 5.0 results in non-zero blur (glass style active)', (WidgetTester tester) async {
      final controller = ScrollController();
      await tester.pumpWidget(
        createTestableWidget(
          Scaffold(
            appBar: FloatingAppBar(scrollController: controller),
            body: ListView(
              controller: controller,
              children: const [SizedBox(height: 1000)],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Scroll to 10.0 (> 5.0)
      controller.jumpTo(10.0);
      await tester.pump();
      await tester.pumpAndSettle();

      final glassContainerFinder = find.descendant(
        of: find.byType(FloatingAppBar),
        matching: find.byType(SolariumGlassContainer),
      );
      final glassContainer = tester.widget<SolariumGlassContainer>(glassContainerFinder);
      expect(glassContainer.blur, equals(25.0));
      expect(glassContainer.customBgColor, isNull); // Default glass background applied
    });

    testWidgets('T1.F3.5: FloatingAppBar remains interactive and visible under blurred states', (WidgetTester tester) async {
      final controller = ScrollController();
      bool tapped = false;
      await tester.pumpWidget(
        createTestableWidget(
          Scaffold(
            appBar: FloatingAppBar(
              scrollController: controller,
              actions: [
                IconButton(
                  key: const Key('app_bar_action_btn'),
                  icon: const Icon(Icons.star),
                  onPressed: () {
                    tapped = true;
                  },
                ),
              ],
            ),
            body: ListView(
              controller: controller,
              children: const [SizedBox(height: 1000)],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Scroll to activate blur
      controller.jumpTo(20.0);
      await tester.pump();
      await tester.pumpAndSettle();

      final actionBtn = find.byKey(const Key('app_bar_action_btn'));
      expect(actionBtn, findsOneWidget);
      await tester.tap(actionBtn);
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });

    // ==========================================
    // Tier 2 - Boundary & Corner Cases
    // ==========================================

    testWidgets('T2.F3.1: Scroll offset exactly at the transition boundary (5.0) behaves deterministically', (WidgetTester tester) async {
      final controller = ScrollController();
      await tester.pumpWidget(
        createTestableWidget(
          Scaffold(
            appBar: FloatingAppBar(scrollController: controller),
            body: ListView(
              controller: controller,
              children: const [SizedBox(height: 1000)],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Offset 5.0 is exactly at boundary (offset > 5 for floating) -> should remain non-floating
      controller.jumpTo(5.0);
      await tester.pump();
      await tester.pumpAndSettle();

      var glassContainerFinder = find.descendant(
        of: find.byType(FloatingAppBar),
        matching: find.byType(SolariumGlassContainer),
      );
      expect(tester.widget<SolariumGlassContainer>(glassContainerFinder).blur, equals(0.0));

      // Offset 5.1 is past boundary -> should change to floating
      controller.jumpTo(5.1);
      await tester.pump();
      await tester.pumpAndSettle();

      glassContainerFinder = find.descendant(
        of: find.byType(FloatingAppBar),
        matching: find.byType(SolariumGlassContainer),
      );
      expect(tester.widget<SolariumGlassContainer>(glassContainerFinder).blur, equals(25.0));
    });

    testWidgets('T2.F3.2: Scroll offset at extremely high values (e.g. 5000.0) clamps blur and does not overflow or crash', (WidgetTester tester) async {
      final controller = ScrollController();
      await tester.pumpWidget(
        createTestableWidget(
          Scaffold(
            appBar: FloatingAppBar(scrollController: controller),
            body: ListView(
              controller: controller,
              children: const [SizedBox(height: 10000)],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      controller.jumpTo(5000.0);
      await tester.pump();
      await tester.pumpAndSettle();

      final glassContainerFinder = find.descendant(
        of: find.byType(FloatingAppBar),
        matching: find.byType(SolariumGlassContainer),
      );
      final glassContainer = tester.widget<SolariumGlassContainer>(glassContainerFinder);
      expect(glassContainer.blur, equals(25.0)); // Should remain capped at 25.0
      expect(tester.takeException(), isNull);
    });

    testWidgets('T2.F3.3: Rapid scrolling up and down updates the glass background blur smoothly', (WidgetTester tester) async {
      final controller = ScrollController();
      await tester.pumpWidget(
        createTestableWidget(
          Scaffold(
            appBar: FloatingAppBar(scrollController: controller),
            body: ListView(
              controller: controller,
              children: const [SizedBox(height: 2000)],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Alternate offsets rapidly
      for (int i = 0; i < 10; i++) {
        controller.jumpTo(i % 2 == 0 ? 20.0 : 0.0);
        await tester.pump();
      }
      await tester.pumpAndSettle();
      
      expect(tester.takeException(), isNull);
    });

    testWidgets('T2.F3.4: A completely empty non-scrollable list keeps the frosted glass effect disabled', (WidgetTester tester) async {
      final controller = ScrollController();
      await tester.pumpWidget(
        createTestableWidget(
          Scaffold(
            appBar: FloatingAppBar(scrollController: controller),
            body: ListView(
              controller: controller,
              children: const [], // Non-scrollable list
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final glassContainerFinder = find.descendant(
        of: find.byType(FloatingAppBar),
        matching: find.byType(SolariumGlassContainer),
      );
      final glassContainer = tester.widget<SolariumGlassContainer>(glassContainerFinder);
      expect(glassContainer.blur, equals(0.0));
    });

    testWidgets('T2.F3.5: Resize or screen orientation changes update FloatingAppBar margins without breaking layout', (WidgetTester tester) async {
      final controller = ScrollController();
      await tester.pumpWidget(
        createTestableWidget(
          Scaffold(
            appBar: FloatingAppBar(scrollController: controller),
            body: ListView(
              controller: controller,
              children: const [SizedBox(height: 1000)],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Change dimensions to landscape simulation
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      await tester.pumpAndSettle();

      final appBarFinder = find.byType(FloatingAppBar);
      expect(appBarFinder, findsOneWidget);
      expect(tester.takeException(), isNull);

      // Reset tester dimensions
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  });
}
