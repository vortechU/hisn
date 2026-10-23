import 'package:adhan/adhan.dart';
import 'package:file_selector/file_selector.dart' show openFile;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_strings.dart';
import '../../services/adhan_audio.dart';
import '../../services/notification_service.dart';
import '../../services/prayer_countdown_settings.dart';
import '../../services/prayer_silence_settings.dart';
import '../../services/sunnah_calendar_service.dart';
import 'prayer_silence_settings_screen.dart';
import 'settings_common.dart';

/// All notification settings: prayer-time reminders, the daily-remembrance
/// bundle, and the adhan sound.
class NotificationsSettingsScreen extends StatelessWidget {
  const NotificationsSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final notifications = context.watch<NotificationService>();
    final adhan = context.watch<AdhanAudioService>();
    final calendar = context.watch<SunnahCalendarService>();
    final s = AppStrings.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(s.notifications)),
      body: ListView(
        children: [
          const _PrayerFeatures(),
          SettingsSectionHeader(s.prayerReminders),
          SwitchListTile(
            secondary: const Icon(Icons.notifications_active_outlined),
            title: Text(s.prayerReminders),
            subtitle: Text(s.prayerRemindersSub),
            value: notifications.masterEnabled,
            onChanged: (value) =>
                context.read<NotificationService>().setMasterEnabled(value),
          ),
          if (notifications.permissionDenied &&
              (notifications.masterEnabled ||
                  notifications.dailyRemembranceEnabled))
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    size: 18,
                    color: theme.colorScheme.error,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      s.notifBlocked,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (notifications.masterEnabled)
            for (final prayer in NotificationService.notifiablePrayers)
              SwitchListTile(
                contentPadding: const EdgeInsetsDirectional.only(
                  start: 32,
                  end: 12,
                ),
                dense: true,
                title: Text(s.prayerName(prayer)),
                subtitle: notifications.isPrayerEnabled(prayer)
                    ? _IqamahOffsetPicker(prayer: prayer)
                    : null,
                value: notifications.isPrayerEnabled(prayer),
                onChanged: (value) => context
                    .read<NotificationService>()
                    .setPrayerEnabled(prayer, value),
              ),
          if (notifications.masterEnabled) ...[
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(72, 4, 16, 0),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final enabled = await context
                        .read<NotificationService>()
                        .sendTestNotification();
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context)
                      ..hideCurrentSnackBar()
                      ..showSnackBar(
                        SnackBar(
                          duration: const Duration(seconds: 6),
                          content: Text(
                            enabled == false ? s.testBlocked : s.testSent,
                          ),
                        ),
                      );
                  },
                  icon: const Icon(Icons.notifications_active_outlined),
                  label: Text(s.sendTestNotif),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.battery_alert_outlined,
                    size: 18,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      s.batteryHint,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const Divider(height: 24),
          SettingsSectionHeader(s.dailyRemembrance),
          // One switch for the whole remembrance bundle (morning/evening adhkar
          // repeating until done, Friday Al-Kahf + salawat, nightly Al-Mulk).
          SwitchListTile(
            secondary: const Icon(Icons.menu_book_outlined),
            title: Text(s.dailyRemembrance),
            subtitle: Text(s.dailyRemembranceSub),
            isThreeLine: true,
            value: notifications.dailyRemembranceEnabled,
            onChanged: (value) =>
                context.read<NotificationService>().setDailyRemembrance(value),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.nights_stay_outlined),
            title: Text(s.fastingReminders),
            subtitle: Text(s.fastingRemindersSub),
            value: calendar.remindersEnabled,
            onChanged: (value) async {
              await context.read<SunnahCalendarService>().setRemindersEnabled(
                value,
              );
              if (!context.mounted) return;
              // The calendar service doesn't own the scheduler, so ask for the
              // window to be rebuilt now rather than at the next launch.
              await context.read<NotificationService>().reschedule();
            },
          ),
          const Divider(height: 24),
          SettingsSectionHeader(s.adhanSound),
          SwitchListTile(
            secondary: const Icon(Icons.volume_up_outlined),
            title: Text(s.adhanSound),
            subtitle: Text(s.adhanSoundSub),
            value: adhan.enabled,
            onChanged: (value) =>
                context.read<AdhanAudioService>().setEnabled(value),
          ),
          if (adhan.enabled) ...[
            const _ExactAlarmsWarning(),
            if (!notifications.masterEnabled)
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(72, 0, 16, 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 18,
                      color: theme.colorScheme.tertiary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        s.adhanNeedsReminders,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.tertiary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const _AdhanVoiceTile(),
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(72, 0, 16, 4),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  s.adhanVolume,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(72, 0, 16, 0),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Wrap(
                  spacing: 8,
                  children: [
                    for (var i = 0; i < AdhanVolumeStream.values.length; i++)
                      ChoiceChip(
                        label: Text(s.streamLabel(i)),
                        selected: adhan.stream == AdhanVolumeStream.values[i],
                        onSelected: (_) => context
                            .read<AdhanAudioService>()
                            .setStream(AdhanVolumeStream.values[i]),
                      ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(72, 6, 16, 0),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  s.streamHint(adhan.stream.index),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(72, 10, 16, 8),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: FilledButton.tonalIcon(
                  onPressed: () async {
                    final svc = context.read<AdhanAudioService>();
                    if (adhan.isPlaying) {
                      await svc.stop();
                    } else if (!await svc.playPreview() && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(s.adhanVoiceNotPlayable)),
                      );
                    }
                  },
                  icon: Icon(adhan.isPlaying ? Icons.stop : Icons.play_arrow),
                  label: Text(adhan.isPlaying ? s.stopAdhan : s.previewAdhan),
                ),
              ),
            ),
            SwitchListTile(
              secondary: const Icon(Icons.screen_rotation_alt_outlined),
              title: Text(s.adhanFlipToSilence),
              subtitle: Text(s.adhanFlipToSilenceSub),
              isThreeLine: true,
              value: adhan.flipToSilence,
              onChanged: (value) =>
                  context.read<AdhanAudioService>().setFlipToSilence(value),
            ),
          ],
        ],
      ),
    );
  }
}

/// Which recording plays at prayer time: one of the bundled voices, or a file
/// the user imports. Opens a sheet; importing a file selects it and plays it
/// straight away, so the user hears at once whether it's the one they meant.
class _AdhanVoiceTile extends StatelessWidget {
  const _AdhanVoiceTile();

  static const _pickFile = '\u0000pick';

  static String _label(AppStrings s, AdhanAudioService adhan, String id) =>
      switch (id) {
        AdhanAudioService.customVoiceId =>
          adhan.customFileName ?? s.adhanVoiceCustom,
        _ => s.adhanVoiceDefault,
      };

  @override
  Widget build(BuildContext context) {
    final adhan = context.watch<AdhanAudioService>();
    final s = AppStrings.of(context);
    return ListTile(
      leading: const Icon(Icons.record_voice_over_outlined),
      title: Text(s.adhanVoice),
      subtitle: Text(
        _label(s, adhan, adhan.effectiveVoiceId),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _open(context),
    );
  }

  Future<void> _open(BuildContext context) async {
    final adhan = context.read<AdhanAudioService>();
    final s = AppStrings.of(context);
    final current = adhan.effectiveVoiceId;
    final hasFile = adhan.customFilePath != null;
    final choice = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    s.adhanVoice,
                    style: Theme.of(sheetContext).textTheme.titleSmall,
                  ),
                ),
              ),
              for (final voice in AdhanAudioService.bundledVoices)
                ListTile(
                  title: Text(_label(s, adhan, voice.id)),
                  trailing: voice.id == current
                      ? const Icon(Icons.check)
                      : null,
                  onTap: () => Navigator.of(sheetContext).pop(voice.id),
                ),
              if (hasFile)
                ListTile(
                  title: Text(s.adhanVoiceCustom),
                  subtitle: Text(
                    '${adhan.customFileName ?? ''}\n${s.adhanVoiceCustomHint}',
                  ),
                  isThreeLine: true,
                  trailing: current == AdhanAudioService.customVoiceId
                      ? const Icon(Icons.check)
                      : null,
                  onTap: () => Navigator.of(
                    sheetContext,
                  ).pop(AdhanAudioService.customVoiceId),
                ),
              ListTile(
                leading: const Icon(Icons.audio_file_outlined),
                title: Text(
                  hasFile ? s.adhanVoiceChangeFile : s.adhanVoiceChooseFile,
                ),
                subtitle: hasFile ? null : Text(s.adhanVoiceCustomHint),
                onTap: () => Navigator.of(sheetContext).pop(_pickFile),
              ),
            ],
          ),
        ),
      ),
    );
    if (choice == null || !context.mounted) return;
    if (choice != _pickFile) {
      await adhan.setVoice(choice);
      return;
    }

    // No type filter, for the reason given in BackupIo.pick: Android reports
    // MIME types inconsistently by source, and a wrong guess hides the file.
    final file = await openFile();
    if (file == null || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final result = await adhan.importCustom(file);
    switch (result) {
      case CustomAdhanResult.unreadable:
        messenger.showSnackBar(SnackBar(content: Text(s.adhanVoiceUnreadable)));
      case CustomAdhanResult.tooLarge:
        messenger.showSnackBar(SnackBar(content: Text(s.adhanVoiceTooLarge)));
      case CustomAdhanResult.imported:
        if (!await adhan.playPreview()) {
          // Not audio after all: go back to what played before.
          await adhan.setVoice(current);
          messenger.showSnackBar(
            SnackBar(content: Text(s.adhanVoiceNotPlayable)),
          );
        }
    }
  }
}

class _PrayerFeatures extends StatelessWidget {
  const _PrayerFeatures();

  @override
  Widget build(BuildContext context) {
    final countdown = context.watch<PrayerCountdownSettings>();
    final silence = context.watch<PrayerSilenceSettings>();
    final s = AppStrings.of(context);
    return Column(
      children: [
        SettingsSectionHeader(s.prayerCountdownTitle),
        SwitchListTile(
          secondary: const Icon(Icons.timer_outlined),
          title: Text(s.prayerCountdownTitle),
          subtitle: Text(
            countdown.supported
                ? countdown.enabled && countdown.notificationsAllowed == false
                      ? s.notifBlocked
                      : s.prayerCountdownSubtitle
                : s.prayerCountdownUnavailable,
          ),
          value: countdown.enabled,
          onChanged: countdown.supported
              ? (value) async {
                  final notifications = context.read<NotificationService>();
                  if (value &&
                      !await notifications.requestDisplayPermission()) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text(s.notifBlocked)));
                    return;
                  }
                  await countdown.setEnabled(value);
                }
              : null,
        ),
        ListTile(
          leading: const Icon(Icons.do_not_disturb_on_outlined),
          title: Text(s.prayerSilenceTitle),
          subtitle: Text(
            silence.supported ? s.prayerSilenceSub : s.prayerSilenceUnavailable,
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const PrayerSilenceSettingsScreen(),
            ),
          ),
        ),
        const Divider(height: 24),
      ],
    );
  }
}

/// Warns, under the adhan switch, when the OS won't let the app set exact
/// alarms — without them the adhan can't start at prayer time — and links to
/// the system setting. Checks again whenever the user comes back to the app,
/// since that setting lives outside it.
class _ExactAlarmsWarning extends StatefulWidget {
  const _ExactAlarmsWarning();

  @override
  State<_ExactAlarmsWarning> createState() => _ExactAlarmsWarningState();
}

class _ExactAlarmsWarningState extends State<_ExactAlarmsWarning>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    context.read<NotificationService>().checkExactAlarms();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      context.read<NotificationService>().checkExactAlarms();
    }
  }

  @override
  Widget build(BuildContext context) {
    final allowed = context.select<NotificationService, bool>(
      (n) => n.exactAlarmsAllowed,
    );
    if (allowed) return const SizedBox.shrink();
    final s = AppStrings.of(context);
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(72, 0, 16, 8),
      child: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            size: 18,
            color: theme.colorScheme.error,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              s.adhanExactAlarmsOff,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ),
          TextButton(
            onPressed: () =>
                context.read<NotificationService>().requestExactAlarms(),
            child: Text(s.allowAlarms),
          ),
        ],
      ),
    );
  }
}

/// A small tappable label under a prayer's switch, showing the reminder's
/// delay after adhan ("At adhan" / "+15 min") and opening a picker on tap.
/// The delay only shifts the reminder notification — the adhan audio (if on)
/// still plays at the real prayer time.
class _IqamahOffsetPicker extends StatelessWidget {
  const _IqamahOffsetPicker({required this.prayer});

  final Prayer prayer;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final theme = Theme.of(context);
    final notifications = context.watch<NotificationService>();
    final offset = notifications.iqamahOffset(prayer);

    return InkWell(
      borderRadius: BorderRadius.circular(6),
      onTap: () => _pick(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.timer_outlined,
              size: 14,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 4),
            Text(
              s.iqamahOffsetValue(offset),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pick(BuildContext context) async {
    final notifications = context.read<NotificationService>();
    final s = AppStrings.of(context);
    final selected = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  '${s.prayerName(prayer)} · ${s.iqamahOffset}',
                  style: Theme.of(sheetContext).textTheme.titleSmall,
                ),
              ),
            ),
            for (final minutes in NotificationService.iqamahOffsetChoices)
              ListTile(
                title: Text(s.iqamahOffsetValue(minutes)),
                trailing: minutes == notifications.iqamahOffset(prayer)
                    ? const Icon(Icons.check)
                    : null,
                onTap: () => Navigator.of(sheetContext).pop(minutes),
              ),
          ],
        ),
      ),
    );
    if (selected != null) {
      await notifications.setIqamahOffset(prayer, selected);
    }
  }
}
