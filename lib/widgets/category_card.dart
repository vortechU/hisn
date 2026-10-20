import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/dua_repository.dart';
import '../l10n/app_strings.dart';
import '../models/dua.dart';
import '../models/dua_category.dart';
import '../services/dua_progress_service.dart';
import '../theme/app_theme.dart';
import '../theme/category_visuals.dart';
import 'arabic_text.dart';
import 'ornament.dart';

/// A category as one row of a group: its mark in a tinted well, its name and
/// where today's reading of it stands, and its Arabic name at the far end.
///
/// A set finished today takes the lamp: the row's fill warms, the well fills
/// solid with a check, and the status says so — and all of it eases back when
/// the set is started again.
///
/// The name and [featured] are kept from the grid tile this replaced;
/// [featured] now only shows the subtitle under the name.
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
    final s = AppStrings.of(context);
    final duas = category.id == Dua.customCategoryId
        ? const <Dua>[]
        : context.read<DuaRepository>().duasForCategory(category.id);
    final completed = context.select<DuaProgressService, int>(
      (progress) =>
          duas.where((dua) => progress.countOf(dua.id) >= dua.repeat).length,
    );
    final allDone = duas.isNotEmpty && completed == duas.length;
    final started = completed > 0 && !allDone;
    final tint = allDone ? ms.gilt : visuals.color(context);
    // Keep the numeric fraction in reading order inside Arabic/Urdu text.
    final tally = '\u2066$completed / ${duas.length}\u2069';
    final status = duas.isEmpty || completed == 0
        ? s.duaCount(count)
        : allDone
            ? '${s.done} · $tally'
            : tally;

    return JadwalFrame(
      onTap: onTap,
      // Transparent rather than paper, so the row sits on its group's fill
      // and only a finished set adds a tint of its own.
      background: allDone ? null : Colors.transparent,
      accent: allDone ? ms.gilt : null,
      emphasis: allDone,
      padding: const EdgeInsetsDirectional.fromSTEB(16, 14, 18, 14),
      child: Row(
        children: [
          IconWell(
            icon: allDone ? Icons.check_rounded : visuals.icon,
            color: tint,
            filled: allDone,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _title(theme, s),
                if (featured) ...[
                  const SizedBox(height: 1),
                  Text(
                    category.subtitleForLang(s.lang.name),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall,
                  ),
                ],
                const SizedBox(height: 3),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        status,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: allDone
                              ? Color.lerp(
                                  ms.gilt,
                                  theme.colorScheme.onSurface,
                                  0.3,
                                )
                              : started
                                  ? ms.rubric
                                  : null,
                          fontWeight:
                              allDone || started ? FontWeight.w500 : null,
                        ),
                      ),
                    ),
                    if (started) ...[
                      const SizedBox(width: 10),
                      SizedBox(
                        width: 56,
                        child: ProgressRule(
                          value: completed / duas.length,
                          color: ms.rubric,
                          thickness: 3,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (!s.ar) ...[
            const SizedBox(width: 10),
            // A capped column at the far end: the Arabic name gives way to
            // the title, never the other way round.
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 118),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: AlignmentDirectional.centerEnd,
                child: ArabicText(
                  category.titleArabic,
                  fontSize: 18,
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _title(ThemeData theme, AppStrings s) {
    if (s.rtl) {
      return ArabicText(
        category.titleForLang(s.lang.name),
        fontSize: 18,
        fontWeight: FontWeight.w500,
        textAlign: TextAlign.start,
        height: 1.45,
        maxLines: 1,
      );
    }
    return Text(
      category.titleForLang(s.lang.name),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: theme.textTheme.titleSmall,
    );
  }
}
