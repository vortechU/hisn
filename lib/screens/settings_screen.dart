import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_strings.dart';
import '../services/adhkar_audio_library.dart';
import '../services/feature_tour_controller.dart';
import '../services/prayer_service.dart';
import '../services/prayer_settings.dart';
import '../services/theme_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/ornament.dart';
import '../widgets/feature_tour_anchor.dart';
import 'settings/about_settings_screen.dart';
import 'settings/appearance_settings_screen.dart';
import 'settings/backup_settings_screen.dart';
import 'settings/display_settings_screen.dart';
import 'settings/language_settings_screen.dart';
import 'settings/listen_settings_screen.dart';
import 'settings/notifications_settings_screen.dart';
import 'settings/prayer_times_settings_screen.dart';
import 'sunnah_calendar_screen.dart';

/// Settings hub — one row per section, each opening its own screen, on one
/// group; the app guide stands apart in a group of its own.
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
      _Entry(
        Icons.schedule_outlined,
        s.secPrayerTimes,
        _locationSubtitle(service, s),
        (_) => const PrayerTimesSettingsScreen(),
      ),
      _Entry(
        Icons.notifications_none,
        s.notifications,
        s.prayerRemindersSub,
        (_) => const NotificationsSettingsScreen(),
      ),
      _Entry(
        Icons.calendar_month_outlined,
        s.secCalendar,
        s.calendarSub,
        (_) => const SunnahCalendarScreen(),
      ),
      _Entry(
        Icons.palette_outlined,
        s.secAppearance,
        s.paletteName(theme.palette.id),
        (_) => const AppearanceSettingsScreen(),
      ),
      _Entry(
        Icons.format_size,
        s.secDisplay,
        s.textSize,
        (_) => const DisplaySettingsScreen(),
      ),
      // Only when something is recorded — otherwise this section would settle
      // the behaviour of a feature the build doesn't have.
      if (context.read<AdhkarAudioLibrary>().hasAnyAudio)
        _Entry(
          Icons.headset_outlined,
          s.secListen,
          s.listenSub,
          (_) => const ListenSettingsScreen(),
        ),
      _Entry(
        Icons.translate_outlined,
        s.secLanguage,
        s.currentLanguage,
        (_) => const LanguageSettingsScreen(),
      ),
      _Entry(
        Icons.backup_outlined,
        s.secBackup,
        s.backupSub,
        (_) => const BackupSettingsScreen(),
      ),
      _Entry(
        Icons.info_outline,
        s.secAbout,
        'v$kAppVersion',
        (_) => const AboutSettingsScreen(),
      ),
    ];

    final tour = context.read<FeatureTourController?>();

    return Scaffold(
      appBar: AppBar(title: Text(s.settings)),
      // Eager rather than lazy: the list is short, and the guide row at its
      // foot has to exist for the tour to scroll to it on a small screen.
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(Ms.margin, 6, Ms.margin, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            RowGroup(
              children: [
                for (var i = 0; i < entries.length; i++)
                  if (i == 1)
                    FeatureTourAnchor(
                      target: FeatureTourTarget.notifications,
                      child: _SettingsRow(entry: entries[i]),
                    )
                  else
                    _SettingsRow(entry: entries[i]),
              ],
            ),
            if (tour != null) ...[
              const SizedBox(height: 14),
              RowGroup(
                children: [
                  _SettingsRow(
                    key: const ValueKey('replay_feature_guide'),
                    entry: _Entry(
                      Icons.help_outline,
                      s.replayGuide,
                      s.replayGuideSub,
                      null,
                    ),
                    onTap: tour.start,
                  ),
                ],
              ),
            ],
            const SizedBox(height: 28),
            Text(
              s.appName,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: ms.rubric.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Entry {
  const _Entry(this.icon, this.title, this.subtitle, this.builder);
  final IconData icon;
  final String title;
  final String subtitle;
  final WidgetBuilder? builder;
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({super.key, required this.entry, this.onTap});

  final _Entry entry;

  /// Overrides opening [_Entry.builder].
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap:
          onTap ??
          () => Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: entry.builder!)),
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(16, 14, 12, 14),
        child: Row(
          children: [
            IconWell(icon: entry.icon),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(entry.title, style: theme.textTheme.titleSmall),
                  const SizedBox(height: 2),
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
              size: 20,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}
