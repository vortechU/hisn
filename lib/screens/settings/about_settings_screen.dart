import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/quran_repository.dart';
import '../../l10n/app_strings.dart';
import '../../models/quran.dart';
import '../../services/display_settings.dart';
import '../../theme/app_theme.dart';
import '../../util/arabic.dart';
import '../../widgets/ornament.dart';
import 'settings_common.dart';

/// The colophon: what the app is, and — as a printed book does on its last
/// leaf — what it was set in.
///
/// The credits here are not decoration. Every face bundled ships under the SIL
/// Open Font License, which asks that the fonts be identified, and the verse
/// translations are used by permission of the projects that produced them;
/// listing both is the honest thing and the licence-respecting one.
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
          const _CreditPanel(_typefaces),

          // The verse meanings — the translations, and the Arabic tafsir.
          // Loaded from the manifest the meaning files are generated with, so
          // what is credited here is necessarily the edition that actually
          // shipped.
          FutureBuilder<List<QuranEdition>>(
            future: context.read<QuranRepository>().loadEditions(),
            builder: (context, snap) {
              final editions = snap.data;
              if (editions == null || editions.isEmpty) {
                return const SizedBox.shrink();
              }
              return Column(
                children: [
                  const SettingsSectionHeader('Verse meanings'),
                  _CreditPanel([
                    for (final e in editions)
                      (e.name, e.translator, e.source),
                  ]),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

/// A ruled panel of credits: what it is, who made it, under what terms.
class _CreditPanel extends StatelessWidget {
  const _CreditPanel(this.rows);

  /// Name, who produced it, and the licence or source it comes under.
  final List<(String, String, String)> rows;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ms = ManuscriptTheme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: Ms.margin),
      decoration: BoxDecoration(
        border: Border.all(color: ms.rule),
        borderRadius: BorderRadius.circular(Ms.rPanel),
      ),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
              decoration: BoxDecoration(
                border:
                    i == 0 ? null : Border(top: BorderSide(color: ms.rule)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Credited(rows[i].$1,
                            style: theme.textTheme.titleSmall),
                        _Credited(rows[i].$2,
                            style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(rows[i].$3, style: theme.textTheme.labelSmall),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// One line of a credit, set in whichever script it is written in.
///
/// Most of what is credited here is a Latin proper noun and takes the panel's
/// own type. The tafsir is not — its title and the body that compiled it are
/// Arabic, and putting them through a Latin face would leave them to whatever
/// the system happened to fall back to, set left-to-right.
class _Credited extends StatelessWidget {
  const _Credited(this.text, {this.style});

  final String text;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    if (!isArabicScript(text)) return Text(text, style: style);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Text(
        text,
        style: style?.copyWith(
          fontFamily: context.read<DisplaySettings>().arabicFontFamily,
          height: 1.6,
        ),
      ),
    );
  }
}
