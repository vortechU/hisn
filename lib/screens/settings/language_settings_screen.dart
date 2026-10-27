import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_strings.dart';
import '../../l10n/locale_controller.dart';
import '../../theme/app_theme.dart';
import '../../widgets/arabic_text.dart';
import '../../widgets/ornament.dart';

/// UI language picker, populated from the language registry.
///
/// Each language is named in its own script and set in the face that will
/// actually render it, so the list previews the choice it offers.
class LanguageSettingsScreen extends StatelessWidget {
  const LanguageSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleController>();
    final s = AppStrings.of(context);

    void select(AppLang lang) => context.read<LocaleController>().setLang(lang);

    return Scaffold(
      appBar: AppBar(title: Text(s.secLanguage)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(Ms.margin, 6, Ms.margin, 32),
        children: [
          RowGroup(
            indent: 66,
            children: [
              for (final language in AppLang.values)
                _LanguageRow(
                  label: language.nativeName,
                  code: language.code.toUpperCase(),
                  arabic: language.usesArabicScript,
                  selected: locale.lang == language,
                  onTap: () => select(language),
                ),
            ],
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
            padding: const EdgeInsets.fromLTRB(20, 12, 18, 12),
            constraints: const BoxConstraints(minHeight: 64),
            child: Row(
              children: [
                SizedBox(
                  width: 46,
                  child: Text(
                    code,
                    style: theme.textTheme.labelMedium?.copyWith(
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
                          child: ArabicText(
                            label,
                            fontSize: 23,
                            textAlign: TextAlign.start,
                            height: 1.7,
                            maxLines: 1,
                          ),
                        )
                      : Text(label, style: theme.textTheme.titleSmall),
                ),
                if (selected) Icon(Icons.check_rounded, color: ms.rubric),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
