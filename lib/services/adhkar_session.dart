import '../models/dua.dart';
import 'adhkar_audio_library.dart';
import 'dua_progress_service.dart';
import 'muhassan_service.dart';

/// One item in the playlist: either a recitation of a dua, or a pause.
///
/// A dua said three times is three steps over one file, not one step played
/// three times. Modelling every repetition separately is what lets the counter
/// advance in the middle of a dua, the lock screen say "2 of 3", and a resumed
/// session start on the exact repetition the reader stopped at.
class AdhkarStep {
  const AdhkarStep.recitation({
    required this.dua,
    required this.asset,
    required this.repIndex,
    required this.duaOrdinal,
    required this.appendix,
  });

  const AdhkarStep.pause({required this.asset})
      : dua = null,
        repIndex = -1,
        duaOrdinal = -1,
        appendix = false;

  /// The dua being recited; null for a pause.
  final Dua? dua;

  /// Asset path handed to the player.
  final String asset;

  /// Which repetition this is, zero-based. `-1` for a pause.
  final int repIndex;

  /// Position of this dua within the session's recitable duas, zero-based.
  /// Drives the "3 / 19" line on the lock screen.
  final int duaOrdinal;

  /// Whether this step belongs to the optional tail of long dhikr.
  final bool appendix;

  bool get isPause => dua == null;

  /// True on the last repetition — the step that finishes the dua and, for the
  /// morning and evening sets, credits it toward the day.
  bool get completesDua => dua != null && repIndex == dua!.repeat - 1;
}

/// A recited run through one category: which files play, in what order, and
/// where to pick up from.
///
/// Pure data. It touches neither the player nor the progress store, which is
/// what makes the ordering rules — repetition expansion, the long-dhikr tail,
/// resume — testable without a platform.
class AdhkarSession {
  AdhkarSession._({
    required this.categoryId,
    required this.steps,
    required this.duas,
    required this.missing,
    required this.appendixDuas,
  });

  final String categoryId;
  final List<AdhkarStep> steps;

  /// The duas that will actually be recited, in playing order.
  final List<Dua> duas;

  /// Duas in the category with no recording. Named so the player screen can
  /// say what it is going to leave out rather than silently dropping it.
  final List<Dua> missing;

  /// The long dhikr held back as an optional tail (empty unless included).
  final List<Dua> appendixDuas;

  bool get isEmpty => steps.isEmpty;

  /// Builds the playlist for [categoryDuas].
  ///
  /// [gapSteps] is how many one-second silences separate one recitation from
  /// the next; zero runs them back to back. Duas repeated
  /// [MuhassanService.highRepeatThreshold] times or more are held out of the
  /// body — a hundred tahlīl is a quarter of an hour of audio, and the streak
  /// already treats them as optional — and appended only when
  /// [includeAppendix] is set.
  factory AdhkarSession.build({
    required String categoryId,
    required List<Dua> categoryDuas,
    required AdhkarAudioLibrary library,
    int gapSteps = 1,
    bool includeAppendix = false,
  }) {
    final steps = <AdhkarStep>[];
    final playable = <Dua>[];
    final missing = <Dua>[];
    final appendixDuas = <Dua>[];

    final body = <Dua>[];
    final tail = <Dua>[];
    for (final dua in categoryDuas) {
      if (!library.covers(dua.id)) {
        missing.add(dua);
        continue;
      }
      (dua.repeat >= MuhassanService.highRepeatThreshold ? tail : body)
          .add(dua);
    }

    final pauses = library.hasSilence ? gapSteps : 0;

    void emit(List<Dua> group, {required bool appendix}) {
      for (final dua in group) {
        final ordinal = playable.length;
        playable.add(dua);
        if (appendix) appendixDuas.add(dua);
        final asset = library.assetFor(dua.id)!;
        for (var rep = 0; rep < dua.repeat; rep++) {
          steps.add(AdhkarStep.recitation(
            dua: dua,
            asset: asset,
            repIndex: rep,
            duaOrdinal: ordinal,
            appendix: appendix,
          ));
          for (var i = 0; i < pauses; i++) {
            steps.add(AdhkarStep.pause(asset: AdhkarAudioLibrary.silenceAsset));
          }
        }
      }
    }

    emit(body, appendix: false);
    if (includeAppendix) emit(tail, appendix: true);

    // A trailing pause would hold the notification open on silence after the
    // last word. Drop any that ended up at the end.
    while (steps.isNotEmpty && steps.last.isPause) {
      steps.removeLast();
    }

    return AdhkarSession._(
      categoryId: categoryId,
      steps: steps,
      duas: playable,
      missing: missing,
      appendixDuas: appendixDuas,
    );
  }

  /// Where to start, given what has already been counted today.
  ///
  /// The earliest repetition that has not been done — so tapping halfway
  /// through a set and then pressing play resumes at the right word, and a set
  /// that is already finished starts again from the top rather than ending
  /// immediately.
  ///
  /// [countOf] is [DuaProgressService.countOf]; taking it as a function keeps
  /// this class free of the service.
  int startIndex(int Function(String duaId) countOf) {
    for (var i = 0; i < steps.length; i++) {
      final step = steps[i];
      if (step.isPause) continue;
      if (countOf(step.dua!.id) <= step.repIndex) return i;
    }
    return 0;
  }

  /// Records the step at [index] as having been recited in full.
  ///
  /// This is the whole contract between listening and tapping: it ends at the
  /// same two calls `CategoryDuasScreen._tap` makes — [DuaProgressService
  /// .setCount] and, on the last repetition, [MuhassanService.markCompleted] —
  /// so a set half-read with a thumb and half-listened to on a walk is one
  /// set, not two tallies.
  ///
  /// Safe to call twice for the same step: the count is set absolutely rather
  /// than incremented, and `markCompleted` is itself idempotent.
  void creditStep(
    int index, {
    required DuaProgressService progress,
    required MuhassanService muhassan,
  }) {
    if (index < 0 || index >= steps.length) return;
    final step = steps[index];
    if (step.isPause) return;

    final dua = step.dua!;
    final reached = step.repIndex + 1;
    // Never walk a count backwards. A reader who tapped further ahead than the
    // recitation has reached keeps their tally.
    if (progress.countOf(dua.id) < reached) {
      progress.setCount(dua.id, reached);
    }
    if (step.completesDua) muhassan.markCompleted(categoryId, dua.id);
  }

  /// The index of the first step of the dua at [ordinal] — where "skip to the
  /// next dhikr" lands, as opposed to the next repetition.
  int indexOfDua(int ordinal) {
    for (var i = 0; i < steps.length; i++) {
      final step = steps[i];
      if (!step.isPause && step.duaOrdinal == ordinal) return i;
    }
    return 0;
  }

  /// How many duas are finished once playback reaches [index] — the number the
  /// session's progress rule shows.
  int completedBefore(int index) {
    final done = <String>{};
    for (var i = 0; i < index && i < steps.length; i++) {
      final step = steps[i];
      if (!step.isPause && step.completesDua) done.add(step.dua!.id);
    }
    return done.length;
  }
}
