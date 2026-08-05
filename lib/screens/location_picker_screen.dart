import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_strings.dart';
import '../services/prayer_service.dart';
import '../services/prayer_settings.dart';

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
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(s.automatic,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  letterSpacing: 1.2,
                )),
          ),
          ListTile(
            leading: Icon(Icons.my_location,
                color: usingGps ? theme.colorScheme.primary : null),
            title: Text(s.useDeviceLocation),
            subtitle: Text(usingGps && service.usingDeviceLocation
                ? s.gpsActive
                : s.gpsDetect),
            trailing: usingGps
                ? Icon(Icons.check_circle, color: theme.colorScheme.primary)
                : null,
            onTap: () async {
              await context.read<PrayerService>().useDeviceLocation();
              if (context.mounted) Navigator.of(context).pop();
            },
          ),
          const Divider(height: 8),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(s.chooseCity,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  letterSpacing: 1.2,
                )),
          ),
          ...presetCities.map((city) {
            final selected = !usingGps && service.locationLabel == city.name;
            return ListTile(
              leading: Icon(Icons.location_city_outlined,
                  color: selected ? theme.colorScheme.primary : null),
              title: Text(city.name),
              subtitle: Text(city.region),
              trailing: selected
                  ? Icon(Icons.check_circle, color: theme.colorScheme.primary)
                  : null,
              onTap: () async {
                await context.read<PrayerService>().useManualCity(city);
                if (context.mounted) Navigator.of(context).pop();
              },
            );
          }),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: Text(
              s.cityNote,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
