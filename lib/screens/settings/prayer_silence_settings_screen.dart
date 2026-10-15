import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_strings.dart';
import '../../services/prayer_silence_settings.dart';
import 'settings_common.dart';

class PrayerSilenceSettingsScreen extends StatefulWidget {
  const PrayerSilenceSettingsScreen({super.key});

  @override
  State<PrayerSilenceSettingsScreen> createState() =>
      _PrayerSilenceSettingsScreenState();
}

class _PrayerSilenceSettingsScreenState
    extends State<PrayerSilenceSettingsScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<PrayerSilenceSettings>().refreshStatus();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      context.read<PrayerSilenceSettings>().refreshStatus();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  String _status(PrayerSilenceSettings settings, AppStrings s) {
    final end = settings.activeUntil;
    return switch (settings.reason) {
      'disabled' => s.prayerSilenceDisabled,
      'permission' => s.prayerSilencePermission,
      'exactAlarm' => s.prayerSilenceExact,
      'location' => s.prayerSilenceLocation,
      'waiting' => s.prayerSilenceWaiting,
      'ruleDisabled' => s.prayerSilenceRuleDisabled,
      'unsupported' => s.prayerSilenceUnavailable,
      'ready' => s.prayerSilenceReady,
      'active' when end != null => s.prayerSilenceActiveUntil(
        MaterialLocalizations.of(context).formatTimeOfDay(
          TimeOfDay.fromDateTime(end),
          alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
        ),
      ),
      _ => s.prayerSilenceError,
    };
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<PrayerSilenceSettings>();
    final s = AppStrings.of(context);
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: Text(s.prayerSilenceTitle)),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Text(s.prayerSilenceBody, style: textTheme.bodyMedium),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.notifications_paused_outlined),
            title: Text(s.prayerSilenceEnable),
            value: settings.enabled,
            onChanged: settings.supported ? settings.setEnabled : null,
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(_status(settings, s)),
          ),
          if (settings.enabled && settings.supported) ...[
            if (!settings.policyGranted || settings.reason == 'ruleDisabled')
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                child: OutlinedButton(
                  onPressed: settings.openPolicySettings,
                  child: Text(s.prayerSilencePolicyButton),
                ),
              ),
            if (!settings.exactAllowed)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                child: OutlinedButton(
                  onPressed: settings.openExactAlarmSettings,
                  child: Text(s.prayerSilenceExactButton),
                ),
              ),
            if (settings.activeUntil != null || settings.reason == 'waiting')
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                child: OutlinedButton.icon(
                  onPressed: settings.skipCurrentWindow,
                  icon: const Icon(Icons.volume_up_outlined),
                  label: Text(s.prayerSilenceStopNow),
                ),
              ),
          ],
          const Divider(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(s.prayerSilenceTimingHint, style: textTheme.bodyMedium),
          ),
          for (final prayer in PrayerSilenceSettings.prayers) ...[
            SwitchListTile(
              title: Text(s.prayerName(prayer)),
              value: settings.windowFor(prayer).enabled,
              onChanged: settings.supported
                  ? (value) => settings.setWindow(
                      prayer,
                      settings.windowFor(prayer).copyWith(enabled: value),
                    )
                  : null,
            ),
            if (settings.windowFor(prayer).enabled)
              Padding(
                padding: const EdgeInsetsDirectional.only(
                  start: 16,
                  end: 16,
                  bottom: 16,
                ),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    OutlinedButton(
                      onPressed: settings.supported
                          ? () => _pick(prayer, start: true)
                          : null,
                      child: Text(
                        '${s.prayerSilenceStart}: ${s.prayerSilenceMinutes(settings.windowFor(prayer).startMinutes)}',
                      ),
                    ),
                    OutlinedButton(
                      onPressed: settings.supported
                          ? () => _pick(prayer, start: false)
                          : null,
                      child: Text(
                        '${s.prayerSilenceEnd}: ${s.prayerSilenceMinutes(settings.windowFor(prayer).endMinutes)}',
                      ),
                    ),
                  ],
                ),
              ),
          ],
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: Text(s.prayerSilenceExpiryNote, style: textTheme.bodySmall),
          ),
        ],
      ),
    );
  }

  Future<void> _pick(Prayer prayer, {required bool start}) async {
    final settings = context.read<PrayerSilenceSettings>();
    final s = AppStrings.of(context);
    final window = settings.windowFor(prayer);
    final options =
        <int>{
              for (var i = 0; i <= 180; i += 5) i,
              window.startMinutes,
              window.endMinutes,
            }
            .where(
              (i) => start ? i < window.endMinutes : i > window.startMinutes,
            )
            .toList()
          ..sort();
    final value = await showSettingsPicker<int>(
      context: context,
      title:
          '${s.prayerName(prayer)} · ${start ? s.prayerSilenceStart : s.prayerSilenceEnd}',
      options: options,
      current: start ? window.startMinutes : window.endMinutes,
      labelOf: s.prayerSilenceMinutes,
    );
    if (value != null) {
      final current = settings.windowFor(prayer);
      await settings.setWindow(
        prayer,
        start
            ? current.copyWith(startMinutes: value)
            : current.copyWith(endMinutes: value),
      );
    }
  }
}
