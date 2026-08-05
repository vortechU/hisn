import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_strings.dart';
import '../../l10n/locale_controller.dart';
import '../../theme/app_theme.dart';
import '../../widgets/arabic_text.dart';
import '../../widgets/ornament.dart';

/// UI language picker (English / Arabic / Indonesian).
///
/// Each language is named in its own script and set in the face that will
/// actually render it, so the list previews the choice it offers.
class LanguageSettingsScreen extends StatelessWidget {
  const LanguageSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleController>();
    final s = AppStrings.of(context);

    void select(AppLang lang) =>
        context.read<LocaleController>().setLang(lang);

    return Scaffold(
      appBar: AppBar(title: Text(s.secLanguage)),
      body: ListView(
        children: [
          _LanguageRow(
            label: s.languageEnglish,
            code: 'EN',
            selected: locale.lang == AppLang.en,
            onTap: () => select(AppLang.en),
          ),
          _LanguageRow(
            label: s.languageArabic,
            code: 'AR',
            arabic: true,
            selected: locale.lang == AppLang.ar,
            onTap: () => select(AppLang.ar),
          ),
          _LanguageRow(
            label: s.languageIndonesian,
            code: 'ID',
            selected: locale.lang == AppLang.id,
            onTap: () => select(AppLang.id),
          ),
        ],
      ),
    );
  }
}

class _LanguageRow extends StatelessWidget {
  const _LanguageRow({
    required this.label,
    required this.code,
    required this.selected,
    required this.onTap,
    this.arabic = false,
  });

  final String label;
  final String code;
  final bool selected;
  final VoidCallback onTap;

  /// Sets the name in the Arabic face rather than the Latin one.
  final bool arabic;

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
            padding: const EdgeInsets.symmetric(
                horizontal: Ms.margin, vertical: 13),
            decoration: BoxDecoration(
              color: selected ? ms.rubric.withValues(alpha: 0.07) : null,
              border: Border(bottom: BorderSide(color: ms.rule)),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 34,
                  child: Text(
                    code,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: selected
                          ? ms.rubric
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                Expanded(
                  // The Arabic endonym is set in whichever Arabic face the
                  // user has chosen in Display settings, not a hardcoded one.
                  child: arabic
                      ? Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: ArabicText(label,
                              fontSize: 23,
                              textAlign: TextAlign.start,
                              height: 1.7,
                              maxLines: 1),
                        )
                      : Text(label, style: theme.textTheme.titleSmall),
                ),
                if (selected) Rosette(size: 16, color: ms.gilt, filled: true),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
