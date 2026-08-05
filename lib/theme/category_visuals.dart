import 'package:flutter/material.dart';

import 'app_theme.dart';

/// Which of the palette's two inks a category is set in.
///
/// The app deliberately does *not* give each category its own hue. Eleven
/// accent colours made the grid read as a colour swatch rather than as a book,
/// and it meant colour carried no information. Here the ink carries the
/// category's group: the sets you work through every day are rubricated, the
/// ones you reach for as the occasion arises are gilt.
enum CategoryTone { rubric, gilt }

/// Maps a category id to its presentational mark.
///
/// Keeping this out of the JSON lets content stay purely textual while the UI
/// owns how each category looks.
class CategoryVisuals {
  const CategoryVisuals(this.icon, this.tone, this.lobes);

  final IconData icon;
  final CategoryTone tone;

  /// Lobe count for the small rosette the "recommended now" rubric sets beside
  /// its label. Category cards show the bare icon — an icon inside a lobed
  /// ring put two ornaments on one job and turned the grid into a row of
  /// medallions.
  final int lobes;

  /// The colour for this category under the active theme.
  Color color(BuildContext context) {
    final ms = ManuscriptTheme.of(context);
    return tone == CategoryTone.rubric ? ms.rubric : ms.gilt;
  }

  // Icons are all drawn from one library at one weight (outlined), monochrome,
  // and sized 20–24. They are wayfinding, not decoration.
  static const Map<String, CategoryVisuals> _map = {
    'morning': CategoryVisuals(
        Icons.wb_twilight_outlined, CategoryTone.rubric, 12),
    'evening':
        CategoryVisuals(Icons.nights_stay_outlined, CategoryTone.rubric, 10),
    'after_salah':
        CategoryVisuals(Icons.mosque_outlined, CategoryTone.rubric, 8),
    'sleep': CategoryVisuals(Icons.bedtime_outlined, CategoryTone.rubric, 6),
    'waking': CategoryVisuals(Icons.alarm_outlined, CategoryTone.rubric, 8),
    'daily':
        CategoryVisuals(Icons.auto_awesome_outlined, CategoryTone.rubric, 10),
    'forgiveness': CategoryVisuals(Icons.spa_outlined, CategoryTone.gilt, 8),
    'distress':
        CategoryVisuals(Icons.self_improvement_outlined, CategoryTone.gilt, 12),
    'travel': CategoryVisuals(Icons.explore_outlined, CategoryTone.gilt, 6),
    'mosque': CategoryVisuals(
        Icons.door_front_door_outlined, CategoryTone.gilt, 10),
    'custom': CategoryVisuals(
        Icons.volunteer_activism_outlined, CategoryTone.gilt, 8),
  };

  static CategoryVisuals of(String categoryId) =>
      _map[categoryId] ??
      const CategoryVisuals(
          Icons.menu_book_outlined, CategoryTone.rubric, 8);
}
