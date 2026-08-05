import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_strings.dart';
import '../../services/adhan_audio.dart';
import '../../services/notification_service.dart';
import 'settings_common.dart';

/// All notification settings: prayer-time reminders, the daily-remembrance
/// bundle, and the adhan sound.
class NotificationsSettingsScreen extends StatelessWidget {
  const NotificationsSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final notifications = context.watch<NotificationService>();
    final adhan = context.watch<AdhanAudioService>();
    final s = AppStrings.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(s.notifications)),
      body: ListView(
        children: [
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
                  Icon(Icons.warning_amber_rounded,
                      size: 18, color: theme.colorScheme.error),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      s.notifBlocked,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.colorScheme.error),
                    ),
                  ),
                ],
              ),
            ),
          if (notifications.masterEnabled)
            for (final prayer in NotificationService.notifiablePrayers)
              SwitchListTile(
                contentPadding:
                    const EdgeInsetsDirectional.only(start: 32, end: 12),
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
                      ..showSnackBar(SnackBar(
                          duration: const Duration(seconds: 6),
                          content: Text(
                              enabled == false ? s.testBlocked : s.testSent)));
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
                  Icon(Icons.battery_alert_outlined,
                      size: 18, color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(s.batteryHint,
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant)),
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
            secondary: const Icon(Icons.auto_awesome_outlined),
            title: Text(s.dailyRemembrance),
            subtitle: Text(s.dailyRemembranceSub),
            isThreeLine: true,
            value: notifications.dailyRemembranceEnabled,
            onChanged: (value) =>
                context.read<NotificationService>().setDailyRemembrance(value),
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
            if (!notifications.masterEnabled)
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(72, 0, 16, 8),
                child: Row(
                  children: [
                    Icon(Icons.info_outline,
                        size: 18, color: theme.colorScheme.tertiary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(s.adhanNeedsReminders,
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: theme.colorScheme.tertiary)),
                    ),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(72, 0, 16, 4),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(s.adhanVolume,
                    style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant)),
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
                child: Text(s.streamHint(adhan.stream.index),
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant)),
              ),
            ),
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(72, 10, 16, 8),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: FilledButton.tonalIcon(
                  onPressed: () {
                    final svc = context.read<AdhanAudioService>();
                    if (adhan.isPlaying) {
                      svc.stop();
                    } else {
                      svc.playPreview();
                    }
                  },
                  icon: Icon(adhan.isPlaying ? Icons.stop : Icons.play_arrow),
                  label: Text(adhan.isPlaying ? s.stopAdhan : s.previewAdhan),
                ),
              ),
            ),
          ],
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
            Icon(Icons.timer_outlined,
                size: 14, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: 4),
            Text(s.iqamahOffsetValue(offset),
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
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
                child: Text('${s.prayerName(prayer)} · ${s.iqamahOffset}',
                    style: Theme.of(sheetContext).textTheme.titleSmall),
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
