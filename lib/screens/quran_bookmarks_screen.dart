import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/quran_repository.dart';
import '../l10n/app_strings.dart';
import '../services/quran_service.dart';
import '../util/arabic.dart';
import '../widgets/arabic_text.dart';
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
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.bookmarks_outlined,
                      size: 48,
                      color: Theme.of(context).colorScheme.onSurfaceVariant),
                  const SizedBox(height: 12),
                  Text(s.noBookmarks,
                      style: TextStyle(
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant)),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: pages.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final page = pages[i];
                final surah = repo.surahForPage(page);
                final scheme = Theme.of(context).colorScheme;
                return ListTile(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => MushafScreen(startPage: page),
                    ),
                  ),
                  leading: CircleAvatar(
                    radius: 20,
                    backgroundColor: scheme.primary.withValues(alpha: 0.12),
                    child: Text(toArabicDigits(page),
                        style: TextStyle(
                            color: scheme.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 13)),
                  ),
                  title: Text('${s.surahWord} ${surah.translit}'),
                  subtitle: Text(s.juzLabel(surah.juz),
                      style: TextStyle(color: scheme.onSurfaceVariant)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ArabicText(surah.name, fontSize: 18, color: scheme.primary),
                      IconButton(
                        icon: Icon(Icons.bookmark_remove_outlined,
                            color: scheme.error),
                        onPressed: () =>
                            context.read<QuranService>().toggleBookmark(page),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
