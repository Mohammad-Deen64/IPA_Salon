import 'package:dr_salon_app/theme/app_colors.dart';
import 'package:dr_salon_app/widgets/salon_bottom_nav.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const customer = [
    SalonNavDestination(icon: Icons.home_outlined, label: 'Home'),
    SalonNavDestination(icon: Icons.calendar_month_outlined, label: 'Bookings'),
    SalonNavDestination(icon: Icons.auto_awesome, label: 'AI Style'),
    SalonNavDestination(icon: Icons.chat_bubble_outline, label: 'Chat'),
    SalonNavDestination(icon: Icons.person_outline, label: 'Profile'),
  ];
  const owner = [
    SalonNavDestination(icon: Icons.dashboard_outlined, label: 'Dashboard'),
    SalonNavDestination(icon: Icons.calendar_month_outlined, label: 'Appointments'),
    SalonNavDestination(icon: Icons.content_cut, label: 'Services'),
    SalonNavDestination(icon: Icons.chat_bubble_outline, label: 'Chat'),
    SalonNavDestination(icon: Icons.person_outline, label: 'Profile'),
  ];

  Future<void> pumpNav(
    WidgetTester tester, {
    required Brightness brightness,
    required List<SalonNavDestination> destinations,
    required int selected,
    required ValueChanged<int> onSelected,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(brightness: brightness),
        home: Scaffold(
          body: const SizedBox.expand(),
          bottomNavigationBar: SalonBottomNav(
            destinations: destinations,
            currentIndex: selected,
            onSelected: onSelected,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Color iconColor(WidgetTester tester, String label) {
    final icon = tester.widget<Icon>(
      find.descendant(of: find.byKey(ValueKey(label)), matching: find.byType(Icon)),
    );
    return icon.color!;
  }

  double labelOpacity(WidgetTester tester, String label) {
    return tester
        .widget<AnimatedOpacity>(
          find.ancestor(of: find.text(label), matching: find.byType(AnimatedOpacity)),
        )
        .opacity;
  }

  for (final brightness in Brightness.values) {
    final inactive = brightness == Brightness.dark ? AppPalette.dark.foreground : AppPalette.light.foreground;

    testWidgets('customer pills expand in $brightness', (tester) async {
      var selected = 0;
      await pumpNav(
        tester,
        brightness: brightness,
        destinations: customer,
        selected: 0,
        onSelected: (value) => selected = value,
      );
      expect(iconColor(tester, 'Home'), Colors.white);
      expect(labelOpacity(tester, 'Home'), 1);
      expect(iconColor(tester, 'Bookings'), inactive);
      expect(labelOpacity(tester, 'Bookings'), 0);

      await tester.tap(find.byKey(const ValueKey('Bookings')));
      expect(selected, 1);
      await tester.tap(find.byKey(const ValueKey('AI Style')));
      expect(selected, 2);
      await tester.tap(find.byKey(const ValueKey('Chat')));
      expect(selected, 3);
      await tester.tap(find.byKey(const ValueKey('Profile')));
      expect(selected, 4);
    });

    testWidgets('owner pills expand in $brightness', (tester) async {
      var selected = 0;
      await pumpNav(
        tester,
        brightness: brightness,
        destinations: owner,
        selected: 0,
        onSelected: (value) => selected = value,
      );
      expect(iconColor(tester, 'Dashboard'), Colors.white);
      expect(labelOpacity(tester, 'Dashboard'), 1);
      expect(iconColor(tester, 'Profile'), inactive);
      expect(labelOpacity(tester, 'Profile'), 0);

      await tester.tap(find.byKey(const ValueKey('Appointments')));
      expect(selected, 1);
      await tester.tap(find.byKey(const ValueKey('Services')));
      expect(selected, 2);
      await tester.tap(find.byKey(const ValueKey('Chat')));
      expect(selected, 3);
      await tester.tap(find.byKey(const ValueKey('Profile')));
      expect(selected, 4);
    });
  }
}
