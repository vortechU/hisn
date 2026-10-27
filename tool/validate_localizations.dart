import 'dart:convert';
import 'dart:io';

import 'package:dua_app/data/content_overlay.dart';
import 'package:dua_app/l10n/app_language.dart';
import 'sync_native_localizations.dart';

const _pluralForms = {'zero', 'one', 'two', 'few', 'many', 'other'};
const contentFields = {
  'duas': {'title', 'translation', 'virtue', 'instruction', 'reference'},
  'categories': {'title', 'subtitle'},
  'tasbih': {'translation'},
};

Set<String> _parameters(String value) => RegExp(
  r'\$(?:\{([A-Za-z_]\w*)\}|([A-Za-z_]\w*))',
).allMatches(value).map((match) => match[1] ?? match[2]!).toSet();

/// Checks structure, non-empty text and placeholders. Plural categories may
/// differ by language; zero/one/two may omit the count for natural wording.
List<String> validateCatalog(
  Object? base,
  Object? translated, [
  String path = '',
]) {
  final problems = <String>[];
  void compare(Object? source, Object? target, String key) {
    if (source is String) {
      if (target is! String || target.trim().isEmpty) {
        problems.add('$key: expected non-empty text');
      } else if (!_same(_parameters(source), _parameters(target))) {
        problems.add('$key: placeholders differ');
      }
    } else if (source is List) {
      if (target is! List || source.length != target.length) {
        problems.add('$key: list length differs');
        return;
      }
      for (var i = 0; i < source.length; i++) {
        compare(source[i], target[i], '$key[$i]');
      }
    } else if (source is Map) {
      if (target is! Map) {
        problems.add('$key: expected an object');
        return;
      }
      final sourceKeys = source.keys.cast<String>().toSet();
      final targetKeys = target.keys.cast<String>().toSet();
      if (sourceKeys.contains('other') &&
          _pluralForms.containsAll(sourceKeys)) {
        if (!targetKeys.contains('other') ||
            !_pluralForms.containsAll(targetKeys)) {
          problems.add('$key: invalid plural categories or missing other');
        }
        final expected = source.values
            .whereType<String>()
            .expand(_parameters)
            .toSet();
        final count = RegExp(r'param=(\w+)').firstMatch(key)?[1] ?? 'n';
        for (final entry in target.entries) {
          final value = entry.value;
          final required = {...expected};
          if (const {'zero', 'one', 'two'}.contains(entry.key)) {
            required.remove(count);
          }
          if (value is! String ||
              value.trim().isEmpty ||
              !expected.containsAll(_parameters(value)) ||
              !_parameters(value).containsAll(required)) {
            problems.add('$key.${entry.key}: invalid plural text/placeholders');
          }
        }
      } else {
        for (final missing in sourceKeys.difference(targetKeys)) {
          problems.add('$key.$missing: missing key');
        }
        for (final extra in targetKeys.difference(sourceKeys)) {
          problems.add('$key.$extra: unknown key');
        }
        for (final child in sourceKeys.intersection(targetKeys)) {
          compare(
            source[child],
            target[child],
            key.isEmpty ? child : '$key.$child',
          );
        }
      }
    } else {
      problems.add('$key: unsupported catalog value');
    }
  }

  compare(base, translated, path);
  return problems;
}

bool _same(Set<String> a, Set<String> b) =>
    a.length == b.length && a.containsAll(b);

/// Validates all shipped languages against the registry, including asset
/// registration and generated native data. Run from the project root.
List<String> localizationProblems() {
  final problems = <String>[];
  final manifest = File('pubspec.yaml').readAsStringSync();
  final assets = RegExp(
    r'^\s*-\s+(assets/[^\s#]+)\s*$',
    multiLine: true,
  ).allMatches(manifest).map((match) => match[1]!).toSet();
  bool bundled(String asset) => assets.any(
    (entry) =>
        entry == asset ||
        (entry.endsWith('/') &&
            asset.startsWith(entry) &&
            !asset.substring(entry.length).contains('/')),
  );
  Object? read(String path) => jsonDecode(File(path).readAsStringSync());
  void check(String label, void Function() action) {
    try {
      action();
    } catch (error) {
      problems.add('$label: $error');
    }
  }

  final base = read('lib/i18n/en.i18n.json');
  final registered = AppLang.values.map((language) => language.code).toSet();
  for (final file in Directory('lib/i18n').listSync().whereType<File>()) {
    if (!file.path.endsWith('.i18n.json')) continue;
    final code = file.uri.pathSegments.last.replaceFirst('.i18n.json', '');
    if (!registered.contains(code)) {
      problems.add('Unregistered UI catalog: $code');
    }
  }
  for (final language in AppLang.values) {
    check(language.code, () {
      problems.addAll(
        validateCatalog(
          base,
          read('lib/i18n/${language.code}.i18n.json'),
        ).map((problem) => '${language.code}: $problem'),
      );
      if (!manifest.contains('family: ${language.uiFontFamily}')) {
        problems.add(
          '${language.code}: unbundled UI font ${language.uiFontFamily}',
        );
      }
    });
    for (final dataset in language.overlays.entries) {
      final asset = language.overlayAsset(dataset.key);
      check(asset, () {
        if (!bundled(asset)) {
          problems.add('$asset: not registered in pubspec.yaml');
        }
        final allowed = contentFields[dataset.key];
        if (allowed == null || !allowed.containsAll(dataset.value)) {
          throw const FormatException('Unknown dataset or required fields');
        }
        final overlay = decodeContentOverlay(
          File(asset).readAsStringSync(),
          allowedFields: allowed,
        );
        final entries = (read('assets/data/${dataset.key}.json') as List)
            .cast<Map<String, dynamic>>();
        if (!_same(
          overlay.keys.toSet(),
          entries.map((entry) => entry['id'] as String).toSet(),
        )) {
          problems.add('$asset: entry IDs differ from the base dataset');
        }
        for (final entry in entries) {
          for (final field in dataset.value) {
            if (entry[field] == null) continue;
            if (overlay[entry['id']]?[field] == null) {
              problems.add('$asset: missing ${entry['id']}.$field');
            }
          }
        }
      });
    }
  }
  // A new overlay must be declared, otherwise it would never be loaded.
  for (final dataset in contentFields.keys) {
    for (final file in Directory('assets/data').listSync().whereType<File>()) {
      final match = RegExp(
        '^$dataset\\.([a-z]+)\\.json\$',
      ).firstMatch(file.uri.pathSegments.last);
      if (match == null) continue;
      if (AppLang.tryFromCode(match[1])?.overlays.containsKey(dataset) !=
          true) {
        problems.add('Undeclared overlay: ${file.path}');
      }
    }
  }
  check(nativeLocalizationAsset, () {
    if (!bundled(nativeLocalizationAsset)) {
      problems.add('Native localizations are not bundled');
    }
    if (jsonEncode(read(nativeLocalizationAsset)) !=
        jsonEncode(nativeLocalizations())) {
      problems.add(
        'Native localizations are stale; run dart run tool/sync_native_localizations.dart',
      );
    }
  });
  return problems;
}

void main() {
  final problems = localizationProblems();
  if (problems.isEmpty) {
    stdout.writeln(
      'Validated ${AppLang.values.length} languages, catalogs, content overlays and native localizations.',
    );
  } else {
    stderr.writeln(problems.join('\n'));
    exitCode = 1;
  }
}
