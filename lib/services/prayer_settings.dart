import 'package:adhan/adhan.dart';

/// How the app decides which coordinates to compute prayer times for.
enum LocationMode { gps, manual }

/// A built-in city the user can pick in Settings (offline — no geocoding).
///
/// Times for a manual city are shown in the device's current timezone, which is
/// correct when the city is in your own region (the common case).
class PresetCity {
  const PresetCity(this.name, this.region, this.latitude, this.longitude);

  final String name;
  final String region;
  final double latitude;
  final double longitude;
}

const List<PresetCity> presetCities = [
  PresetCity('Makkah', 'Saudi Arabia', 21.4225, 39.8262),
  PresetCity('Madinah', 'Saudi Arabia', 24.4672, 39.6111),
  PresetCity('Riyadh', 'Saudi Arabia', 24.7136, 46.6753),
  PresetCity('Doha', 'Qatar', 25.2854, 51.5310),
  PresetCity('Dubai', 'UAE', 25.2048, 55.2708),
  PresetCity('Kuwait City', 'Kuwait', 29.3759, 47.9774),
  PresetCity('Cairo', 'Egypt', 30.0444, 31.2357),
  PresetCity('Istanbul', 'Türkiye', 41.0082, 28.9784),
  PresetCity('Casablanca', 'Morocco', 33.5731, -7.5898),
  PresetCity('Lagos', 'Nigeria', 6.5244, 3.3792),
  PresetCity('Karachi', 'Pakistan', 24.8607, 67.0011),
  PresetCity('Lahore', 'Pakistan', 31.5204, 74.3587),
  PresetCity('Delhi', 'India', 28.6139, 77.2090),
  PresetCity('Dhaka', 'Bangladesh', 23.8103, 90.4125),
  PresetCity('Jakarta', 'Indonesia', -6.2088, 106.8456),
  PresetCity('Kuala Lumpur', 'Malaysia', 3.1390, 101.6869),
  PresetCity('Singapore', 'Singapore', 1.3521, 103.8198),
  PresetCity('London', 'United Kingdom', 51.5074, -0.1278),
  PresetCity('Paris', 'France', 48.8566, 2.3522),
  PresetCity('New York', 'USA', 40.7128, -74.0060),
  PresetCity('Chicago', 'USA', 41.8781, -87.6298),
  PresetCity('Los Angeles', 'USA', 34.0522, -118.2437),
  PresetCity('Toronto', 'Canada', 43.6532, -79.3832),
  PresetCity('Sydney', 'Australia', -33.8688, 151.2093),
];

/// Calculation methods offered in Settings, with friendly labels.
/// (`other` is intentionally excluded — it zeroes the Fajr/Isha angles.)
const Map<CalculationMethod, String> calculationMethodLabels = {
  CalculationMethod.muslim_world_league: 'Muslim World League',
  CalculationMethod.egyptian: 'Egyptian General Authority',
  CalculationMethod.karachi: 'University of Karachi',
  CalculationMethod.umm_al_qura: 'Umm al-Qura (Makkah)',
  CalculationMethod.dubai: 'Dubai',
  CalculationMethod.qatar: 'Qatar',
  CalculationMethod.kuwait: 'Kuwait',
  CalculationMethod.moon_sighting_committee: 'Moonsighting Committee',
  CalculationMethod.singapore: 'Singapore',
  CalculationMethod.north_america: 'ISNA (North America)',
  CalculationMethod.turkey: 'Türkiye (Diyanet)',
  CalculationMethod.tehran: 'University of Tehran',
};

List<CalculationMethod> get selectableMethods =>
    calculationMethodLabels.keys.toList(growable: false);

extension MadhabLabel on Madhab {
  String get label => this == Madhab.hanafi
      ? 'Hanafi'
      : 'Standard (Shafi, Maliki, Hanbali)';

  String get asrHint => this == Madhab.hanafi
      ? 'Asr begins when an object\'s shadow is twice its length'
      : 'Asr begins when an object\'s shadow equals its length';
}
