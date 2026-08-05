import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/quran_repository.dart';
import '../l10n/app_strings.dart';
import '../services/quran_service.dart';
import '../theme/app_theme.dart';
import '../util/arabic.dart';
import '../widgets/arabic_text.dart';
import '../widgets/ornament.dart';
import 'mushaf_screen.dart';

/// Lists the user's bookmarked mushaf pages.
class QuranBookmarksScreen extends StatelessWidget {
  const QuranBookmarksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final quran = context.watch<QuranService>();
    final repo = context.read<QuranRepository>();
    final pages = quran.bookmarkedPages;

    return Scaffold(
      appBar: AppBar(title: Text(s.quranBookmarks)),
      body: pages.isEmpty
          ? EmptyPage(icon: Icons.bookmarks_outlined, body: s.noBookmarks)
          : ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 4),
              itemCount: pages.length,
              separatorBuilder: (context, _) => Divider(
                height: 1,
                indent: Ms.margin,
                endIndent: Ms.margin,
                color: ManuscriptTheme.of(context).rule,
              ),
              itemBuilder: (context, i) {
                final page = pages[i];
                final surah = repo.surahForPage(page);
                final theme = Theme.of(context);
                final ms = ManuscriptTheme.of(context);
                return Material(
                  type: MaterialType.transparency,
                  child: InkWell(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => MushafScreen(startPage: page),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                          Ms.margin, 9, Ms.margin - 6, 9),
                      child: Row(
                        children: [
                          // The page number in the mushaf's own Arabic-Indic
                          // digits, inside the khātam it is marked with there.
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
                                Text('${s.surahWord} ${surah.translit}',
                                    style: theme.textTheme.titleSmall),
                                Text(s.juzLabel(surah.juz),
                                    style: theme.textTheme.bodySmall),
                              ],
                            ),
                          ),
                          ArabicText(surah.name,
                              fontSize: 20, color: ms.rubric, height: 1.5),
                          IconButton(
                            icon: const Icon(Icons.bookmark_remove_outlined,
                                size: 20),
                            color: theme.colorScheme.error,
                            tooltip: s.removeBookmark,
                            onPressed: () => context
                                .read<QuranService>()
                                .toggleBookmark(page),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
