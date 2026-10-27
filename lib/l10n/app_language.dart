/// Language metadata shared by the app and the native-localization generator.
/// Add a catalog and register its presentation and content coverage here.
enum AppLang {
  en('English'),
  ar(
    'العربية',
    rtl: true,
    usesArabicScript: true,
    arabicDigits: true,
    geocoderLocale: 'ar',
    overlays: {
      'duas': {'virtue', 'instruction', 'reference'},
    },
  ),
  id(
    'Bahasa Indonesia',
    geocoderLocale: 'id',
    overlays: {
      'duas': {'translation', 'virtue', 'instruction'},
    },
  ),
  ur(
    'اردو',
    rtl: true,
    usesArabicScript: true,
    uiFontFamily: 'Noto Naskh Arabic',
    nativeUiFontFamily: 'sans-serif',
    overlays: {
      'duas': {'title', 'translation', 'virtue', 'instruction', 'reference'},
      'categories': {'title', 'subtitle'},
      'tasbih': {'translation'},
    },
  ),
  sq(
    'Shqip',
    geocoderLocale: 'sq',
    overlays: {
      'duas': {'title', 'translation', 'virtue', 'instruction', 'reference'},
      'categories': {'title', 'subtitle'},
      'tasbih': {'translation'},
    },
  );

  const AppLang(
    this.nativeName, {
    this.rtl = false,
    this.usesArabicScript = false,
    this.arabicDigits = false,
    this.uiFontFamily = 'Readex Pro',
    this.nativeUiFontFamily,
    this.geocoderLocale = 'en',
    this.overlays = const {},
  });

  final String nativeName;
  final bool rtl;
  final bool usesArabicScript;
  final bool arabicDigits;
  final String uiFontFamily;
  final String? nativeUiFontFamily;
  final String geocoderLocale;

  /// Dataset -> fields translated for every applicable built-in entry.
  /// Absent datasets deliberately use the base content.
  final Map<String, Set<String>> overlays;

  /// Stable code used by catalogs, assets and saved preferences.
  String get code => name;

  String overlayAsset(String dataset) => 'assets/data/$dataset.$code.json';

  static AppLang? tryFromCode(String? code) {
    for (final language in values) {
      if (language.code == code) return language;
    }
    return null;
  }

  static AppLang fromCode(String? code) => tryFromCode(code) ?? en;
}
