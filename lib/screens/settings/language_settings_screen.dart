import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_strings.dart';
import '../../l10n/locale_controller.dart';

/// UI language picker (English / Arabic / Indonesian).
class LanguageSettingsScreen extends StatelessWidget {
  const LanguageSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleController>();
    final s = AppStrings.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(s.secLanguage)),
      body: ListView(
        children: [
          _LanguageTile(
            icon: Icons.language,
            label: s.languageEnglish,
            selected: locale.lang == AppLang.en,
            onTap: () => context.read<LocaleController>().setLang(AppLang.en),
          ),
          _LanguageTile(
            icon: Icons.translate,
            label: s.languageArabic,
            selected: locale.lang == AppLang.ar,
            onTap: () => context.read<LocaleController>().setLang(AppLang.ar),
          ),
          _LanguageTile(
            icon: Icons.translate,
            label: s.languageIndonesian,
            selected: locale.lang == AppLang.id,
            onTap: () => context.read<LocaleController>().setLang(AppLang.id),
          ),
        ],
      ),
    );
  }
}

class _LanguageTile extends StatelessWidget {
  const _LanguageTile({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      trailing: selected
          ? Icon(Icons.check, color: theme.colorScheme.primary)
          : null,
      selected: selected,
      onTap: onTap,
    );
  }
}
