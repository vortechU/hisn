import 'dart:convert';

import 'package:dua_app/data/dua_repository.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Map<String, dynamic> overlay;
  late DuaRepository repository;

  setUpAll(() async {
    overlay = jsonDecode(await rootBundle.loadString('assets/data/duas.ur.json'))
        as Map<String, dynamic>;
    repository = DuaRepository();
    await repository.load();
  });

  test('every current dua has Urdu fields without English fallback', () {
    expect(overlay.keys.where((id) => id != '_meta').toSet(),
        repository.duas.map((dua) => dua.id).toSet());
    for (final dua in repository.duas) {
      final entry = overlay[dua.id] as Map<String, dynamic>;
      for (final field in ['title', 'translation', 'reference',
        if (dua.virtue != null) 'virtue',
        if (dua.instruction != null) 'instruction']) {
        expect(entry[field], isA<String>(), reason: '${dua.id}.$field');
        expect((entry[field] as String).trim(), isNotEmpty,
            reason: '${dua.id}.$field');
        expect(entry[field], isNot(matches(RegExp('[A-Za-z]'))),
            reason: '${dua.id}.$field retains Latin text');
      }
      expect(repository.duaById(dua.id)!.translationFor('ur'), entry['translation']);
      expect(repository.duaById(dua.id)!.referenceFor('ur'), entry['reference']);
      if (dua.instruction != null) {
        expect(dua.instructionFor('ur'), entry['instruction']);
      }
    }
  });

  test('Quran meanings retain exact translator text and visible provenance', () async {
    final meta = overlay['_meta'] as Map<String, dynamic>;
    expect(meta['status'], contains('DRAFT'));
    expect(meta['authorship'], contains('original project'));
    final credit = meta['quran'] as Map<String, dynamic>;
    expect(credit['translator'], 'Muhammad Junagarhi');
    expect(credit['source'], 'https://tanzil.net/trans/ur.junagarhi');
    Future<List<dynamic>> ayahs(int surah) async =>
        (jsonDecode(await rootBundle.loadString(
          'assets/data/quran/trans/ur/surah_$surah.json')) as Map<String, dynamic>)['ayahs']
            as List<dynamic>;
    final kursi = (await ayahs(2))[254];
    for (final prefix in ['morning', 'evening', 'salah', 'sleep']) {
      expect((overlay['${prefix}_ayat_kursi'] as Map)['translation'], kursi);
      for (final (name, number) in [('ikhlas', 112), ('falaq', 113), ('nas', 114)]) {
        final translation = (overlay['${prefix}_$name'] as Map)['translation'] as String;
        for (final verse in await ayahs(number)) {
          expect(translation, contains(verse));
        }
      }
    }
    final waking = (overlay['waking_imran_190_200'] as Map)['translation'] as String;
    final imran = await ayahs(3);
    for (var i = 189; i < 200; i++) {
      expect(waking, contains(imran[i]));
    }
  });
}
