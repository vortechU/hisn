import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/quran_repository.dart';
import '../l10n/app_strings.dart';
import '../models/quran.dart';
import '../services/quran_service.dart';
import '../theme/app_theme.dart';
import '../widgets/arabic_text.dart';
import '../widgets/ornament.dart';
import 'mushaf_screen.dart';
import 'quran_bookmarks_screen.dart';

/// Quran tab: a searchable list of the 114 surahs with a "continue reading"
/// shortcut. Tapping a surah opens the Madani Mushaf at that surah's page.
class QuranScreen extends StatefulWidget {
  const QuranScreen({super.key});

  @override
  State<QuranScreen> createState() => _QuranScreenState();
}

class _QuranScreenState extends State<QuranScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openPage(int page) => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => MushafScreen(startPage: page)),
      );

  @override
  Widget build(BuildContext context) {
    final repo = context.read<QuranRepository>();
    final quran = context.watch<QuranService>();
    final s = AppStrings.of(context);
    final results = repo.searchSurahs(_query);

    return Scaffold(
      appBar: AppBar(
        title: Text(s.quranTitle),
        actions: [
          IconButton(
            icon: Badge(
              isLabelVisible: quran.bookmarkCount > 0,
              label: Text('${quran.bookmarkCount}'),
              child: const Icon(Icons.bookmarks_outlined),
            ),
            tooltip: s.quranBookmarks,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const QuranBookmarksScreen()),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(Ms.margin, 4, Ms.margin, 10),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: s.searchSurah,
                prefixIcon: const Icon(Icons.search, size: 19),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        tooltip: s.clear,
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                      ),
              ),
            ),
          ),
          if (_query.isEmpty && quran.hasLastRead)
            _ContinueBanner(
              surah: repo.surahForPage(quran.lastPage!),
              page: quran.lastPage!,
              onTap: () => _openPage(quran.lastPage!),
            ),
          Expanded(
            child: ListView.separated(
              itemCount: results.length,
              separatorBuilder: (_, _) => Divider(
                height: 1,
                indent: Ms.margin + 52,
                endIndent: Ms.margin,
                color: ManuscriptTheme.of(context).rule,
              ),
              itemBuilder: (context, i) {
                final surah = results[i];
                return _SurahTile(
                  surah: surah,
                  onTap: () => _openPage(surah.page),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Where the reader left off, set as a rubric ruled into the page rather than
/// as a tinted box — the same treatment the Adhkar tab gives its suggestion.
class _ContinueBanner extends StatelessWidget {
  const _ContinueBanner({
    required this.surah,
    required this.page,
    required this.onTap,
  });

  final Surah surah;
  final int page;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ms = ManuscriptTheme.of(context);
    final s = AppStrings.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(Ms.margin, 4, Ms.margin, 8),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                    color: ms.gilt.withValues(alpha: 0.7), width: Ms.stroke),
                bottom: BorderSide(color: ms.rule),
              ),
            ),
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.continueReading.toUpperCase(),
                        style:
                            theme.textTheme.labelSmall?.copyWith(color: ms.gilt),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${s.surahWord} ${surah.nameFor(s.ar)} · '
                        '${s.juzLabel(surah.juz)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall,
                      ),
                    ],
                  ),
                ),
                // In Arabic the line above already names the surah in Arabic;
                // repeating it here would set the same word twice.
                if (!s.ar) ...[
                  const SizedBox(width: 12),
                  ArabicText(surah.name,
                      fontSize: 22, color: ms.rubric, height: 1.5),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// One sūrah in the register: its number in a khātam medallion, its name in
/// the reader's script, and where it sits in the revelation.
class _SurahTile extends StatelessWidget {
  const _SurahTile({required this.surah, required this.onTap});

  final Surah surah;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ms = ManuscriptTheme.of(context);
    final s = AppStrings.of(context);

    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: Ms.margin, vertical: 10),
          child: Row(
            children: [
              StarMedallion(number: surah.number, size: 38, color: ms.rubric),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // The name leads the entry in whichever script the reader
                    // is in: Arabic takes the title slot outright rather than
                    // sitting behind a transliteration they don't read.
                    if (s.ar)
                      ArabicText(
                        surah.name,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: ms.rubric,
                        textAlign: TextAlign.start,
                        height: 1.5,
                        maxLines: 1,
                      )
                    else
                      Text(surah.translit, style: theme.textTheme.titleSmall),
                    const SizedBox(height: 1),
                    Text(
                      '${s.revelationLabel(surah.revelation)} · '
                      '${s.versesCount(surah.ayahCount)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              if (!s.ar) ...[
                const SizedBox(width: 10),
                ArabicText(surah.name,
                    fontSize: 21, color: ms.rubric, height: 1.5),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
