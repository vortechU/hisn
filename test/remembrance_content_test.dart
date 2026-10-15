import 'dart:convert';

import 'package:dua_app/data/dua_repository.dart';
import 'package:dua_app/data/quran_repository.dart';
import 'package:dua_app/services/dua_progress_service.dart';
import 'package:dua_app/services/favorites_service.dart';
import 'package:dua_app/services/muhassan_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DuaRepository repo;
  late QuranRepository quran;

  setUpAll(() async {
    repo = DuaRepository();
    quran = QuranRepository();
    await Future.wait([repo.load(), quran.loadIndex()]);
  });

  String today() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
  }

  test(
    'each remembrance set contains three complete surahs with basmalah',
    () async {
      for (final group in {
        'morning': 'morning',
        'evening': 'evening',
        'after_salah': 'salah',
        'sleep': 'sleep',
      }.entries) {
        final entries = repo.duasForCategory(group.key);
        final first = entries.indexWhere(
          (d) => d.id == '${group.value}_ikhlas',
        );
        final cards = entries.skip(first).take(3).toList();
        expect(first, greaterThanOrEqualTo(0));
        expect(cards.map((d) => d.title), ['Al-Ikhlas', 'Al-Falaq', 'An-Nas']);
        expect(
          cards.map((d) => d.repeat),
          everyElement(group.key == 'after_salah' ? 1 : 3),
        );
        for (var i = 0; i < cards.length; i++) {
          final card = cards[i];
          final surah = await quran.loadSurah(112 + i);
          expect(card.arabic, startsWith('${QuranRepository.bismillah}\n\n'));
          expect(
            QuranRepository.bismillah.allMatches(card.arabic),
            hasLength(1),
          );
          for (final ayah in surah.ayahs) {
            expect(
              card.arabic,
              contains(ayah.text),
              reason: '${card.id}:${ayah.number}',
            );
          }
          // A card must carry only its own surah, not the former concatenation.
          for (var other = 112; other <= 114; other++) {
            if (other == 112 + i) continue;
            final unrelated = await quran.loadSurah(other);
            expect(card.arabic, isNot(contains(unrelated.ayahs.first.text)));
          }
          expect(card.referenceFor('ar'), isNot(matches(RegExp('[A-Za-z]'))));
          expect(card.translationFor('id'), contains(card.title));
        }
      }
      expect(repo.duas.map((d) => d.id).toSet(), hasLength(repo.duas.length));
    },
  );

  test('evening includes Ayat al-Kursi and the evening protection note', () {
    final evening = repo.duaById('evening_ayat_kursi')!;
    final morning = repo.duaById('morning_ayat_kursi')!;
    expect(evening.id, 'evening_ayat_kursi');
    expect(evening.categoryId, 'evening');
    expect(
      repo.duasForCategory('evening').where((d) => d.id == evening.id),
      hasLength(1),
    );
    expect(evening.arabic, morning.arabic);
    expect(evening.reference, "Qur'an 2:255");
    expect(evening.repeat, 1);
    expect(evening.virtue, contains('until morning'));
    expect(evening.virtueFor('ar'), contains('حتى يُصبح'));
    expect(evening.virtueFor('id'), contains('hingga pagi'));
    expect(evening.translationFor('id'), morning.translationFor('id'));
  });

  test(
    'old bookmarks resolve to all three cards, without duplicates',
    () async {
      SharedPreferences.setMockInitialValues({
        'favorite_dua_ids': [
          'morning_muawwidhat',
          'morning_falaq',
          'sleep_three_quls',
          'daily_leaving_home',
        ],
      });
      final prefs = await SharedPreferences.getInstance();
      final favorites = FavoritesService(prefs);
      final saved = repo.duasByIds(favorites.ids);
      expect(saved, hasLength(7));
      expect(
        saved.map((d) => d.title).where((t) => t == 'Al-Falaq'),
        hasLength(2),
      );
      expect(favorites.isFavorite('morning_muawwidhat'), isFalse);
      expect(favorites.isFavorite('daily_leaving_home'), isTrue);
      await favorites.toggle('morning_ikhlas');
      expect(FavoritesService(prefs).isFavorite('morning_ikhlas'), isFalse);
    },
  );

  test(
    'an upgrade carries shared counts over and respects individual counts',
    () async {
      SharedPreferences.setMockInitialValues({
        'dua_progress_day': today(),
        'dua_progress_counts': jsonEncode({
          'morning_muawwidhat': 2,
          'morning_falaq': 1,
          'evening_muawwidhat': 3,
          'salah_muawwidhat': 1,
          'sleep_three_quls': 2,
          'morning_ayat_kursi': 1,
        }),
      });
      final prefs = await SharedPreferences.getInstance();
      final progress = DuaProgressService(prefs);
      expect(progress.countOf('morning_ikhlas'), 2);
      expect(progress.countOf('morning_falaq'), 1);
      expect(progress.countOf('morning_nas'), 2);
      expect(progress.countOf('evening_ikhlas'), 3);
      expect(progress.countOf('salah_nas'), 1);
      expect(progress.countOf('sleep_falaq'), 2);
      expect(progress.countOf('morning_ayat_kursi'), 1);
      expect(progress.countOf('evening_ayat_kursi'), 0);
      progress.resetDuas(['morning_ikhlas', 'morning_falaq', 'morning_nas']);
      final reopened = DuaProgressService(prefs);
      expect(reopened.countOf('morning_ikhlas'), 0);
      expect(reopened.countOf('morning_falaq'), 0);
      expect(reopened.countOf('morning_nas'), 0);
    },
  );

  test(
    'yesterday\'s combined counts do not become today\'s progress',
    () async {
      SharedPreferences.setMockInitialValues({
        'dua_progress_day': '2000-01-01',
        'dua_progress_counts': jsonEncode({'morning_muawwidhat': 3}),
        'muhassan_day': '2000-01-01',
        'muhassan_morning': jsonEncode(['morning_muawwidhat']),
      });
      final prefs = await SharedPreferences.getInstance();
      final progress = DuaProgressService(prefs);
      final muhassan = MuhassanService(prefs)
        ..setEssential(
          {'morning_ikhlas', 'morning_falaq', 'morning_nas'},
          {'evening_ikhlas'},
        );
      expect(progress.countOf('morning_ikhlas'), 0);
      expect(muhassan.morningCount, 0);
    },
  );

  test('completed groups and streak history survive an upgrade', () async {
    SharedPreferences.setMockInitialValues({
      'muhassan_day': today(),
      'muhassan_morning': jsonEncode(['morning_muawwidhat']),
      'muhassan_evening': jsonEncode(['evening_muawwidhat']),
      'muhassan_streak': 7,
      'muhassan_best': 10,
      'muhassan_last': today(),
      'muhassan_history': jsonEncode([today()]),
      'muhassan_total': 15,
    });
    final prefs = await SharedPreferences.getInstance();
    MuhassanService load() => MuhassanService(prefs)
      ..setEssential(
        {'morning_ikhlas', 'morning_falaq', 'morning_nas'},
        {
          'evening_ayat_kursi',
          'evening_ikhlas',
          'evening_falaq',
          'evening_nas',
        },
      );
    final service = load();
    expect(service.morningCount, 3);
    expect(service.eveningCount, 3);
    expect(service.eveningDone, isFalse);
    expect(service.fortifiedToday, isTrue);
    expect(service.streak, 7);
    expect(service.best, 10);
    expect(service.totalFortified, 15);
    service.markCompleted('evening', 'evening_ayat_kursi');
    expect(load().eveningDone, isTrue);
    expect(load().streak, 7);
    expect(load().totalFortified, 15);
  });
}
