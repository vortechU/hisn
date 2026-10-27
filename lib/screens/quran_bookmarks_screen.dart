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
    final verseRows = verses.isEmpty ? 0 : verses.length + 1;
    final pageRows = pages.isEmpty ? 0 : pages.length + 1;

    return Scaffold(
      appBar: AppBar(title: Text(s.quranBookmarks)),
      body: pages.isEmpty && verses.isEmpty
          ? EmptyPage(icon: Icons.bookmarks_outlined, body: s.noBookmarks)
          : ListView.builder(
              padding: const EdgeInsets.only(bottom: 24),
              itemCount: verseRows + pageRows,
              itemBuilder: (context, index) {
                if (index < verseRows) {
                  if (index == 0) return SectionMark(label: s.savedVerses);
                  final key = verses[index - 1];
                  return _SavedVerse(key: ValueKey(key), verseKey: key);
                }
                final pageIndex = index - verseRows;
                if (pageIndex == 0) return SectionMark(label: s.savedPages);
                return _SavedPage(page: pages[pageIndex - 1]);
              },
            ),
    );
  }
}

/// A saved verse, loaded by its `surah:ayah` key.
///
/// The verse text lives in the surah files, which are loaded on demand, so each
/// row resolves itself rather than the screen loading every surah up front.
class _SavedVerse extends StatefulWidget {
  const _SavedVerse({super.key, required this.verseKey});

  final String verseKey;

  @override
  State<_SavedVerse> createState() => _SavedVerseState();
}

class _SavedVerseState extends State<_SavedVerse> {
  QuranRepository? _repo;
  String? _lang;
  Future<PageVerse?>? _verse;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final repo = context.read<QuranRepository>();
    final lang = AppStrings.of(context).lang.name;
    if (!identical(repo, _repo) || lang != _lang) _verse = null;
    _repo = repo;
    _lang = lang;
  }

  @override
  void didUpdateWidget(_SavedVerse oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.verseKey != widget.verseKey) _verse = null;
  }

  @override
  Widget build(BuildContext context) {
    final repo = _repo!;
    final parsed = PageVerse.parseKey(widget.verseKey);
    if (parsed == null) return const SizedBox.shrink();

    return FutureBuilder<PageVerse?>(
      future: _verse ??= repo.verse(parsed.$1, parsed.$2, lang: _lang),
      builder: (context, snap) {
        final verse = snap.data;
        // Zero-height pending rows make the viewport start every saved verse's
        // load in one frame. Reserve space so only nearby rows are requested.
        if (verse == null && snap.connectionState == ConnectionState.waiting) {
          return const SizedBox(height: 180);
        }
        if (verse == null) return const SizedBox.shrink();
        return Column(
          children: [
            VerseRow(
              verse: verse,
              // Opens on the verse, not merely on its page: the reader arrives
              // with the āyah already lit. The page comes from the rosette
              // index rather than the verse's own page field, which is a page
              // out for 56 verses — see QuranRepository.pageOfAyah.
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => MushafScreen(
                    startPage: repo.pageOfAyah(
                      verse.surah.number,
                      verse.ayah.number,
                    ),
                    highlightVerse: verse.key,
                  ),
                ),
              ),
            ),
            RuleDivider(
              indent: Ms.margin,
              color: ManuscriptTheme.of(context).rule,
            ),
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
              padding: const EdgeInsets.fromLTRB(
                Ms.margin,
                9,
                Ms.margin - 6,
                9,
              ),
              child: Row(
                children: [
                  // The page number in the mushaf's own Arabic-Indic digits,
                  // inside the khātam it is marked with there.
                  StarMedallion(
                    size: 38,
                    color: ms.rubric,
                    child: ArabicText(
                      toArabicDigits(page),
                      fontSize: 13,
                      color: ms.rubric,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${s.surahWord} ${surah.nameFor(s.lang.usesArabicScript)}',
                          style: theme.textTheme.titleSmall,
                        ),
                        Text(
                          s.juzLabel(surah.juz),
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  if (!s.ar)
                    ArabicText(
                      surah.name,
                      fontSize: 20,
                      color: ms.rubric,
                      height: 1.5,
                    ),
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
