import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_strings.dart';
import '../../services/display_settings.dart';
import '../../theme/app_theme.dart';
import '../../theme/arabic_fonts.dart';
import '../../theme/reading_theme.dart';
import '../../widgets/ornament.dart';
import 'settings_common.dart';

/// Reading display options: text size, Arabic font, reading background,
/// transliteration, and translation.
///
/// The font and reading-surface choices are shown as specimens rather than as
/// names — you pick a typeface by looking at it, not by reading its label.
class DisplaySettingsScreen extends StatelessWidget {
  const DisplaySettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final display = context.watch<DisplaySettings>();
    final s = AppStrings.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(s.secDisplay)),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 30),
        children: [
          SettingsSectionHeader(s.textSize),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Ms.margin),
            child: _Register(
              children: [
                for (var i = 0;
                    i < DisplaySettings.fontScaleSteps.length;
                    i++)
                  _Choice(
                    label: s.fontScaleLabels[i],
                    selected:
                        display.fontScale == DisplaySettings.fontScaleSteps[i],
                    onTap: () => context
                        .read<DisplaySettings>()
                        .setFontScale(DisplaySettings.fontScaleSteps[i]),
                  ),
              ],
            ),
          ),
          SettingsSectionHeader(s.arabicFont),
          for (final font in ArabicFonts.all)
            _FontSpecimen(
              font: font,
              selected: display.arabicFontId == font.id,
              onTap: () =>
                  context.read<DisplaySettings>().setArabicFont(font.id),
            ),
          SettingsSectionHeader(s.readingTheme),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Ms.margin),
            child: _Register(
              children: [
                for (final rt in ReadingTheme.values)
                  _Choice(
                    label: _readingLabel(s, rt),
                    selected: display.readingTheme == rt,
                    onTap: () =>
                        context.read<DisplaySettings>().setReadingTheme(rt),
                  ),
              ],
            ),
          ),
          // Both lines are hidden outright in an Arabic interface (see
          // [DuaCard]), so their switches would be controls that change
          // nothing. The stored values are left untouched and come back with
          // the setting if the reader switches language again.
          if (!s.ar) ...[
            const SizedBox(height: 8),
            SwitchListTile(
              secondary: const Icon(Icons.translate, size: 20),
              title: Text(s.showTransliteration),
              subtitle: Text(s.showTransliterationSub),
              value: display.showTransliteration,
              onChanged: (value) =>
                  context.read<DisplaySettings>().setShowTransliteration(value),
            ),
            SwitchListTile(
              secondary: const Icon(Icons.subtitles_outlined, size: 20),
              title: Text(s.showTranslation),
              subtitle: Text(s.showTranslationSub),
              value: display.showTranslation,
              onChanged: (value) =>
                  context.read<DisplaySettings>().setShowTranslation(value),
            ),
          ],
        ],
      ),
    );
  }
}

String _readingLabel(AppStrings s, ReadingTheme theme) {
  switch (theme) {
    case ReadingTheme.system:
      return s.readingSystem;
    case ReadingTheme.sepia:
      return s.readingSepia;
    case ReadingTheme.night:
      return s.readingNight;
  }
}

/// A row of mutually exclusive choices inside one frame, split by vertical
/// rules — a segmented register rather than a scatter of pills.
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

/// An Arabic typeface shown as a specimen: the basmalah set in that face, with
/// its name in the apparatus below.
class _FontSpecimen extends StatelessWidget {
  const _FontSpecimen({
    required this.font,
    required this.selected,
    required this.onTap,
  });

  final ArabicFontOption font;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ms = ManuscriptTheme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(Ms.margin, 0, Ms.margin, 10),
      child: Semantics(
        selected: selected,
        button: true,
        child: JadwalFrame(
          onTap: onTap,
          accent: selected ? ms.rubric : null,
          emphasis: selected,
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 11),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Directionality(
                textDirection: TextDirection.rtl,
                child: Text(
                  'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: font.family,
                    fontSize: 25,
                    height: 1.75,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      font.family.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall,
                    ),
                  ),
                  if (selected) ...[
                    const SizedBox(width: 8),
                    Rosette(size: 15, color: ms.gilt, filled: true),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
