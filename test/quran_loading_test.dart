import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dua_app/data/quran_repository.dart';

class _RetryBundle extends CachingAssetBundle {
  _RetryBundle(this.failOn);
  final String failOn;
  var failed = false;
  @override
  Future<ByteData> load(String key) => rootBundle.load(key);
  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    if (key == failOn && !failed) {
      failed = true;
      throw StateError('temporary asset failure');
    }
    return rootBundle.loadString(key, cache: cache);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'simultaneous surah, meaning and edition requests share decoded results',
    () async {
      final repo = QuranRepository();
      final surahs = await Future.wait([repo.loadSurah(2), repo.loadSurah(2)]);
      expect(identical(surahs[0], surahs[1]), isTrue);
      final editions = await Future.wait([
        repo.loadEditions(),
        repo.loadEditions(),
      ]);
      expect(identical(editions[0], editions[1]), isTrue);
      final meanings = await Future.wait([
        repo.loadTranslation(2, 'en'),
        repo.loadTranslation(2, 'en'),
      ]);
      expect(identical(meanings[0], meanings[1]), isTrue);
    },
  );

  test(
    'failed reads do not poison the index, page, surah or meaning cache',
    () async {
      for (final asset in [
        'assets/data/quran/surahs.json',
        'assets/data/mushaf/020.json',
        'assets/data/quran/surah_2.json',
        'assets/data/quran/trans/editions.json',
        'assets/data/quran/trans/en/surah_2.json',
      ]) {
        final repo = QuranRepository(bundle: _RetryBundle(asset));
        Future<Object?> load() => switch (asset) {
          'assets/data/quran/surahs.json' => repo.loadIndex(),
          'assets/data/mushaf/020.json' => repo.loadPage(20),
          'assets/data/quran/surah_2.json' => repo.loadSurah(2),
          'assets/data/quran/trans/editions.json' => repo.loadEditions(),
          _ => repo.loadTranslation(2, 'en'),
        };
        await expectLater(load(), throwsStateError, reason: asset);
        await expectLater(load(), completes, reason: asset);
      }
    },
  );
}
