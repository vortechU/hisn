import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_strings.dart';
import '../../services/theme_controller.dart';
import '../../theme/app_palette.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ornament.dart';
import 'settings_common.dart';

/// Appearance settings: pick a colour palette and the light/dark theme mode.
/// Changes apply live — the whole app (and this screen) recolour instantly.
class AppearanceSettingsScreen extends StatelessWidget {
  const AppearanceSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ThemeController>();
    final s = AppStrings.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(s.secAppearance)),
      body: ListView(
        children: [
          SettingsSectionHeader(s.appearanceColors),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            padding: const EdgeInsets.fromLTRB(Ms.margin, 0, Ms.margin, 8),
            mainAxisSpacing: 14,
            crossAxisSpacing: 12,
            // Tall enough that the miniature still has room once the name
            // beneath it wraps to two lines at a large text scale.
            childAspectRatio: 0.64,
            children: [
              for (final palette in AppPalettes.all)
                _Swatch(
                  palette: palette,
                  selected: palette.id == controller.palette.id,
                  onTap: () =>
                      context.read<ThemeController>().setPalette(palette),
                ),
            ],
          ),
          SettingsSectionHeader(s.appearanceTheme),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: SegmentedButton<ThemeMode>(
              showSelectedIcon: false,
              segments: [
                ButtonSegment(
                  value: ThemeMode.light,
                  icon: const Icon(Icons.light_mode_outlined),
                  label: Text(s.themeLight),
                ),
                ButtonSegment(
                  value: ThemeMode.dark,
                  icon: const Icon(Icons.dark_mode_outlined),
                  label: Text(s.themeDark),
                ),
                ButtonSegment(
                  value: ThemeMode.system,
                  icon: const Icon(Icons.brightness_auto_outlined),
                  label: Text(s.themeSystem),
                ),
              ],
              selected: {controller.themeMode},
              onSelectionChanged: (set) =>
                  context.read<ThemeController>().setThemeMode(set.first),
            ),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.auto_awesome_outlined),
            title: Text(s.patterns),
            subtitle: Text(s.patternsSub),
            value: controller.patternsEnabled,
            onChanged: (value) =>
                context.read<ThemeController>().setPatternsEnabled(value),
          ),
        ],
      ),
    );
  }
}

/// A palette shown as the page it actually produces: its own paper, its ruled
/// frame, a line of rubricated heading over two lines of ink, and its gilt
/// rosette. A flat colour chip cannot show that these schemes differ in paper
/// temperature as much as in accent, so the swatch is a miniature instead.
class _Swatch extends StatelessWidget {
  const _Swatch({
    required this.palette,
    required this.selected,
    required this.onTap,
  });

  final AppPalette palette;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final s = AppStrings.of(context);
    // Preview each palette in the brightness the user is actually reading in.
    final brightness = theme.brightness;

    final paper = palette.paperFor(brightness);
    final ink = palette.inkFor(brightness);
    final rubric = palette.rubricFor(brightness);
    final gilt = palette.giltFor(brightness);

    Widget line(double width) => Container(
          height: 2.5,
          width: width,
          margin: const EdgeInsets.only(bottom: 3),
          color: ink.withValues(alpha: 0.55),
        );

    return Semantics(
      selected: selected,
      button: true,
      label: s.paletteName(palette.id),
      child: InkWell(
        borderRadius: BorderRadius.circular(Ms.rPanel),
        onTap: onTap,
        child: Column(
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: selected ? rubric : scheme.outlineVariant,
                    width: selected ? Ms.stroke : Ms.hair,
                  ),
                  borderRadius: BorderRadius.circular(Ms.rPanel),
                ),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(8, 7, 8, 7),
                  decoration: BoxDecoration(
                    color: paper,
                    border: Border.all(color: gilt.withValues(alpha: 0.5)),
                    borderRadius: BorderRadius.circular(Ms.rPanel - 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Rosette(size: 12, color: gilt, lobes: 8),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Container(height: 3, color: rubric),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      // The body of the miniature takes whatever height is
                      // left. Three columns of these land at ~45 logical
                      // pixels tall on a 320 px screen, so nothing below the
                      // heading may claim a fixed share.
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            line(double.infinity),
                            line(26),
                            const Spacer(),
                            Container(
                                height: Ms.hair,
                                color: ink.withValues(alpha: 0.3)),
                            const SizedBox(height: 5),
                            Container(width: 16, height: 2, color: gilt),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 7),
            Text(
              s.paletteName(palette.id),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? scheme.primary : scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
