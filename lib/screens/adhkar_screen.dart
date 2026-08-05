import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/dua_repository.dart';
import '../l10n/app_strings.dart';
import '../models/dua.dart';
import '../models/dua_category.dart';
import '../services/custom_dua_service.dart';
import '../theme/app_theme.dart';
import '../widgets/category_card.dart';
import '../widgets/muhassan_card.dart';
import '../widgets/ornament.dart';
import '../widgets/prayer_header.dart';
import '../widgets/recommended_adhkar.dart';
import 'category_duas_screen.dart';
import 'custom_duas_screen.dart';
import 'favorites_screen.dart';
import 'search_screen.dart';
import 'tasbih_screen.dart';

/// The Adhkar tab, laid out as the opening of a book: an illuminated plate,
/// the day's tally, the rubric pointing at what to read now, then the sections
/// of the table of contents.
///
/// Each section leads with one wide entry and continues in two columns, so the
/// page has a first read rather than an undifferentiated field of tiles.
class AdhkarScreen extends StatelessWidget {
  const AdhkarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = context.read<DuaRepository>();
    final categories = repo.categories;
    final custom = context.watch<CustomDuaService>();
    final s = AppStrings.of(context);

    final daily =
        categories.where((c) => c.group == DuaCategory.groupDaily).toList();
    final situational = categories
        .where((c) => c.group == DuaCategory.groupSituational)
        .toList();

    // A synthetic category card for the user's own duas, shown in its own group.
    final customCategory = DuaCategory(
      id: Dua.customCategoryId,
      title: s.myDuas,
      titleArabic: s.myDuasArabic,
      subtitle: s.myDuasSub,
      subtitleArabic: s.myDuasSub,
    );

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(child: PrayerHeader()),
            const SliverToBoxAdapter(child: _Toolbar()),
            const SliverToBoxAdapter(child: MuhassanCard()),
            const SliverToBoxAdapter(child: RecommendedAdhkar()),
            SliverToBoxAdapter(child: SectionMark(label: s.groupDaily)),
            _CategorySection(categories: daily, countOf: repo.countForCategory),
            SliverToBoxAdapter(child: SectionMark(label: s.groupSituational)),
            _CategorySection(
                categories: situational, countOf: repo.countForCategory),
            SliverToBoxAdapter(child: SectionMark(label: s.groupMine)),
            _CategorySection(
              categories: [customCategory],
              countOf: (_) => custom.count,
              bottomPadding: 28,
              onTapOverride: (context, _) => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CustomDuasScreen()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Search, tasbih and saved on one ruled strip.
///
/// These are the three ways *into* the book rather than parts of it, so they
/// share a single line of chrome instead of taking a card each — search
/// stretches, the two shortcuts are square marks at the end.
class _Toolbar extends StatelessWidget {
  const _Toolbar();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ms = ManuscriptTheme.of(context);
    final s = AppStrings.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(Ms.margin, 8, Ms.margin, 2),
      child: Row(
        children: [
          Expanded(
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(
                borderRadius: BorderRadius.circular(Ms.rSmall),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SearchScreen()),
                ),
                child: Container(
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: ms.rule),
                    borderRadius: BorderRadius.circular(Ms.rSmall),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.search,
                          size: 19, color: theme.colorScheme.onSurfaceVariant),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          s.searchDuas,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          _ToolMark(
            icon: Icons.radio_button_checked,
            tooltip: s.navTasbih,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const TasbihScreen()),
            ),
          ),
          const SizedBox(width: 8),
          _ToolMark(
            icon: Icons.bookmark_border,
            tooltip: s.navSaved,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const FavoritesScreen()),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToolMark extends StatelessWidget {
  const _ToolMark({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ms = ManuscriptTheme.of(context);
    return Tooltip(
      message: tooltip,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(Ms.rSmall),
          onTap: onTap,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              border: Border.all(color: ms.rule),
              borderRadius: BorderRadius.circular(Ms.rSmall),
            ),
            child: Icon(icon, size: 19, color: ms.rubric),
          ),
        ),
      ),
    );
  }
}

/// A section of the table of contents: one wide entry, then two columns.
class _CategorySection extends StatelessWidget {
  const _CategorySection({
    required this.categories,
    required this.countOf,
    this.onTapOverride,
    this.bottomPadding = 4,
  });

  final List<DuaCategory> categories;
  final int Function(String id) countOf;

  /// Optional custom tap handler (used for the "My Duas" entry).
  final void Function(BuildContext context, DuaCategory category)?
      onTapOverride;
  final double bottomPadding;

  void _open(BuildContext context, DuaCategory category) {
    if (onTapOverride != null) {
      onTapOverride!(context, category);
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => CategoryDuasScreen(category: category)),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) return const SliverToBoxAdapter();

    final lead = categories.first;
    final rest = categories.skip(1).toList();

    return SliverMainAxisGroup(
      slivers: [
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
              Ms.margin, 0, Ms.margin, rest.isEmpty ? bottomPadding : 12),
          sliver: SliverToBoxAdapter(
            child: CategoryCard(
              category: lead,
              count: countOf(lead.id),
              featured: true,
              onTap: () => _open(context, lead),
            ),
          ),
        ),
        if (rest.isNotEmpty)
          SliverPadding(
            padding:
                EdgeInsets.fromLTRB(Ms.margin, 0, Ms.margin, bottomPadding),
            sliver: SliverGrid(
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.06,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final category = rest[index];
                  return CategoryCard(
                    category: category,
                    count: countOf(category.id),
                    onTap: () => _open(context, category),
                  );
                },
                childCount: rest.length,
              ),
            ),
          ),
      ],
    );
  }
}
