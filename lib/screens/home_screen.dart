import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../theme/app_theme.dart';
import 'adhkar_screen.dart';
import 'prayer_qibla_screen.dart';
import 'quran_screen.dart';
import 'settings_screen.dart';

/// Root scaffold holding the four primary tabs. Tasbih and Saved are reached
/// from the toolbar inside the Adhkar tab; Qibla lives in the combined Prayer
/// & Qibla tab.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  static const tabAdhkar = 0;
  static const tabQuran = 1;
  static const tabPrayer = 2;
  static const tabSettings = 3;

  /// Which primary tab is showing.
  ///
  /// Held outside the state because a home-screen widget can ask for a tab from
  /// outside the widget tree entirely — see `WidgetRoutes`. Everything that
  /// changes tabs, including the navigation bar itself, goes through here, so
  /// there is only ever one answer to which tab is current.
  static final ValueNotifier<int> tab = ValueNotifier<int>(tabAdhkar);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = HomeScreen.tab.value;

  static const _tabs = [
    AdhkarScreen(),
    QuranScreen(),
    PrayerQiblaScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    HomeScreen.tab.addListener(_onTabChanged);
  }

  @override
  void dispose() {
    HomeScreen.tab.removeListener(_onTabChanged);
    super.dispose();
  }

  void _onTabChanged() {
    if (mounted) setState(() => _index = HomeScreen.tab.value);
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final ms = ManuscriptTheme.of(context);

    return Scaffold(
      body: IndexedStack(index: _index, children: _tabs),
      // A ruled edge rather than a shadow, so the bar reads as the foot of the
      // page it sits under.
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: ms.rule)),
        ),
        child: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) => HomeScreen.tab.value = i,
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.menu_book_outlined),
              selectedIcon: const Icon(Icons.menu_book),
              label: s.navAdhkar,
            ),
            NavigationDestination(
              icon: const Icon(Icons.auto_stories_outlined),
              selectedIcon: const Icon(Icons.auto_stories),
              label: s.navQuran,
            ),
            NavigationDestination(
              icon: const Icon(Icons.mosque_outlined),
              selectedIcon: const Icon(Icons.mosque),
              label: s.navPrayer,
            ),
            NavigationDestination(
              icon: const Icon(Icons.tune_outlined),
              selectedIcon: const Icon(Icons.tune),
              label: s.navSettings,
            ),
          ],
        ),
      ),
    );
  }
}
