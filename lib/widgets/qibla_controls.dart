import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../services/qibla_preferences.dart';
import '../theme/app_theme.dart';

/// Compact, wrapping native menus: settings stay beside their visible effect.
class QiblaControls extends StatelessWidget {
  const QiblaControls({
    super.key,
    required this.style,
    required this.tone,
    required this.vibration,
    required this.onStyle,
    required this.onTone,
    required this.onVibration,
  });

  final QiblaDialStyle style;
  final QiblaDialTone tone;
  final bool vibration;
  final ValueChanged<QiblaDialStyle> onStyle;
  final ValueChanged<QiblaDialTone> onTone;
  final ValueChanged<bool> onVibration;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final styleName = s.qiblaStyle;
    final toneName = s.qiblaTone;
    final vibrationOn = s.qiblaVibrationOn;
    final vibrationOff = s.qiblaVibrationOff;
    final styles = s.qiblaStyles;
    final tones = s.qiblaTones;
    final theme = Theme.of(context);
    final ms = ManuscriptTheme.of(context);
    final colors = [ms.rubric, ms.gilt, theme.colorScheme.onSurface];
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 4,
      children: [
        PopupMenuButton<QiblaDialStyle>(
          tooltip: styleName,
          initialValue: style,
          onSelected: onStyle,
          itemBuilder: (_) => [
            for (final value in QiblaDialStyle.values)
              PopupMenuItem(value: value, child: Text(styles[value.index])),
          ],
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.explore_outlined, size: 18),
                const SizedBox(width: 6),
                Flexible(child: Text(styles[style.index])),
                const Icon(Icons.expand_more, size: 18),
              ],
            ),
          ),
        ),
        PopupMenuButton<QiblaDialTone>(
          tooltip: toneName,
          initialValue: tone,
          onSelected: onTone,
          itemBuilder: (_) => [
            for (final value in QiblaDialTone.values)
              PopupMenuItem(value: value, child: Text(tones[value.index])),
          ],
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.circle, size: 14, color: colors[tone.index]),
                const SizedBox(width: 6),
                Flexible(child: Text(tones[tone.index])),
                const Icon(Icons.expand_more, size: 18),
              ],
            ),
          ),
        ),
        IconButton(
          tooltip: vibration ? vibrationOn : vibrationOff,
          isSelected: vibration,
          onPressed: () => onVibration(!vibration),
          icon: const Icon(Icons.vibration_outlined, size: 20),
          selectedIcon: const Icon(Icons.vibration, size: 20),
        ),
      ],
    );
  }
}
