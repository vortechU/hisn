import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/quran_repository.dart';
import '../l10n/app_strings.dart';
import '../models/quran.dart';
import '../services/quran_service.dart';
import '../services/feature_tour_controller.dart';
import '../theme/app_theme.dart';
import '../util/arabic.dart';
import '../widgets/arabic_text.dart';
import '../widgets/feature_tour_anchor.dart';
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
  Timer? _searchDelay;
  int _searchVersion = 0;
  List<PageVerse> _verseResults = const [];
  bool _searchingVerses = false;
  bool _verseSearchFailed = false;
  bool _moreVerses = false;

  bool get _wordSearch =>
      normalizeArabic(_query.trim()).length >= 2 && isArabicScript(_query);

  void _search(String query, {bool immediate = false}) {
    _searchDelay?.cancel();
    final version = ++_searchVersion;
    setState(() {
      _query = query;
      _verseResults = const [];
      _verseSearchFailed = false;
      _moreVerses = false;
      _searchingVerses = _wordSearch;
    });
    if (!_wordSearch) return;
    if (immediate) {
      _findVerses(query, version);
    } else {
      _searchDelay = Timer(
        const Duration(milliseconds: 250),
        () => _findVerses(query, version),
      );
    }
  }

  Future<void> _findVerses(String query, int version) async {
    try {
      final results = await context.read<QuranRepository>().searchVerses(
        query,
        limit: 51,
      );
      if (!mounted || version != _searchVersion) return;
      setState(() {
        _verseResults = results.take(50).toList();
        _moreVerses = results.length > 50;
        _searchingVerses = false;
      });
    } catch (_) {
      if (!mounted || version != _searchVersion) return;
      setState(() {
        _searchingVerses = false;
        _verseSearchFailed = true;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchDelay?.cancel();
    super.dispose();
  }

  void _openPage(int page) => Navigator.of(
    context,
  ).push(MaterialPageRoute(builder: (_) => MushafScreen(startPage: page)));

  void _openVerse(PageVerse verse) => Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => MushafScreen(
        startPage: context.read<QuranRepository>().pageOfAyah(
          verse.surah.number,
          verse.ayah.number,
        ),
        highlightVerse: verse.key,
      ),
    ),
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
            child: FeatureTourAnchor(
              target: FeatureTourTarget.quranSearch,
              child: TextField(
                controller: _searchController,
                onChanged: _search,
                textDirection:
                    contentDirection(_query, Directionality.of(context)),
                keyboardAppearance: Theme.of(context).brightness,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(Ms.rButton)),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(Ms.rButton)),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius:
                        const BorderRadius.all(Radius.circular(Ms.rButton)),
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.primary,
                      width: 1.5,
                    ),
                  ),
                  hintText: s.searchQuran,
                  prefixIcon: const Padding(
                    padding: EdgeInsetsDirectional.only(start: 8),
                    child: Icon(Icons.search, size: 22),
                  ),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          tooltip: s.clear,
                          onPressed: () {
                            _searchController.clear();
                            _search('');
                          },
                        ),
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
            child: _query.trim().isNotEmpty
                ? _searchResults(context, results, s)
                : ListView.separated(
                    itemCount: results.length,
                    separatorBuilder: (_, _) => Divider(
                      height: 1,
                      indent: Ms.margin + 56,
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

  Widget _searchResults(
    BuildContext context,
    List<Surah> surahs,
    AppStrings s,
  ) {
    final theme = Theme.of(context);
    Widget heading(String text) => Padding(
      padding: const EdgeInsets.fromLTRB(Ms.margin, 12, Ms.margin, 6),
      child: Text(text, style: theme.textTheme.titleSmall),
    );
    return ListView(
      children: [
        if (surahs.isNotEmpty) ...[
          heading(s.quranSearchSurahs),
          for (final surah in surahs)
            _SurahTile(surah: surah, onTap: () => _openPage(surah.page)),
        ],
        if (_wordSearch) ...[
          heading(s.quranSearchVerses),
          if (_searchingVerses)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_verseSearchFailed)
            Padding(
              padding: const EdgeInsets.all(Ms.margin),
              child: Column(
                children: [
                  Text(s.quranSearchFailed),
                  TextButton(
                    onPressed: () => _search(_query, immediate: true),
                    child: Text(s.retrySearch),
                  ),
                ],
              ),
            )
          else if (_verseResults.isEmpty)
            Padding(
              padding: const EdgeInsets.all(Ms.margin),
              child: Text(s.quranNoResults(_query)),
            )
          else ...[
            if (_moreVerses)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Ms.margin),
                child: Text(
                  s.quranSearchLimit,
                  style: theme.textTheme.bodySmall,
                ),
              ),
            for (final verse in _verseResults)
              _VerseSearchTile(verse: verse, onTap: () => _openVerse(verse)),
          ],
        ] else if (surahs.isEmpty)
          Padding(
            padding: const EdgeInsets.all(Ms.margin),
            child: Text(s.quranNoResults(_query)),
          ),
      ],
    );
  }
}

class _VerseSearchTile extends StatelessWidget {
  const _VerseSearchTile({required this.verse, required this.onTap});
  final PageVerse verse;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final theme = Theme.of(context);
    return ListTile(
      key: ValueKey('quran-search-${verse.key}'),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: Ms.margin,
        vertical: 8,
      ),
      title: Text(
        '${verse.surah.nameFor(s.rtl)} · ${verse.reference}',
        style: theme.textTheme.titleSmall,
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 6),
        child: ArabicText(
          verse.ayah.text,
          fontSize: 21,
          height: 1.7,
          maxLines: 3,
        ),
      ),
      onTap: onTap,
    );
  }
}

/// Where the reader left off: the tab's mihrab, holding the sūrah's name in
/// both scripts, where in the Qurʾān it sits, and the way back in.
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
    final quiet = ms.onField.withValues(alpha: 0.88);

    return Padding(
      padding: const EdgeInsets.fromLTRB(Ms.margin, 2, Ms.margin, 12),
      child: MihrabField(
        rise: 34,
        onTap: onTap,
        padding: const EdgeInsets.fromLTRB(20, 0, 16, 16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${s.surahWord} ${surah.nameFor(s.rtl)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleLarge
                        ?.copyWith(color: ms.onField),
                  ),
                  Text(
                    '${s.continueReading} · ${s.juzLabel(surah.juz)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(color: quiet),
                  ),
                ],
              ),
            ),
            // In Arabic the line above already names the surah in Arabic;
            // repeating it here would set the same word twice.
            if (!s.ar) ...[
              const SizedBox(width: 12),
              // Capped, so the name in the reader's script keeps the room.
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 120),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerEnd,
                  child: ArabicText(
                    surah.name,
                    fontSize: 30,
                    color: ms.onField,
                    height: 1.5,
                  ),
                ),
              ),
            ],
            const SizedBox(width: 8),
            Icon(
              s.rtl ? Icons.arrow_back_rounded : Icons.arrow_forward_rounded,
              color: ms.onField,
            ),
          ],
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
          padding: const EdgeInsets.symmetric(
            horizontal: Ms.margin,
            vertical: 10,
          ),
          child: Row(
            children: [
              StarMedallion(number: surah.number, size: 42, color: ms.rubric),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // The name leads the entry in whichever script the reader
                    // is in: Arabic takes the title slot outright rather than
                    // sitting behind a transliteration they don't read.
                    if (s.rtl)
                      ArabicText(
                        surah.name,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
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
                ArabicText(
                  surah.name,
                  fontSize: 22,
                  color: theme.colorScheme.onSurface,
                  height: 1.5,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
