import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_strings.dart';
import '../../services/adhkar_audio_library.dart';
import '../../services/listen_settings.dart';
import '../../theme/app_theme.dart';
import 'settings_common.dart';

/// How the hands-free recitation behaves.
///
/// Reached only when there is something recorded to listen to — see the
/// Settings hub — so it never offers to configure silence.
class ListenSettingsScreen extends StatelessWidget {
  const ListenSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<ListenSettings>();
    final library = context.read<AdhkarAudioLibrary>();
    final s = AppStrings.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(s.secListen)),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 30),
        children: [
          SettingsSectionHeader(s.listenGap),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Ms.margin),
            child: _Register(
              children: [
                for (var i = 0; i < ListenSettings.gapChoices.length; i++)
                  _Choice(
                    label: s.listenGapLabel(i),
                    selected:
                        settings.gapSteps == ListenSettings.gapChoices[i],
                    onTap: () => context
                        .read<ListenSettings>()
                        .setGapSteps(ListenSettings.gapChoices[i]),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          SwitchListTile(
            secondary: const Icon(Icons.repeat, size: 20),
            title: Text(s.listenAppendix),
            subtitle: Text(s.listenAppendixSub),
            value: settings.includeAppendix,
            onChanged: (value) =>
                context.read<ListenSettings>().setIncludeAppendix(value),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.brightness_high_outlined, size: 20),
            title: Text(s.listenKeepScreenOn),
            subtitle: Text(s.listenKeepScreenOnSub),
            value: settings.keepScreenOn,
            onChanged: (value) =>
                context.read<ListenSettings>().setKeepScreenOn(value),
          ),
          if (library.reciterName.isNotEmpty) ...[
            SettingsSectionHeader(s.listenReciter),
            ListTile(
              leading: const Icon(Icons.record_voice_over_outlined, size: 20),
              title: Text(s.ar && library.reciterNameArabic.isNotEmpty
                  ? library.reciterNameArabic
                  : library.reciterName),
            ),
          ],
        ],
      ),
    );
  }
}

/// A row of mutually exclusive choices inside one frame, split by vertical
/// rules — the same segmented register the Display settings use.
class _Register extends StatelessWidget {
  const _Register({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final ms = ManuscriptTheme.of(context);
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: ms.rule),
        borderRadius: BorderRadius.circular(Ms.rPanel),
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0) VerticalDivider(width: 1, color: ms.rule),
              Expanded(child: children[i]),
            ],
          ],
        ),
      ),
    );
  }
}

class _Choice extends StatelessWidget {
  const _Choice({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ms = ManuscriptTheme.of(context);

    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          child: Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
            decoration: BoxDecoration(
              color: selected ? ms.rubric.withValues(alpha: 0.10) : null,
              border: Border(
                bottom: BorderSide(
                  color: selected ? ms.rubric : Colors.transparent,
                  width: Ms.stroke,
                ),
              ),
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelMedium?.copyWith(
                color: selected ? ms.rubric : theme.colorScheme.onSurface,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
