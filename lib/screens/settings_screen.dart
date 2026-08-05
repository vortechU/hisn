import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_strings.dart';
import '../services/prayer_service.dart';
import '../services/prayer_settings.dart';
import '../services/theme_controller.dart';
import 'settings/about_settings_screen.dart';
import 'settings/appearance_settings_screen.dart';
import 'settings/display_settings_screen.dart';
import 'settings/language_settings_screen.dart';
import 'settings/notifications_settings_screen.dart';
import 'settings/prayer_times_settings_screen.dart';

/// Settings hub — one tile per category, each opening its own screen.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  String _locationSubtitle(PrayerService service, AppStrings s) {
    if (service.locationMode == LocationMode.gps) {
      return service.usingDeviceLocation
          ? s.locYourLocationGps
          : s.locDeviceGps(s.place(service.locationLabel));
    }
    return s.locFixedCity(s.place(service.locationLabel));
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<PrayerService>();
    final theme = context.watch<ThemeController>();
    final s = AppStrings.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(s.settings)),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          _CategoryTile(
            icon: Icons.access_time,
            title: s.secPrayerTimes,
            subtitle: _locationSubtitle(service, s),
            screenBuilder: (_) => const PrayerTimesSettingsScreen(),
          ),
          _CategoryTile(
            icon: Icons.notifications_active_outlined,
            title: s.notifications,
            subtitle: s.prayerRemindersSub,
            screenBuilder: (_) => const NotificationsSettingsScreen(),
          ),
          _CategoryTile(
            icon: Icons.palette_outlined,
            title: s.secAppearance,
            subtitle: s.paletteName(theme.palette.id),
            screenBuilder: (_) => const AppearanceSettingsScreen(),
          ),
          _CategoryTile(
            icon: Icons.text_fields,
            title: s.secDisplay,
            subtitle: s.textSize,
            screenBuilder: (_) => const DisplaySettingsScreen(),
          ),
          _CategoryTile(
            icon: Icons.language,
            title: s.secLanguage,
            subtitle: s.currentLanguage,
            screenBuilder: (_) => const LanguageSettingsScreen(),
          ),
          _CategoryTile(
            icon: Icons.info_outline,
            title: s.secAbout,
            subtitle: 'v$kAppVersion',
            screenBuilder: (_) => const AboutSettingsScreen(),
          ),
        ],
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.screenBuilder,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final WidgetBuilder screenBuilder;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(icon, color: theme.colorScheme.primary),
      title: Text(title),
      subtitle: Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: screenBuilder),
      ),
    );
  }
}
