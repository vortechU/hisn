import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import 'adhkar_screen.dart';
import 'prayer_qibla_screen.dart';
import 'quran_screen.dart';
import 'settings_screen.dart';

/// Root scaffold holding the four primary tabs. Tasbih and Saved are reached
/// from inside the Adhkar tab; Qibla lives in the combined Prayer & Qibla tab.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  static const _tabs = [
    AdhkarScreen(),
    QuranScreen(),
    PrayerQiblaScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return Scaffold(
      body: IndexedStack(index: _index, children: _tabs),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
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
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings),
            label: s.navSettings,
          ),
        ],
      ),
    );
  }
}
