import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_strings.dart';
import '../services/prayer_service.dart';
import '../services/prayer_settings.dart';
import '../theme/app_theme.dart';
import '../widgets/ornament.dart';

/// Lets the user choose between device GPS and a built-in city.
class LocationPickerScreen extends StatelessWidget {
  const LocationPickerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = context.watch<PrayerService>();
    final theme = Theme.of(context);
    final s = AppStrings.of(context);
    final usingGps = service.locationMode == LocationMode.gps;

    return Scaffold(
      appBar: AppBar(title: Text(s.location)),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 28),
        children: [
          SectionMark(label: s.automatic),
          _Choice(
            icon: Icons.my_location,
            title: s.useDeviceLocation,
            subtitle: usingGps && service.usingDeviceLocation
                ? s.gpsActive
                : s.gpsDetect,
            selected: usingGps,
            onTap: () async {
              await context.read<PrayerService>().useDeviceLocation();
              if (context.mounted) Navigator.of(context).pop();
            },
          ),
          SectionMark(label: s.chooseCity),
          ...presetCities.map((city) {
            final selected = !usingGps && service.locationLabel == city.name;
            return _Choice(
              icon: Icons.location_city_outlined,
              title: city.name,
              subtitle: city.region,
              selected: selected,
              onTap: () async {
                await context.read<PrayerService>().useManualCity(city);
                if (context.mounted) Navigator.of(context).pop();
              },
            );
          }),
          Padding(
            padding: const EdgeInsets.fromLTRB(Ms.margin, 16, Ms.margin, 0),
            child: Text(s.cityNote, style: theme.textTheme.bodySmall),
          ),
        ],
      ),
    );
  }
}

/// One selectable location, ruled beneath and marked with a filled rosette
/// when active.
class _Choice extends StatelessWidget {
  const _Choice({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ms = ManuscriptTheme.of(context);

    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: Ms.margin, vertical: 11),
            decoration: BoxDecoration(
              color: selected ? ms.rubric.withValues(alpha: 0.07) : null,
              border: Border(bottom: BorderSide(color: ms.rule)),
            ),
            child: Row(
              children: [
                Icon(icon,
                    size: 19,
                    color: selected
                        ? ms.rubric
                        : theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: theme.textTheme.titleSmall),
                      Text(subtitle, style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
                if (selected) Rosette(size: 16, color: ms.gilt, filled: true),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
