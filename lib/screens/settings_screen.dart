import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_strings.dart';
import '../services/adhkar_audio_library.dart';
import '../services/prayer_service.dart';
import '../services/prayer_settings.dart';
import '../services/theme_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/ornament.dart';
import 'settings/about_settings_screen.dart';
import 'settings/appearance_settings_screen.dart';
import 'settings/backup_settings_screen.dart';
import 'settings/display_settings_screen.dart';
import 'settings/language_settings_screen.dart';
import 'settings/listen_settings_screen.dart';
import 'settings/notifications_settings_screen.dart';
import 'settings/prayer_times_settings_screen.dart';
import 'sunnah_calendar_screen.dart';

/// Settings hub — one ruled entry per section, each opening its own screen.
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
    final ms = ManuscriptTheme.of(context);
    final s = AppStrings.of(context);

    final entries = <_Entry>[
      _Entry(Icons.schedule_outlined, s.secPrayerTimes,
          _locationSubtitle(service, s), (_) => const PrayerTimesSettingsScreen()),
      _Entry(Icons.notifications_none, s.notifications, s.prayerRemindersSub,
          (_) => const NotificationsSettingsScreen()),
      _Entry(Icons.calendar_month_outlined, s.secCalendar, s.calendarSub,
          (_) => const SunnahCalendarScreen()),
      _Entry(Icons.palette_outlined, s.secAppearance,
          s.paletteName(theme.palette.id), (_) => const AppearanceSettingsScreen()),
      _Entry(Icons.format_size, s.secDisplay, s.textSize,
          (_) => const DisplaySettingsScreen()),
      // Only when something is recorded — otherwise this section would settle
      // the behaviour of a feature the build doesn't have.
      if (context.read<AdhkarAudioLibrary>().hasAnyAudio)
        _Entry(Icons.headset_outlined, s.secListen, s.listenSub,
            (_) => const ListenSettingsScreen()),
      _Entry(Icons.translate_outlined, s.secLanguage, s.currentLanguage,
          (_) => const LanguageSettingsScreen()),
      _Entry(Icons.backup_outlined, s.secBackup, s.backupSub,
          (_) => const BackupSettingsScreen()),
      _Entry(Icons.info_outline, s.secAbout, 'v$kAppVersion',
          (_) => const AboutSettingsScreen()),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(s.settings)),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 28),
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(Ms.margin, 6, Ms.margin, 0),
            decoration: BoxDecoration(
              border: Border.all(color: ms.rule),
              borderRadius: BorderRadius.circular(Ms.rPanel),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (var i = 0; i < entries.length; i++)
                  _SettingsRow(entry: entries[i], first: i == 0),
              ],
            ),
          ),
          const RuleDivider(indent: Ms.margin),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Ms.margin),
            child: Text(
              s.appName,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _Entry {
  const _Entry(this.icon, this.title, this.subtitle, this.builder);
  final IconData icon;
  final String title;
  final String subtitle;
  final WidgetBuilder builder;
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({required this.entry, required this.first});

  final _Entry entry;
  final bool first;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ms = ManuscriptTheme.of(context);

    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: () => Navigator.of(context)
            .push(MaterialPageRoute(builder: entry.builder)),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            border:
                first ? null : Border(top: BorderSide(color: ms.rule)),
          ),
          child: Row(
            children: [
              Icon(entry.icon, size: 20, color: ms.rubric),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(entry.title, style: theme.textTheme.titleSmall),
                    const SizedBox(height: 1),
                    Text(
                      entry.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Directionality.of(context) == TextDirection.rtl
                    ? Icons.chevron_left
                    : Icons.chevron_right,
                size: 18,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
