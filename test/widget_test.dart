import 'package:flutter_test/flutter_test.dart';

import 'package:dua_app/data/dua_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DuaRepository', () {
    late DuaRepository repo;

    setUp(() async {
      repo = DuaRepository();
      await repo.load();
    });

    test('loads categories, duas, and dhikr from assets', () {
      expect(repo.categories, isNotEmpty);
      expect(repo.duas, isNotEmpty);
      expect(repo.dhikr, isNotEmpty);
    });

    test('every dua belongs to a known category', () {
      final ids = repo.categories.map((c) => c.id).toSet();
      for (final dua in repo.duas) {
        expect(ids, contains(dua.categoryId),
            reason: '${dua.id} has unknown category ${dua.categoryId}');
      }
    });

    test('duasForCategory filters correctly', () {
      for (final category in repo.categories) {
        final duas = repo.duasForCategory(category.id);
        expect(duas.every((d) => d.categoryId == category.id), isTrue);
        expect(duas.length, repo.countForCategory(category.id));
      }
    });

    test('morning & evening adhkar include the full well-known set', () {
      // Guards the expanded Hisn al-Muslim content (see
      // tool/add_morning_evening_adhkar.py).
      expect(repo.countForCategory('morning'), greaterThanOrEqualTo(19));
      expect(repo.countForCategory('evening'), greaterThanOrEqualTo(17));
      const expected = [
        'morning_ushhiduka', 'morning_fitrah', 'morning_ya_hayyu',
        'morning_salah_nabi', 'evening_ushhiduka', 'evening_fitrah',
        'evening_ya_hayyu', 'evening_salah_nabi',
      ];
      final ids = repo.duas.map((d) => d.id).toSet();
      for (final id in expected) {
        expect(ids, contains(id));
      }
      // Every dua must keep a source reference (authenticity rule).
      for (final dua in repo.duas) {
        expect(dua.reference.trim(), isNotEmpty, reason: '${dua.id} has no reference');
      }
    });
  });
}
