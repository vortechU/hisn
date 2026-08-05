import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../l10n/app_strings.dart';
import '../models/quran.dart';
import '../services/quran_service.dart';
import '../theme/app_theme.dart';
import '../util/arabic.dart';
import '../widgets/arabic_text.dart';
import '../widgets/ornament.dart';

/// One verse: its citation, its Arabic text, and the controls for keeping or
/// copying it.
///
/// Shared by the page-verses sheet in the reader and the saved-verses list, so
/// a verse reads the same wherever it is met.
class VerseRow extends StatelessWidget {
  const VerseRow({
    super.key,
    required this.verse,
    this.onTap,
    this.showSurahName = true,
  });

  final PageVerse verse;

  /// Optional: jump to this verse in the mushaf.
  final VoidCallback? onTap;

  /// Whether to name the surah alongside the citation. Off inside a page sheet,
  /// where the running head already says which surah this is.
  final bool showSurahName;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final theme = Theme.of(context);
    final ms = ManuscriptTheme.of(context);
    final quran = context.watch<QuranService>();
    final saved = quran.isVerseBookmarked(verse.key);

    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(Ms.margin, 10, Ms.margin - 6, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // The verse number in the rosette the mushaf marks it with.
                  StarMedallion(
                    size: 30,
                    color: ms.gilt,
                    child: ArabicText(
                      toArabicDigits(verse.ayah.number),
                      fontSize: 11,
                      color: ms.rubric,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      showSurahName
                          ? '${verse.surah.translit} · ${verse.reference}'
                          : verse.reference,
                      style: theme.textTheme.labelSmall,
                    ),
                  ),
                  if (verse.ayah.sajda)
                    Padding(
                      padding: const EdgeInsetsDirectional.only(end: 4),
                      child: Icon(Icons.star_outline, size: 15, color: ms.gilt),
                    ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: Icon(
                      saved ? Icons.bookmark : Icons.bookmark_border,
                      size: 19,
                      color: saved ? ms.gilt : theme.colorScheme.onSurfaceVariant,
                    ),
                    tooltip: saved ? s.unsaveVerse : s.saveVerse,
                    onPressed: () {
                      context.read<QuranService>().toggleVerseBookmark(verse.key);
                      ScaffoldMessenger.of(context)
                        ..hideCurrentSnackBar()
                        ..showSnackBar(SnackBar(
                          content: Text(
                              saved ? s.bookmarkRemoved : s.bookmarkAdded),
                        ));
                    },
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.copy_outlined, size: 18),
                    tooltip: s.copy,
                    onPressed: () {
                      Clipboard.setData(ClipboardData(
                        text: '${verse.ayah.text}\n'
                            '(${verse.surah.translit} ${verse.reference})',
                      ));
                      ScaffoldMessenger.of(context)
                        ..hideCurrentSnackBar()
                        ..showSnackBar(
                            SnackBar(content: Text(s.duaCopied)));
                    },
                  ),
                ],
              ),
              const SizedBox(height: 2),
              // `block` anchors a short verse to the right rather than leaving
              // it adrift on the left.
              ArabicText(verse.ayah.text, block: true),
            ],
          ),
        ),
      ),
    );
  }
}
