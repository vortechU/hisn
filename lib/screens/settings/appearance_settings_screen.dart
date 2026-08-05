import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_strings.dart';
import '../../services/theme_controller.dart';
import '../../theme/app_palette.dart';
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
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
            childAspectRatio: 0.92,
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

/// A tappable palette tile: a colour chip (primary fill + accent dot) with the
/// palette name below, ringed and check-marked when it's the active palette.
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

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Column(
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: palette.primary,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: selected ? scheme.onSurface : Colors.transparent,
                  width: 3,
                ),
              ),
              child: Stack(
                children: [
                  PositionedDirectional(
                    end: 8,
                    bottom: 8,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: palette.secondary,
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.8)),
                      ),
                    ),
                  ),
                  if (selected)
                    const Center(
                      child: Icon(Icons.check, color: Colors.white, size: 26),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            s.paletteName(palette.id),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
              color: selected ? scheme.primary : scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
