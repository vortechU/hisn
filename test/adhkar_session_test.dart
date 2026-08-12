import 'package:dua_app/models/dua.dart';
import 'package:dua_app/services/adhkar_audio_library.dart';
import 'package:dua_app/services/adhkar_session.dart';
import 'package:dua_app/services/dua_progress_service.dart';
import 'package:dua_app/services/muhassan_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The playlist a hands-free session plays: repetition expansion, the pauses
/// between them, the long dhikr held back, and where a resumed session picks
/// up. This is the part that decides whether listening and tapping agree, and
/// it is pure Dart — no player, no platform.
Dua _dua(String id, {int repeat = 1, String category = 'morning'}) => Dua(
      id: id,
      categoryId: category,
      title: id,
      arabic: 'ذكر',
      transliteration: '',
      translation: '',
      reference: '',
      repeat: repeat,
    );

/// A library covering [ids], one file each.
AdhkarAudioLibrary _library(List<String> ids, {bool silence = true}) =>
    AdhkarAudioLibrary.forTest(
      {for (final id in ids) id: 'assets/audio/adhkar/$id.m4a'},
      silence: silence,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('playlist construction', () {
    test('a dua repeated n times becomes n steps over one file', () {
      final duas = [_dua('a', repeat: 3)];
      final session = AdhkarSession.build(
        categoryId: 'morning',
        categoryDuas: duas,
        library: _library(['a']),
        gapSteps: 0,
      );

      expect(session.steps.length, 3);
      expect(session.steps.map((s) => s.repIndex), [0, 1, 2]);
      // One recording, played three times — not three recordings.
      expect(session.steps.map((s) => s.asset).toSet().length, 1);
      // Only the last repetition finishes the dua.
      expect(session.steps.map((s) => s.completesDua), [false, false, true]);
      expect(session.duas, hasLength(1));
    });

    test('duas keep the order of the set, each numbered by position', () {
      final duas = [_dua('a'), _dua('b', repeat: 2), _dua('c')];
      final session = AdhkarSession.build(
        categoryId: 'morning',
        categoryDuas: duas,
        library: _library(['a', 'b', 'c']),
        gapSteps: 0,
      );

      expect(session.steps.map((s) => s.dua!.id), ['a', 'b', 'b', 'c']);
      expect(session.steps.map((s) => s.duaOrdinal), [0, 1, 1, 2]);
      expect(session.indexOfDua(2), 3);
    });

    test('a dua with no recording is named, not silently dropped', () {
      final duas = [_dua('a'), _dua('b'), _dua('c')];
      final session = AdhkarSession.build(
        categoryId: 'morning',
        categoryDuas: duas,
        // 'b' was never recorded.
        library: _library(['a', 'c']),
        gapSteps: 0,
      );

      expect(session.missing.map((d) => d.id), ['b']);
      expect(session.duas.map((d) => d.id), ['a', 'c']);
      // The ordinals renumber over what is actually recited, so the lock
      // screen counts "2 / 2" rather than skipping a number.
      expect(session.steps.map((s) => s.duaOrdinal), [0, 1]);
    });

    test('pauses separate repetitions but never trail the set', () {
      final session = AdhkarSession.build(
        categoryId: 'morning',
        categoryDuas: [_dua('a', repeat: 2)],
        library: _library(['a']),
        gapSteps: 2,
      );

      // recite, pause, pause, recite — and nothing after the last word, so the
      // notification doesn't sit open on silence.
      expect(session.steps.map((s) => s.isPause), [false, true, true, false]);
    });

    test('without the silence asset the steps simply run back to back', () {
      final session = AdhkarSession.build(
        categoryId: 'morning',
        categoryDuas: [_dua('a', repeat: 2)],
        library: _library(['a'], silence: false),
        gapSteps: 3,
      );

      expect(session.steps.every((s) => !s.isPause), isTrue);
      expect(session.steps.length, 2);
    });
  });

  group('the long dhikr', () {
    final duas = [
      _dua('short', repeat: 3),
      _dua('tahlil', repeat: MuhassanService.highRepeatThreshold),
    ];

    test('are left out of the body by default', () {
      final session = AdhkarSession.build(
        categoryId: 'morning',
        categoryDuas: duas,
        library: _library(['short', 'tahlil']),
        gapSteps: 0,
      );

      // Three steps, not a hundred and three.
      expect(session.steps.length, 3);
      expect(session.duas.map((d) => d.id), ['short']);
      expect(session.appendixDuas, isEmpty);
      // Not "missing" — it has a recording, it is just held back.
      expect(session.missing, isEmpty);
    });

    test('are appended, and marked as the tail, when asked for', () {
      final session = AdhkarSession.build(
        categoryId: 'morning',
        categoryDuas: duas,
        library: _library(['short', 'tahlil']),
        gapSteps: 0,
        includeAppendix: true,
      );

      expect(session.steps.length, 3 + MuhassanService.highRepeatThreshold);
      expect(session.appendixDuas.map((d) => d.id), ['tahlil']);
      // The body comes first and is not marked as the tail.
      expect(session.steps.take(3).every((s) => !s.appendix), isTrue);
      expect(session.steps.skip(3).every((s) => s.appendix), isTrue);
    });
  });

  group('resuming', () {
    final duas = [_dua('a', repeat: 2), _dua('b', repeat: 3)];
    AdhkarSession build() => AdhkarSession.build(
          categoryId: 'morning',
          categoryDuas: duas,
          library: _library(['a', 'b']),
          gapSteps: 0,
        );

    test('a fresh set starts at the beginning', () {
      expect(build().startIndex((_) => 0), 0);
    });

    test('picks up on the repetition the reader stopped at', () {
      // 'a' said twice (done), 'b' said once of three.
      final counts = {'a': 2, 'b': 1};
      final session = build();
      // Steps are a0 a1 b0 b1 b2 — resume on b's second repetition.
      expect(session.startIndex((id) => counts[id] ?? 0), 3);
    });

    test('resumes at the earliest gap, not the furthest thing done', () {
      // 'b' was done first, out of order; 'a' is still outstanding.
      final counts = {'a': 0, 'b': 3};
      expect(build().startIndex((id) => counts[id] ?? 0), 0);
    });

    test('a finished set starts over rather than ending immediately', () {
      final counts = {'a': 2, 'b': 3};
      expect(build().startIndex((id) => counts[id] ?? 0), 0);
    });
  });

  test('an empty library yields nothing to play', () {
    final session = AdhkarSession.build(
      categoryId: 'morning',
      categoryDuas: [_dua('a'), _dua('b')],
      library: AdhkarAudioLibrary.empty(),
    );

    expect(session.isEmpty, isTrue);
    expect(session.missing, hasLength(2));
  });

  // The contract the whole feature rests on: a step recited aloud has to land
  // in exactly the same place a tap lands, or a set half-read and
  // half-listened-to would count twice or not at all.
  group('crediting a recited step', () {
    late DuaProgressService progress;
    late MuhassanService muhassan;

    final duas = [_dua('a', repeat: 2), _dua('b')];
    AdhkarSession build() => AdhkarSession.build(
          categoryId: MuhassanService.morningId,
          categoryDuas: duas,
          library: _library(['a', 'b']),
          gapSteps: 1,
        );

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      progress = DuaProgressService(prefs);
      muhassan = MuhassanService(prefs)..setEssential({'a', 'b'}, {'e'});
    });

    void credit(AdhkarSession s, int index) =>
        s.creditStep(index, progress: progress, muhassan: muhassan);

    test('advances the day\'s count one repetition at a time', () {
      final session = build();
      expect(progress.countOf('a'), 0);

      credit(session, 0); // a, first repetition
      expect(progress.countOf('a'), 1);
      // The dua is not finished, so it must not count toward the day yet.
      expect(muhassan.morningCount, 0);

      credit(session, 2); // a, second repetition (index 1 is the pause)
      expect(progress.countOf('a'), 2);
      expect(muhassan.morningCount, 1);
    });

    test('a pause credits nothing', () {
      final session = build();
      credit(session, 1); // the silence between a's repetitions
      expect(progress.countOf('a'), 0);
      expect(muhassan.morningCount, 0);
    });

    test('crediting the same step twice is harmless', () {
      final session = build();
      credit(session, 0);
      credit(session, 0);
      expect(progress.countOf('a'), 1);

      credit(session, 4); // b, its only repetition
      credit(session, 4);
      expect(progress.countOf('b'), 1);
      expect(muhassan.morningCount, 1); // b counted once, not twice
    });

    test('never walks a count backwards past what was tapped', () {
      final session = build();
      // The reader already tapped 'a' through both repetitions by hand.
      progress.setCount('a', 2);
      credit(session, 0); // recitation only reaches the first
      expect(progress.countOf('a'), 2, reason: 'their tally stands');
    });

    test('an out-of-range step is ignored rather than throwing', () {
      final session = build();
      expect(() => credit(session, -1), returnsNormally);
      expect(() => credit(session, 999), returnsNormally);
    });
  });

  test('completedBefore counts duas finished, not repetitions played', () {
    final session = AdhkarSession.build(
      categoryId: 'morning',
      categoryDuas: [_dua('a', repeat: 3), _dua('b')],
      library: _library(['a', 'b']),
      gapSteps: 0,
    );

    expect(session.completedBefore(0), 0);
    expect(session.completedBefore(2), 0); // two of a's three repetitions
    expect(session.completedBefore(3), 1); // a finished
    expect(session.completedBefore(4), 2); // b finished
  });
}
