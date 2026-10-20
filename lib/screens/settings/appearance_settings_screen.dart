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
            secondary: const Icon(Icons.pattern_outlined),
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

/// A palette shown as the screen it actually produces: its ground, its mihrab
/// with the lamp, and a group of rows. A flat colour chip cannot show how the
/// accent fills a field and tints the ground, so the swatch is a miniature.
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

    final ground = palette.groundFor(brightness);
    final paper = palette.paperFor(brightness);
    final ink = palette.inkFor(brightness);
    final rubric = palette.rubricFor(brightness);
    final gilt = palette.giltFor(brightness);
    final field = palette.fieldFor(brightness);
    final onField = palette.onFieldFor(brightness);

    Widget line(Color color, double width) => Container(
          height: 3,
          width: width,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
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
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: double.infinity,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: selected ? rubric : Colors.transparent,
                    width: Ms.stroke,
                  ),
                  borderRadius: BorderRadius.circular(Ms.rPanel),
                ),
                // A miniature of the hall in this palette: the ground, the
                // mihrab with its lamp, and a group of rows beneath.
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: ground,
                    borderRadius: BorderRadius.circular(Ms.rPanel - 4),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        flex: 5,
                        child: Container(
                          decoration: ShapeDecoration(
                            color: field,
                            shape: const MihrabBorder(rise: 7, radius: 8),
                          ),
                          padding: const EdgeInsets.fromLTRB(7, 10, 7, 6),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              line(onField.withValues(alpha: 0.85), 22),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Expanded(
                                    child: line(
                                        onField.withValues(alpha: 0.3), 0),
                                  ),
                                  const SizedBox(width: 4),
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: gilt,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Expanded(
                        flex: 3,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          decoration: BoxDecoration(
                            color: paper,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 7,
                                height: 7,
                                decoration: BoxDecoration(
                                  color: rubric.withValues(alpha: 0.6),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: line(ink.withValues(alpha: 0.45), 0),
                              ),
                            ],
                          ),
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
