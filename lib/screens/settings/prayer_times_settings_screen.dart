import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_strings.dart';
import '../../services/prayer_service.dart';
import '../../services/prayer_settings.dart';
import '../location_picker_screen.dart';
import 'settings_common.dart';

/// Prayer-time calculation settings: location, method, and Asr/madhab.
class PrayerTimesSettingsScreen extends StatelessWidget {
  const PrayerTimesSettingsScreen({super.key});

  String _locationSubtitle(PrayerService service, AppStrings s) {
    if (service.locationMode == LocationMode.gps) {
      return service.usingDeviceLocation
          ? s.locYourLocationGps
          : s.locDeviceGps(s.place(service.locationLabel));
    }
    return s.locFixedCity(s.place(service.locationLabel));
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<PrayerService>();
    final s = AppStrings.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(s.secPrayerTimes)),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.place_outlined),
            title: Text(s.location),
            subtitle: Text(_locationSubtitle(service, s)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const LocationPickerScreen()),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.calculate_outlined),
            title: Text(s.calcMethod),
            subtitle: Text(calculationMethodLabels[service.method] ?? '—'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _pickMethod(context, service, s),
          ),
          ListTile(
            leading: const Icon(Icons.schedule_outlined),
            title: Text(s.asrCalc),
            subtitle: Text(s.madhabLabel(service.madhab)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _pickMadhab(context, service, s),
          ),
        ],
      ),
    );
  }

  Future<void> _pickMethod(
      BuildContext context, PrayerService service, AppStrings s) async {
    final selected = await showSettingsPicker<CalculationMethod>(
      context: context,
      title: s.calcMethod,
      options: selectableMethods,
      current: service.method,
      labelOf: (m) => calculationMethodLabels[m] ?? m.name,
    );
    if (selected != null) await service.setMethod(selected);
  }

  Future<void> _pickMadhab(
      BuildContext context, PrayerService service, AppStrings s) async {
    final selected = await showSettingsPicker<Madhab>(
      context: context,
      title: s.asrCalc,
      options: const [Madhab.shafi, Madhab.hanafi],
      current: service.madhab,
      labelOf: (m) => s.madhabLabel(m),
      hintOf: (m) => s.madhabHint(m),
    );
    if (selected != null) await service.setMadhab(selected);
  }
}
