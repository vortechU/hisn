import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app.dart';
import '../../l10n/app_strings.dart';
import '../../services/backup_io.dart';
import '../../services/backup_service.dart';
import '../../services/custom_dua_service.dart';
import '../../services/favorites_service.dart';
import '../../services/muhassan_service.dart';
import '../../services/quran_service.dart';
import '../../theme/app_theme.dart';
import '../../util/app_navigator.dart';
import '../../widgets/ornament.dart';
import 'settings_common.dart';

/// Backup & restore — writes the user's data out to a file, and reads one back.
///
/// Everything Hisn knows lives on the device and nowhere else, which is the
/// point of it; the cost is that reinstalling the app, or changing phone, would
/// otherwise take a streak and every saved dua with it. This screen is the way
/// out of that.
class BackupSettingsScreen extends StatefulWidget {
  const BackupSettingsScreen({super.key, this.io = const BackupIo()});

  final BackupIo io;

  @override
  State<BackupSettingsScreen> createState() => _BackupSettingsScreenState();
}

class _BackupSettingsScreenState extends State<BackupSettingsScreen> {
  /// Guards against a second tap while a picker or share sheet is already up.
  bool _busy = false;

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _say(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _save() => _run(() async {
        final s = AppStrings.read(context);
        final prefs = context.read<SharedPreferences>();
        // The share sheet anchors to this box on iPad.
        final box = context.findRenderObject() as RenderBox?;
        try {
          await widget.io.share(
            prefs,
            appVersion: kAppVersion,
            origin: box == null
                ? null
                : box.localToGlobal(Offset.zero) & box.size,
          );
        } catch (_) {
          _say(s.backupFailed);
        }
      });

  Future<void> _restore() => _run(() async {
        // Captured before the first await: this screen is torn down by the
        // reload at the end, so nothing may be looked up from its context
        // after the user has picked a file.
        final s = AppStrings.read(context);
        final prefs = context.read<SharedPreferences>();
        final reload = AppReload.of(context).reload;

        final (backup, error) = await widget.io.pick();

        if (error != null) {
          _say(s.restoreError(error));
          return;
        }
        if (backup == null) return; // picker dismissed
        if (!mounted) return;

        final scope = await showModalBottomSheet<BackupScope>(
          context: context,
          showDragHandle: true,
          isScrollControlled: true,
          builder: (_) => RestoreSheet(backup: backup),
        );
        if (scope == null) return;

        final int written;
        try {
          written =
              await const BackupService().restore(prefs, backup, scope: scope);
        } catch (_) {
          // A restore is all-or-nothing, so this really does mean nothing
          // changed — the message can say so without hedging, and there is no
          // need to rebuild the tree over state that never moved.
          _say(s.restoreFailed);
          return;
        }

        // Every service read its state at construction, so the tree has to be
        // rebuilt for the restored values to take. This screen goes with it —
        // hence the message is posted through the new tree's messenger below,
        // not this one's.
        await reload();
        _sayThroughRootNavigator((s) => s.restoreDone(written));
      });

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final theme = Theme.of(context);
    final ms = ManuscriptTheme.of(context);

    // Read live from the services rather than from prefs, so the figures match
    // what the rest of the app is showing this second.
    final muhassan = context.watch<MuhassanService>();
    final quran = context.watch<QuranService>();
    final summary = BackupSummary(
      streak: muhassan.streak,
      bestStreak: muhassan.best,
      fortifiedDays: muhassan.totalFortified,
      favorites: context.watch<FavoritesService>().ids.length,
      customDuas: context.watch<CustomDuaService>().count,
      quranBookmarks: quran.bookmarkCount + quran.verseBookmarkCount,
    );

    return Scaffold(
      appBar: AppBar(title: Text(s.secBackup)),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          SettingsSectionHeader(s.backupOnThisDevice),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Ms.margin),
            child: JadwalFrame(
              child: Column(
                children: [
                  _StatRow(label: s.backupStatStreak, value: summary.streak),
                  _StatRow(label: s.backupStatBest, value: summary.bestStreak),
                  _StatRow(
                      label: s.backupStatDays, value: summary.fortifiedDays),
                  _StatRow(
                      label: s.backupStatFavorites, value: summary.favorites),
                  _StatRow(
                      label: s.backupStatCustom, value: summary.customDuas),
                  _StatRow(
                    label: s.backupStatQuran,
                    value: summary.quranBookmarks,
                    last: true,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          _Action(
            icon: Icons.save_alt,
            label: s.backupSave,
            hint: s.backupSaveHint,
            enabled: !_busy,
            onTap: _save,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(Ms.margin, 12, Ms.margin, 0),
            child: Text(s.backupPrivacy, style: theme.textTheme.bodySmall),
          ),
          const SizedBox(height: 8),
          SettingsSectionHeader(s.backupRestoreHeading),
          _Action(
            icon: Icons.settings_backup_restore,
            label: s.backupRestore,
            hint: s.backupRestoreHint,
            enabled: !_busy,
            accent: ms.rubric,
            onTap: _restore,
          ),
        ],
      ),
    );
  }
}

/// Shows a message on whatever tree is currently mounted.
///
/// A restore replaces the widget tree, taking this screen — and its
/// [ScaffoldMessenger] — with it, so the confirmation has to be posted through
/// the rebuilt app rather than through the caller's own context.
void _sayThroughRootNavigator(String Function(AppStrings) message) {
  final context = appNavigatorKey.currentContext;
  if (context == null) return;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message(AppStrings.read(context)))));
}

/// One "label ......... value" line inside the summary frame.
class _StatRow extends StatelessWidget {
  const _StatRow({required this.label, required this.value, this.last = false});

  final String label;
  final int value;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ms = ManuscriptTheme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: BoxDecoration(
        border: last ? null : Border(bottom: BorderSide(color: ms.rule)),
      ),
      child: Row(
        children: [
          Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
          Text(
            '$value',
            style: theme.textTheme.titleSmall?.copyWith(color: ms.rubric),
          ),
        ],
      ),
    );
  }
}

/// A full-width tappable row: icon, label, and a line explaining what it does.
class _Action extends StatelessWidget {
  const _Action({
    required this.icon,
    required this.label,
    required this.hint,
    required this.enabled,
    required this.onTap,
    this.accent,
  });

  final IconData icon;
  final String label;
  final String hint;
  final bool enabled;
  final VoidCallback onTap;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ms = ManuscriptTheme.of(context);
    final tint = accent ?? ms.gilt;

    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Ms.margin),
        child: JadwalFrame(
          accent: tint,
          onTap: enabled ? onTap : null,
          child: Row(
            children: [
              Icon(icon, size: 20, color: tint),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: theme.textTheme.titleSmall),
                    const SizedBox(height: 2),
                    Text(hint, style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Confirms a restore: what the file holds, and how much of it to write back.
///
/// Shown by [showModalBottomSheet], and popped with the chosen [BackupScope]
/// or null to cancel. Public so the layout test can render it directly — it
/// packs long explanatory lines and a two-button row into a narrow sheet,
/// which is exactly the shape that overflows at a large text scale.
class RestoreSheet extends StatefulWidget {
  const RestoreSheet({super.key, required this.backup});

  final Backup backup;

  @override
  State<RestoreSheet> createState() => _RestoreSheetState();
}

class _RestoreSheetState extends State<RestoreSheet> {
  BackupScope _scope = BackupScope.everything;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final theme = Theme.of(context);
    final ms = ManuscriptTheme.of(context);
    final backup = widget.backup;
    final summary = backup.summary;

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(Ms.margin, 0, Ms.margin, 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(s.restoreTitle,
                        style: theme.textTheme.titleMedium),
                  ),
                  if (backup.createdAt != null) ...[
                    const SizedBox(height: 2),
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: Text(
                        s.restoreSavedOn(backup.createdAt!, backup.appVersion),
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const RuleDivider(indent: Ms.margin),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: Ms.margin),
                children: [
                  const SizedBox(height: 10),
                  JadwalFrame(
                    child: Column(
                      children: [
                        _StatRow(
                            label: s.backupStatStreak, value: summary.streak),
                        _StatRow(
                            label: s.backupStatBest, value: summary.bestStreak),
                        _StatRow(
                            label: s.backupStatDays,
                            value: summary.fortifiedDays),
                        _StatRow(
                            label: s.backupStatFavorites,
                            value: summary.favorites),
                        _StatRow(
                            label: s.backupStatCustom,
                            value: summary.customDuas),
                        _StatRow(
                          label: s.backupStatQuran,
                          value: summary.quranBookmarks,
                          last: true,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  _ScopeOption(
                    label: s.restoreScopeEverything,
                    hint: s.restoreScopeEverythingSub,
                    selected: _scope == BackupScope.everything,
                    onTap: () =>
                        setState(() => _scope = BackupScope.everything),
                  ),
                  _ScopeOption(
                    label: s.restoreScopeProgress,
                    hint: s.restoreScopeProgressSub,
                    selected: _scope == BackupScope.progressOnly,
                    onTap: () =>
                        setState(() => _scope = BackupScope.progressOnly),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.warning_amber_rounded,
                          size: 16, color: ms.rubric),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(s.restoreWarning,
                            style: theme.textTheme.bodySmall),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text(s.cancel),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: () => Navigator.of(context).pop(_scope),
                          child: Text(s.restoreAction),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One of the two restore scopes, marked with the app's rosette when chosen.
class _ScopeOption extends StatelessWidget {
  const _ScopeOption({
    required this.label,
    required this.hint,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String hint;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ms = ManuscriptTheme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: JadwalFrame(
        onTap: onTap,
        emphasis: selected,
        accent: selected ? ms.gilt : null,
        child: Row(
          children: [
            SizedBox(
              width: 22,
              child: selected
                  ? Rosette(size: 16, color: ms.gilt, filled: true)
                  : null,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: theme.textTheme.titleSmall),
                  const SizedBox(height: 2),
                  Text(hint, style: theme.textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
