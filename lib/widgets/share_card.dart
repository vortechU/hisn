import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/shareable.dart';
import '../theme/app_theme.dart';
import '../util/arabic.dart';
import 'arabic_text.dart';
import 'ornament.dart';

/// A passage set as a standalone leaf, for sending out of the app.
///
/// This is the one surface the app is seen on by people who don't have it, so
/// it is built to different rules than a list card:
///
/// * **A fixed width.** The image must come out the same on every phone, so
///   the card does not take its width from the screen.
/// * **No text scaling.** The user's text-size preference and the system
///   scaler are both pinned off. They are reading aids for a screen being
///   read now; letting them through would change the image's proportions and
///   could push the text past the frame.
/// * **An opaque ground.** No transparency — a PNG with an alpha channel
///   turns into whatever the receiving app puts behind it, which for a dark
///   chat window means unreadable text.
class ShareCard extends StatelessWidget {
  const ShareCard({super.key, required this.passage});

  final Shareable passage;

  /// The card's width in logical pixels. At the 3× capture ratio this gives a
  /// 1080px-wide image — the long-standing size for a social post, and enough
  /// that Arabic at this size stays crisp.
  static const double width = 360;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ms = ManuscriptTheme.of(context);
    final s = AppStrings.of(context);

    return MediaQuery(
      // Pin the scaler: see the class comment.
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
      child: SizedBox(
        width: width,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: ms.paper,
            border: Border.all(color: ms.ruleStrong, width: Ms.stroke),
            borderRadius: BorderRadius.circular(Ms.rPanel),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // The heading band, the way a chapter is opened.
              if (passage.title != null || passage.titleArabic != null)
                UnwanBand(
                  child: passage.titleArabic != null
                      ? ArabicText(
                          stripHarakat(passage.titleArabic!),
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          textAlign: TextAlign.center,
                          height: 1.5,
                          color: ms.rubric,
                        )
                      : Text(
                          passage.title ?? '',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.titleSmall
                              ?.copyWith(color: ms.rubric),
                        ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ArabicText(passage.arabic, block: true, fontSize: 25),
                    if (passage.transliteration != null) ...[
                      const SizedBox(height: 14),
                      Text(
                        passage.transliteration!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontStyle: FontStyle.italic,
                          color: theme.colorScheme.onSurfaceVariant,
                          height: 1.55,
                        ),
                      ),
                    ],
                    if (passage.translation != null) ...[
                      const SizedBox(height: 10),
                      // An Arabic meaning is a tafsir, and wants Arabic type
                      // and a right-to-left line — set below the verse and
                      // smaller than it, so the card still reads as a verse
                      // with an explanation rather than two blocks of Arabic.
                      if (passage.translationIsArabic)
                        ArabicText(
                          passage.translation!,
                          block: true,
                          fontSize: 17,
                          height: 1.75,
                          color: theme.colorScheme.onSurfaceVariant,
                        )
                      else
                        Text(passage.translation!,
                            style: theme.textTheme.bodyLarge),
                    ],
                    // The translator, set small and directly under their work.
                    // The card is going somewhere the app isn't, so the person
                    // who rendered the meaning travels with it.
                    if (passage.translationCredit != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        passage.translationCredit!,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Container(height: Ms.hair, color: ms.rule),
                    const SizedBox(height: 9),
                    // The colophon. The source carries the weight here; the
                    // app's name is set smaller than it, because the passage
                    // is the point and the app is only how it travelled.
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Text(
                            passage.reference,
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                        const SizedBox(width: 10),
                        if (passage.repeat > 1) ...[
                          Cartouche(
                              label: '×${passage.repeat}', color: ms.gilt),
                          const SizedBox(width: 8),
                        ],
                        Rosette(size: 12, color: ms.gilt, lobes: 6),
                        const SizedBox(width: 5),
                        Text(
                          s.appName,
                          style: theme.textTheme.labelSmall
                              ?.copyWith(color: ms.rubric),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
