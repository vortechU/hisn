import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/quran_repository.dart';
import '../l10n/app_strings.dart';
import '../models/quran.dart';
import '../services/quran_service.dart';
import '../widgets/arabic_text.dart';
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
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: s.searchSurah,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                      ),
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.zero,
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
              separatorBuilder: (_, _) => const Divider(height: 1, indent: 72),
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
    final scheme = Theme.of(context).colorScheme;
    final s = AppStrings.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Material(
        color: scheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Icon(Icons.menu_book, color: scheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.continueReading,
                        style: TextStyle(
                          color: scheme.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${s.surahWord} ${surah.translit} · ${s.juzLabel(surah.juz)}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                ArabicText(surah.name, fontSize: 20, color: scheme.primary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SurahTile extends StatelessWidget {
  const _SurahTile({required this.surah, required this.onTap});

  final Surah surah;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final s = AppStrings.of(context);

    return ListTile(
      onTap: onTap,
      leading: _NumberDiamond(number: surah.number),
      title: Text(
        surah.translit,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        '${s.revelationLabel(surah.revelation)} · ${s.versesCount(surah.ayahCount)}',
        style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12.5),
      ),
      trailing: ArabicText(surah.name, fontSize: 20, color: scheme.primary),
    );
  }
}

class _NumberDiamond extends StatelessWidget {
  const _NumberDiamond({required this.number});

  final int number;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: 44,
      height: 44,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Transform.rotate(
            angle: 0.785398, // 45°
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: scheme.primary.withValues(alpha: 0.35),
                ),
              ),
            ),
          ),
          Text(
            '$number',
            style: TextStyle(
              color: scheme.primary,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
