import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/dua_repository.dart';
import '../l10n/app_strings.dart';
import '../models/dua.dart';
import '../models/dua_category.dart';
import '../services/custom_dua_service.dart';
import '../widgets/category_card.dart';
import '../widgets/muhassan_card.dart';
import '../widgets/prayer_header.dart';
import '../widgets/recommended_adhkar.dart';
import 'category_duas_screen.dart';
import 'custom_duas_screen.dart';
import 'favorites_screen.dart';
import 'search_screen.dart';
import 'tasbih_screen.dart';

/// Home tab: a greeting header, the daily muhassan meter, and the dua
/// categories grouped into sections (daily routine vs. situational).
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
    final situational =
        categories.where((c) => c.group == DuaCategory.groupSituational).toList();

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
        child: CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(child: PrayerHeader()),
            _SearchBar(),
            const _QuickActions(),
            const SliverToBoxAdapter(child: MuhassanCard()),
            const SliverToBoxAdapter(child: RecommendedAdhkar()),
            _SectionHeader(s.groupDaily),
            _CategoryGrid(
              categories: daily,
              countOf: repo.countForCategory,
            ),
            _SectionHeader(s.groupSituational),
            _CategoryGrid(
              categories: situational,
              countOf: repo.countForCategory,
            ),
            _SectionHeader(s.groupMine),
            _CategoryGrid(
              categories: [customCategory],
              countOf: (_) => custom.count,
              bottomPadding: 24,
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

class _SearchBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final s = AppStrings.of(context);
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
        child: Material(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SearchScreen()),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Icon(Icons.search, color: scheme.onSurfaceVariant),
                  const SizedBox(width: 12),
                  Text(
                    s.searchDuas,
                    style:
                        TextStyle(color: scheme.onSurfaceVariant, fontSize: 15),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Quick-access tiles for Tasbih and Saved, which used to be their own bottom
/// nav tabs and now live inside the Adhkar tab. Each opens the existing,
/// unchanged screen.
class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
        child: Row(
          children: [
            Expanded(
              child: _QuickTile(
                icon: Icons.radio_button_checked,
                label: s.navTasbih,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const TasbihScreen()),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickTile(
                icon: Icons.bookmark,
                label: s.navSaved,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const FavoritesScreen()),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickTile extends StatelessWidget {
  const _QuickTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(icon, size: 20, color: scheme.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
        ),
      ),
    );
  }
}

class _CategoryGrid extends StatelessWidget {
  const _CategoryGrid({
    required this.categories,
    required this.countOf,
    this.onTapOverride,
    this.bottomPadding = 8,
  });

  final List<DuaCategory> categories;
  final int Function(String id) countOf;

  /// Optional custom tap handler (used for the "My Duas" tile).
  final void Function(BuildContext context, DuaCategory category)? onTapOverride;
  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, bottomPadding),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          childAspectRatio: 0.92,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final category = categories[index];
            return CategoryCard(
              category: category,
              count: countOf(category.id),
              onTap: () {
                if (onTapOverride != null) {
                  onTapOverride!(context, category);
                } else {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => CategoryDuasScreen(category: category),
                    ),
                  );
                }
              },
            );
          },
          childCount: categories.length,
        ),
      ),
    );
  }
}
