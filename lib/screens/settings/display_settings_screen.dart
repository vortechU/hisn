import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_strings.dart';
import '../../services/display_settings.dart';
import '../../theme/arabic_fonts.dart';
import '../../theme/reading_theme.dart';

/// Reading display options: text size, Arabic font, reading background,
/// transliteration, and translation.
class DisplaySettingsScreen extends StatelessWidget {
  const DisplaySettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final display = context.watch<DisplaySettings>();
    final s = AppStrings.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(s.secDisplay)),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                const Icon(Icons.format_size),
                const SizedBox(width: 12),
                Text(s.textSize, style: theme.textTheme.bodyLarge),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(52, 0, 16, 8),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: Wrap(
                spacing: 8,
                children: [
                  for (var i = 0;
                      i < DisplaySettings.fontScaleSteps.length;
                      i++)
                    ChoiceChip(
                      label: Text(s.fontScaleLabels[i]),
                      selected: display.fontScale ==
                          DisplaySettings.fontScaleSteps[i],
                      onSelected: (_) => context
                          .read<DisplaySettings>()
                          .setFontScale(DisplaySettings.fontScaleSteps[i]),
                    ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                const Icon(Icons.font_download_outlined),
                const SizedBox(width: 12),
                Text(s.arabicFont, style: theme.textTheme.bodyLarge),
              ],
            ),
          ),
          for (final font in ArabicFonts.all)
            _FontTile(
              font: font,
              selected: display.arabicFontId == font.id,
              onTap: () =>
                  context.read<DisplaySettings>().setArabicFont(font.id),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                const Icon(Icons.contrast),
                const SizedBox(width: 12),
                Text(s.readingTheme, style: theme.textTheme.bodyLarge),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(52, 0, 16, 8),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: Wrap(
                spacing: 8,
                children: [
                  for (final rt in ReadingTheme.values)
                    ChoiceChip(
                      label: Text(_readingLabel(s, rt)),
                      selected: display.readingTheme == rt,
                      onSelected: (_) =>
                          context.read<DisplaySettings>().setReadingTheme(rt),
                    ),
                ],
              ),
            ),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.translate),
            title: Text(s.showTransliteration),
            subtitle: Text(s.showTransliterationSub),
            value: display.showTransliteration,
            onChanged: (value) =>
                context.read<DisplaySettings>().setShowTransliteration(value),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.subtitles_outlined),
            title: Text(s.showTranslation),
            subtitle: Text(s.showTranslationSub),
            value: display.showTranslation,
            onChanged: (value) =>
                context.read<DisplaySettings>().setShowTranslation(value),
          ),
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

/// A selectable Arabic-font row that previews the typeface with a basmala
/// sample rendered in that font (not the currently active one).
class _FontTile extends StatelessWidget {
  const _FontTile({
    required this.font,
    required this.selected,
    required this.onTap,
  });

  final ArabicFontOption font;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      onTap: onTap,
      selected: selected,
      title: Directionality(
        textDirection: TextDirection.rtl,
        child: Text(
          'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontFamily: font.family, fontSize: 22, height: 1.6),
        ),
      ),
      subtitle: Text(font.family),
      trailing: Icon(
        selected ? Icons.check_circle : Icons.circle_outlined,
        color: selected ? scheme.primary : scheme.onSurfaceVariant,
      ),
    );
  }
}
