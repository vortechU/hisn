import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ornament.dart';
import 'settings_common.dart';

/// The colophon: what the app is, and — as a printed book does on its last
/// leaf — what it was set in.
///
/// The typeface credits are not decoration. Every face bundled here ships
/// under the SIL Open Font License, which asks that the fonts be identified;
/// listing them is both the honest thing and the licence-respecting one.
class AboutSettingsScreen extends StatelessWidget {
  const AboutSettingsScreen({super.key});

  // Family, role, licence. Proper nouns and licence identifiers only, so this
  // list needs no translation.
  static const _typefaces = <(String, String, String)>[
    ('Amiri', 'Arabic text', 'SIL OFL 1.1'),
    ('Scheherazade New', 'Arabic text', 'SIL OFL 1.1'),
    ('Noto Naskh Arabic', 'Arabic text', 'SIL OFL 1.1'),
    ('KFGQPC Hafs (QCF v4)', 'Mushaf pages', 'KFGQPC'),
    ('Crimson Pro', 'Latin text', 'SIL OFL 1.1'),
    ('Karla', 'Latin apparatus', 'SIL OFL 1.1'),
  ];

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final theme = Theme.of(context);
    final ms = ManuscriptTheme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(s.secAbout)),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 34),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(Ms.margin, 18, Ms.margin, 0),
            child: Column(
              children: [
                Rosette(size: 58, color: ms.gilt, lobes: 12),
                const SizedBox(height: 14),
                Text(s.appName, style: theme.textTheme.headlineMedium),
                const SizedBox(height: 2),
                Text('v$kAppVersion', style: theme.textTheme.labelSmall),
                const RuleDivider(indent: 50),
                Text(
                  s.aboutBody,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge,
                ),
              ],
            ),
          ),
          const SettingsSectionHeader('Set in'),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: Ms.margin),
            decoration: BoxDecoration(
              border: Border.all(color: ms.rule),
              borderRadius: BorderRadius.circular(Ms.rPanel),
            ),
            child: Column(
              children: [
                for (var i = 0; i < _typefaces.length; i++)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 13, vertical: 10),
                    decoration: BoxDecoration(
                      border: i == 0
                          ? null
                          : Border(top: BorderSide(color: ms.rule)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_typefaces[i].$1,
                                  style: theme.textTheme.titleSmall),
                              Text(_typefaces[i].$2,
                                  style: theme.textTheme.bodySmall),
                            ],
                          ),
                        ),
                        Text(_typefaces[i].$3,
                            style: theme.textTheme.labelSmall),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
