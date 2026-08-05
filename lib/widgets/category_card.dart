import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/dua_category.dart';
import '../theme/app_theme.dart';
import '../theme/category_visuals.dart';
import 'arabic_text.dart';
import 'ornament.dart';

/// A category as an entry in the book's table of contents.
///
/// The mark at the head of each entry is a rosette lobed to that category —
/// six points for the sleep adhkar, twelve for the morning — so entries are
/// told apart by their geometry rather than by eleven different accent hues.
///
/// [featured] gives the first entry of a section the wider, two-column
/// treatment, so each section of the grid has a clear first read instead of
/// repeating one tile shape down the page.
class CategoryCard extends StatelessWidget {
  const CategoryCard({
    super.key,
    required this.category,
    required this.count,
    required this.onTap,
    this.featured = false,
  });

  final DuaCategory category;
  final int count;
  final VoidCallback onTap;
  final bool featured;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ms = ManuscriptTheme.of(context);
    final visuals = CategoryVisuals.of(category.id);
    final tint = visuals.color(context);
    final s = AppStrings.of(context);

    return JadwalFrame(
      onTap: onTap,
      accent: featured ? tint : null,
      emphasis: featured,
      padding: EdgeInsets.all(featured ? 15 : 13),
      child: featured
          ? _featuredLayout(context, theme, ms, visuals, tint, s)
          : _tileLayout(context, theme, ms, visuals, tint, s),
    );
  }

  /// The wide entry: mark and text side by side, with the subtitle shown.
  Widget _featuredLayout(BuildContext context, ThemeData theme,
      ManuscriptTheme ms, CategoryVisuals visuals, Color tint, AppStrings s) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(visuals.icon, size: 26, color: tint),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // The Latin title leads and gets the room it needs; the
                  // Arabic takes what is left rather than an equal share, so
                  // a two-word title doesn't wrap while space sits unused.
                  Flexible(flex: 3, child: _title(theme, s, large: true)),
                  if (!s.ar) ...[
                    const SizedBox(width: 10),
                    Flexible(
                      flex: 2,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: AlignmentDirectional.centerEnd,
                        child: ArabicText(category.titleArabic,
                            fontSize: 20, color: tint, height: 1.5),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 3),
              Text(
                category.subtitleFor(s.ar),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Cartouche(label: s.duaCount(count), color: tint),
                  const SizedBox(width: 10),
                  Expanded(child: Container(height: Ms.hair, color: ms.rule)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// The narrow entry: mark and Arabic on one line, title anchored to the
  /// foot of the tile so titles align across a row regardless of length.
  Widget _tileLayout(BuildContext context, ThemeData theme, ManuscriptTheme ms,
      CategoryVisuals visuals, Color tint, AppStrings s) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(visuals.icon, size: 23, color: tint),
            const SizedBox(width: 8),
            if (!s.ar)
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerEnd,
                  child: ArabicText(category.titleArabic,
                      fontSize: 17, color: tint, height: 1.5),
                ),
              ),
          ],
        ),
        const Spacer(),
        const SizedBox(height: 10),
        _title(theme, s, large: false),
        const SizedBox(height: 7),
        Container(height: Ms.hair, color: ms.rule),
        const SizedBox(height: 7),
        Text(
          s.duaCount(count),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _title(ThemeData theme, AppStrings s, {required bool large}) {
    if (s.ar) {
      return ArabicText(
        category.titleArabic,
        fontSize: large ? 21 : 18,
        fontWeight: FontWeight.w600,
        textAlign: TextAlign.start,
        height: 1.45,
        maxLines: 2,
      );
    }
    return Text(
      category.title,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: large ? theme.textTheme.titleLarge : theme.textTheme.titleMedium,
    );
  }
}
