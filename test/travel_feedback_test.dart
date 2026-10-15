import 'package:dua_app/data/dua_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('journey supplication includes all clauses of Muslim 1342', () async {
    final repo = DuaRepository();
    await repo.load();
    final dua = repo.duaById('travel_setting_off')!;
    final arabic = dua.arabic.replaceAll(RegExp(r'[\u064B-\u065F\u0670]'), '');

    // These successive clauses were omitted from the original travel card.
    final clauses = [
      'اللهم هون علينا سفرنا هذا واطو عنا بعده',
      'اللهم أنت الصاحب في السفر والخليفة في الأهل',
      'اللهم إني أعوذ بك من وعثاء السفر',
      'وكآبة المنظر',
      'وسوء المنقلب في المال والأهل',
    ];
    var previous = -1;
    for (final clause in clauses) {
      final position = arabic.indexOf(clause);
      expect(position, greaterThan(previous), reason: clause);
      previous = position;
    }
    expect(dua.translation, contains('shorten its distance'));
    expect(dua.translation, contains('guardian of our family'));
    expect(dua.translation, contains('property and family'));
    expect(dua.transliteration, contains("watwi 'anna bu'dah"));
    expect(dua.transliteration, contains('wal-khalifatu fil-ahl'));
    expect(dua.transliteration, contains('fil-mali wal-ahl'));
    expect(dua.translationFor('id'), contains('dekatkanlah jaraknya'));
    expect(dua.translationFor('id'), contains('penjaga keluarga'));
    expect(dua.translationFor('id'), contains('harta dan keluarga'));
    expect(dua.referenceFor('ar'), 'صحيح مسلم ١٣٤٢');
    expect(dua.reference, 'Sahih Muslim 1342');
    expect(dua.repeat, 1);
  });
}
