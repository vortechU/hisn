import 'package:dua_app/data/dua_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DuaRepository repo;

  setUpAll(() async {
    repo = DuaRepository();
    await repo.load();
  });

  String unvowelled(String text) =>
      text.replaceAll(RegExp(r'[\u064B-\u065F\u0670]'), '');

  test('adhan testimony retains its complete distinct Muslim 386 wording', () {
    final testimony = repo.duaById('mosque_adhan_testimony');
    expect(testimony, isNotNull);
    final dua = testimony!;
    expect(dua.categoryId, 'mosque');
    expect(dua.reference, 'Sahih Muslim 386');
    expect(dua.repeat, 1);
    final text = unvowelled(dua.arabic);
    expect(text, startsWith('وأنا أشهد'));
    expect(text, contains('وحده لا شريك له'));
    expect(text, contains('وأن محمدا عبده ورسوله'));
    expect(text, contains('وبمحمد رسولا'));
    expect(text, contains('وبالإسلام دينا'));
    expect(text, isNot(contains('نبيا')));
    expect(dua.virtue, contains('when hearing'));
  });

  test('testimony is placed after the shahadatayn, before Hayya', () {
    final ids = repo.duasForCategory('mosque').map((d) => d.id).toList();
    expect(
      ids.indexOf('mosque_adhan_testimony'),
      lessThan(ids.indexOf('mosque_adhan_response_hayya')),
    );
    final testimony = repo.duaById('mosque_adhan_testimony')!;
    expect(testimony.instruction, contains('two testimonies'));
    expect(
      testimony.instructionFor('ar'),
      'يُقال بعد انتهاء المؤذن من الشهادتين، قبل قوله: حي على الصلاة.',
    );
  });

  test('salawat follows the adhan response and precedes al-Wasilah', () {
    final mosque = repo.duasForCategory('mosque');
    final ids = mosque.map((d) => d.id).toList();
    final salawat = repo.duaById('mosque_after_adhan_salawat');
    expect(salawat, isNotNull);
    expect(
      ids.indexOf('mosque_adhan_response_hayya'),
      lessThan(ids.indexOf('mosque_after_adhan_salawat')),
    );
    expect(
      ids.indexOf('mosque_after_adhan_salawat') + 1,
      ids.indexOf('mosque_after_adhan'),
    );
    expect(salawat!.reference, 'Sahih Muslim 384, 406');
    expect(salawat.repeat, 1);
    expect(
      salawat.virtue,
      contains('does not require this particular formula'),
    );
    final text = unvowelled(salawat.arabic);
    expect(text, contains('اللهم صل على محمد وعلى آل محمد'));
    expect(text, contains('اللهم بارك على محمد وعلى آل محمد'));
    expect(
      repo.duaById('mosque_after_adhan')!.reference,
      'Sahih al-Bukhari 614',
    );
  });

  test('new adhan cards have Arabic and Indonesian content', () {
    for (final id in ['mosque_adhan_testimony', 'mosque_after_adhan_salawat']) {
      final dua = repo.duaById(id)!;
      expect(dua.referenceFor('ar'), isNot(matches(RegExp('[A-Za-z]'))));
      expect(dua.virtueFor('ar'), isNot(dua.virtue));
      expect(dua.translationFor('id'), isNot(dua.translation));
      expect(dua.virtueFor('id'), isNot(dua.virtue));
    }
    expect(repo.duas.map((d) => d.id).toSet(), hasLength(repo.duas.length));
  });
}
