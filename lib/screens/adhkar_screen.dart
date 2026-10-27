import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/dua_repository.dart';
import '../l10n/app_strings.dart';
import '../models/dua.dart';
import '../models/dua_category.dart';
import '../services/custom_dua_service.dart';
import '../services/feature_tour_controller.dart';
import '../services/theme_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/app_dedication.dart';
import '../widgets/category_card.dart';
import '../widgets/feature_tour_anchor.dart';
import '../widgets/muhassan_card.dart';
import '../widgets/ornament.dart';
import '../widgets/prayer_header.dart';
import 'category_duas_screen.dart';
import 'custom_duas_screen.dart';
import 'favorites_screen.dart';
import 'search_screen.dart';
import 'tasbih_screen.dart';
import 'settings/appearance_settings_screen.dart';

/// The Adhkar tab: the mihrab at the head — the next prayer, the day, and the
/// adhkar to read now — then the ways in (search, tasbih, saved), then every
/// set as calm rows in three groups.
///
/// One thing on the page is filled and arched; everything else sits on the
/// plain ground, so the eye always knows where to land first.
class AdhkarScreen extends StatelessWidget {
  const AdhkarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = context.read<DuaRepository>();
    final categories = repo.categories;
    final custom = context.watch<CustomDuaService>();
    final s = AppStrings.of(context);

    final daily = categories
        .where((c) => c.group == DuaCategory.groupDaily)
        .toList();
    final situational = categories
        .where((c) => c.group == DuaCategory.groupSituational)
        .toList();

    // A synthetic category row for the user's own duas, in its own group.
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
            SliverToBoxAdapter(child: SectionMark(label: s.groupDaily)),
            _CategoryGroup(
              categories: daily,
              countOf: repo.countForCategory,
              leading: const MuhassanCard(),
            ),
            SliverToBoxAdapter(child: SectionMark(label: s.groupSituational)),
            _CategoryGroup(
              categories: situational,
              countOf: repo.countForCategory,
            ),
            SliverToBoxAdapter(child: SectionMark(label: s.groupMine)),
            _CategoryGroup(
              categories: [customCategory],
              countOf: (_) => custom.count,
              featured: true,
              onTapOverride: (context, _) => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CustomDuasScreen()),
              ),
            ),
            const SliverToBoxAdapter(child: AppDedication()),
          ],
        ),
      ),
    );
  }
}

/// Search, tasbih and saved: the ways *into* the book rather than parts of it.
///
/// Search is a wide pill with the appearance switch beside it; Tasbih and
/// Saved sit under it as a matched pair of labelled buttons, so every way in
/// has the same weight and a name.
class _Toolbar extends StatelessWidget {
  const _Toolbar();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ms = ManuscriptTheme.of(context);
    final s = AppStrings.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(Ms.margin, 16, Ms.margin, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Material(
                  color: ms.paper,
                  shape: const StadiumBorder(),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SearchScreen()),
                    ),
                    child: SizedBox(
                      height: 52,
                      child: Row(
                        children: [
                          const SizedBox(width: 18),
                          Icon(
                            Icons.search,
                            size: 22,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 12),
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
              const SizedBox(width: 10),
              const _HomeAppearanceMenu(),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: FeatureTourAnchor(
                  target: FeatureTourTarget.tasbih,
                  child: FilledButton.tonalIcon(
                    key: const ValueKey('open_tasbih'),
                    icon: const Icon(Icons.radio_button_checked, size: 20),
                    label: Text(s.navTasbih),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const TasbihScreen()),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.tonalIcon(
                  key: const ValueKey('open_saved'),
                  icon: const Icon(Icons.bookmark_border, size: 20),
                  label: Text(s.navSaved),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const FavoritesScreen()),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Theme choices live on the opening page so system-dark users can discover
/// both the light pages and the palette collection without hunting in Settings.
class _HomeAppearanceMenu extends StatelessWidget {
  const _HomeAppearanceMenu();

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ThemeController?>();
    if (controller == null) return const SizedBox.shrink();
    final s = AppStrings.of(context);
    final ms = ManuscriptTheme.of(context);
    return FeatureTourAnchor(
      target: FeatureTourTarget.appearance,
      child: PopupMenuButton<String>(
        key: const ValueKey('home_appearance'),
        tooltip: s.secAppearance,
        style: IconButton.styleFrom(
          backgroundColor: ms.paper,
          fixedSize: const Size(52, 52),
        ),
        icon: Icon(
          Theme.of(context).brightness == Brightness.dark
              ? Icons.dark_mode_outlined
              : Icons.light_mode_outlined,
          color: ms.rubric,
        ),
        onSelected: (value) {
          if (value == 'palette') {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const AppearanceSettingsScreen(),
              ),
            );
          } else {
            controller.setThemeMode(ThemeMode.values.byName(value));
          }
        },
        itemBuilder: (_) => [
          for (final mode in ThemeMode.values)
            CheckedPopupMenuItem(
              key: ValueKey('home_theme_${mode.name}'),
              value: mode.name,
              checked: controller.themeMode == mode,
              child: Text(switch (mode) {
                ThemeMode.light => s.themeLight,
                ThemeMode.dark => s.themeDark,
                ThemeMode.system => s.themeSystem,
              }),
            ),
          const PopupMenuDivider(),
          PopupMenuItem(value: 'palette', child: Text(s.secAppearance)),
        ],
      ),
    );
  }
}

/// A group of sets on one panel, one row each, optionally headed by a row of
/// its own ([leading]).
class _CategoryGroup extends StatelessWidget {
  const _CategoryGroup({
    required this.categories,
    required this.countOf,
    this.leading,
    this.onTapOverride,
    this.featured = false,
  });

  final List<DuaCategory> categories;
  final int Function(String id) countOf;
  final Widget? leading;

  /// Optional custom tap handler (used for the "My Duas" entry).
  final void Function(BuildContext context, DuaCategory category)?
  onTapOverride;

  /// Shows each row's subtitle — for a group of one, where there is room.
  final bool featured;

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

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: Ms.margin),
      sliver: SliverToBoxAdapter(
        child: RowGroup(
          indent: 70,
          children: [
            ?leading,
            for (final category in categories)
              CategoryCard(
                category: category,
                count: countOf(category.id),
                featured: featured,
                onTap: () => _open(context, category),
              ),
          ],
        ),
      ),
    );
  }
}
