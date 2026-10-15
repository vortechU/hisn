import 'dart:convert';

import 'package:dua_app/data/dua_repository.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late DuaRepository repo;

  setUpAll(() async {
    repo = DuaRepository();
    await repo.load();
  });

  test(
    'post wudu testimony and eight gates reward precede going to mosque',
    () {
      final mosque = repo.duasForCategory('mosque');
      final afterWudu = mosque.indexWhere(
        (dua) => dua.id == 'mosque_after_wudu',
      );
      final going = mosque.indexWhere((dua) => dua.id == 'mosque_going');
      expect(afterWudu, greaterThanOrEqualTo(0));
      expect(afterWudu + 1, going);
      final dua = mosque[afterWudu];
      expect(dua.repeat, 1);
      expect(dua.arabic, contains('وَحْدَهُ لَا شَرِيكَ لَهُ'));
      expect(dua.reference, contains('234a, 234b'));
      expect(dua.virtue, contains('eight gates of Paradise'));
      expect(dua.virtueFor('ar'), contains('أبواب الجنة الثمانية'));
      expect(dua.virtueFor('id'), contains('delapan pintu surga'));
      expect(dua.virtueFor('ur'), contains('آٹھوں دروازے'));
    },
  );

  test(
    'waking face wipe is guidance with its source, separate from recitation',
    () {
      final dua = repo.duaById('waking_alhamdulillah_ahyana')!;
      expect(dua.categoryId, 'waking');
      expect(dua.arabic, startsWith('الْحَمْدُ لِلَّهِ'));
      expect(dua.arabic, isNot(contains('امسح')));
      expect(dua.reference, contains('6312'));
      expect(dua.reference, contains('183'));
      expect(dua.instruction, contains('wipe the traces of sleep'));
      expect(dua.instruction, contains('not words to recite'));
      expect(dua.instructionFor('ar'), contains('هذا عمل وليس دعاءً'));
      expect(dua.instructionFor('id'), contains('tindakan, bukan bacaan doa'));
      expect(dua.instructionFor('ur'), contains('یہ ایک عمل ہے'));
    },
  );

  test(
    'all shipped overlays explicitly include the new guidance and virtue',
    () async {
      for (final lang in ['ar', 'id', 'ur']) {
        final overlay =
            jsonDecode(
                  await rootBundle.loadString('assets/data/duas.$lang.json'),
                )
                as Map<String, dynamic>;
        expect(
          overlay['mosque_after_wudu']['virtue'],
          isNotEmpty,
          reason: lang,
        );
        expect(
          overlay['waking_alhamdulillah_ahyana']['instruction'],
          isNotEmpty,
          reason: lang,
        );
        if (lang != 'ar') {
          expect(
            overlay['mosque_after_wudu']['translation'],
            isNotEmpty,
            reason: lang,
          );
        }
      }
    },
  );
}
