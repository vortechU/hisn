import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/quran_repository.dart';
import '../l10n/app_strings.dart';
import '../models/quran.dart';
import '../services/quran_service.dart';
import '../theme/app_theme.dart';
import '../util/arabic.dart';
import '../widgets/arabic_text.dart';
import '../widgets/ornament.dart';
import '../widgets/verse_row.dart';
import 'mushaf_screen.dart';

/// The user's saved verses and saved pages.
///
/// Two lists rather than one: a page mark records where reading stopped, a
/// verse mark records an āyah worth returning to. Merging them would let a
/// khatmah's worth of reading marks bury the handful of verses that were meant
/// to be kept.
class QuranBookmarksScreen extends StatelessWidget {
  const QuranBookmarksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final quran = context.watch<QuranService>();
    final pages = quran.bookmarkedPages;
    final verses = quran.bookmarkedVerses;

    return Scaffold(
      appBar: AppBar(title: Text(s.quranBookmarks)),
      body: pages.isEmpty && verses.isEmpty
          ? EmptyPage(icon: Icons.bookmarks_outlined, body: s.noBookmarks)
          : ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                if (verses.isNotEmpty) ...[
                  SectionMark(label: s.savedVerses),
                  for (final key in verses) _SavedVerse(verseKey: key),
                ],
                if (pages.isNotEmpty) ...[
                  SectionMark(label: s.savedPages),
                  for (final page in pages) _SavedPage(page: page),
                ],
              ],
            ),
    );
  }
}

/// A saved verse, loaded by its `surah:ayah` key.
///
/// The verse text lives in the surah files, which are loaded on demand, so each
/// row resolves itself rather than the screen loading every surah up front.
class _SavedVerse extends StatelessWidget {
  const _SavedVerse({required this.verseKey});

  final String verseKey;

  @override
  Widget build(BuildContext context) {
    final repo = context.read<QuranRepository>();
    final parsed = PageVerse.parseKey(verseKey);
    if (parsed == null) return const SizedBox.shrink();

    return FutureBuilder<PageVerse?>(
      future: repo.verse(parsed.$1, parsed.$2,
          lang: AppStrings.of(context).lang.name),
      builder: (context, snap) {
        final verse = snap.data;
        // Reserve nothing while loading: the rows resolve within a frame or two
        // and a placeholder would flicker more than it reassures.
        if (verse == null) return const SizedBox.shrink();
        return Column(
          children: [
            VerseRow(
              verse: verse,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => MushafScreen(startPage: verse.ayah.page),
                ),
              ),
            ),
            RuleDivider(indent: Ms.margin, color: ManuscriptTheme.of(context).rule),
          ],
        );
      },
    );
  }
}

/// A saved page: where reading stopped.
class _SavedPage extends StatelessWidget {
  const _SavedPage({required this.page});

  final int page;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final theme = Theme.of(context);
    final ms = ManuscriptTheme.of(context);
    final surah = context.read<QuranRepository>().surahForPage(page);

    return Column(
      children: [
        Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => MushafScreen(startPage: page)),
            ),
            child: Padding(
              padding:
                  const EdgeInsets.fromLTRB(Ms.margin, 9, Ms.margin - 6, 9),
              child: Row(
                children: [
                  // The page number in the mushaf's own Arabic-Indic digits,
                  // inside the khātam it is marked with there.
                  StarMedallion(
                    size: 38,
                    color: ms.rubric,
                    child: ArabicText(toArabicDigits(page),
                        fontSize: 13, color: ms.rubric, height: 1.2),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${s.surahWord} ${surah.nameFor(s.ar)}',
                            style: theme.textTheme.titleSmall),
                        Text(s.juzLabel(surah.juz),
                            style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ),
                  if (!s.ar)
                    ArabicText(surah.name,
                        fontSize: 20, color: ms.rubric, height: 1.5),
                  IconButton(
                    icon: const Icon(Icons.bookmark_remove_outlined, size: 20),
                    color: theme.colorScheme.error,
                    tooltip: s.removeBookmark,
                    onPressed: () =>
                        context.read<QuranService>().toggleBookmark(page),
                  ),
                ],
              ),
            ),
          ),
        ),
        RuleDivider(indent: Ms.margin, color: ms.rule),
      ],
    );
  }
}
