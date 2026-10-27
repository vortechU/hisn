// Run after changing language metadata or catalogs. --check detects stale output.
import 'dart:convert';
import 'dart:io';

import 'package:dua_app/l10n/app_language.dart';

const nativeLocalizationAsset = 'assets/data/native_localizations.json';
const nativeStringKeys = [
  'stopAdhan',
  'adhanPlaying',
  'durationMinutes',
  'durationHoursMinutes',
];

Map<String, Object?> nativeLocalizations() => {
  for (final language in AppLang.values)
    language.code: {
      'rtl': language.rtl,
      'isArabic': language == AppLang.ar,
      'arabicScript': language.usesArabicScript,
      'arabicDigits': language.arabicDigits,
      'fontFamily': language.nativeUiFontFamily,
      'strings': _stringsFor(language),
    },
};

Map<String, String> _stringsFor(AppLang language) {
  final catalog =
      jsonDecode(File('lib/i18n/${language.code}.i18n.json').readAsStringSync())
          as Map<String, dynamic>;
  return {for (final key in nativeStringKeys) key: catalog[key] as String};
}

void main(List<String> arguments) {
  final output =
      '${const JsonEncoder.withIndent('  ').convert(nativeLocalizations())}\n';
  final file = File(nativeLocalizationAsset);
  if (arguments.contains('--check')) {
    if (!file.existsSync() || file.readAsStringSync() != output) {
      stderr.writeln(
        'Native localizations are stale. Run dart run tool/sync_native_localizations.dart',
      );
      exitCode = 1;
    }
  } else {
    file.writeAsStringSync(output);
    stdout.writeln('Updated $nativeLocalizationAsset');
  }
}
