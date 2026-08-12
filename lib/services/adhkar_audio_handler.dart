import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

import '../models/dua.dart';
import 'adhkar_audio_library.dart';
import 'adhkar_session.dart';
import 'dua_progress_service.dart';
import 'muhassan_service.dart';

/// Brings the media session up, once, for the life of the process.
///
/// Returns null where there is no session to bring up — a widget test, a
/// desktop or web build — in which case the app runs exactly as it did before
/// this feature existed and every listening affordance hides itself.
Future<AdhkarAudioHandler?> initAdhkarAudio() async {
  try {
    return await AudioService.init(
      builder: AdhkarAudioHandler.new,
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'com.vortech.dua_app.adhkar',
        androidNotificationChannelName: 'Adhkar recitation',
        androidNotificationIcon: 'mipmap/ic_launcher',
        // Kept in the foreground while paused as well. Pausing at a red light
        // and having the OS reclaim the service — losing your place in the set
        // — is the one failure this feature cannot afford.
        androidStopForegroundOnPause: false,
        androidNotificationOngoing: false,
      ),
    );
  } catch (_) {
    return null;
  }
}

/// Recites a set of adhkar aloud, advancing the day's counters as it goes.
///
/// This is the hands-free half of [DuaProgressService]: where
/// `CategoryDuasScreen` advances a dua by a tap, this advances it by having
/// finished saying it. Both end at the same two calls — `setCount` and
/// `markCompleted` — which is the whole reason listening and tapping can't
/// drift apart. Read half a set with your thumb, press play, and it carries on
/// from the next word.
///
/// It is an [AudioHandler], so playback survives the screen going off: Android
/// keeps the process alive for the media session's foreground service, and the
/// lock screen, headset buttons and car controls all drive it. Since
/// audio_service 0.18 the handler lives in the app's own isolate, so it can
/// write to the progress services directly rather than posting messages at a
/// second copy of today's state.
///
/// It is also a [ChangeNotifier] so the player screen can watch it the way the
/// rest of the app watches its services.
class AdhkarAudioHandler extends BaseAudioHandler
    with SeekHandler, ChangeNotifier {
  AdhkarAudioHandler() {
    _player.playbackEventStream.listen(_broadcast, onError: (Object _) {});

    // Credit a repetition only when the player *finished* it and moved on of
    // its own accord. `autoAdvance` is precisely that: just_audio suppresses
    // it while seeking, so pressing "next" to skip a dhikr you have already
    // said elsewhere doesn't quietly tick it off.
    _player.positionDiscontinuityStream.listen((d) {
      if (d.reason != PositionDiscontinuityReason.autoAdvance) return;
      final finished = d.previousEvent.currentIndex;
      if (finished != null) _credit(finished);
    }, onError: (Object _) {});

    _player.processingStateStream.listen((state) {
      if (state != ProcessingState.completed) return;
      // The last step never auto-advances — there is nothing after it — so it
      // is credited here instead.
      final session = _session;
      if (session != null) _credit(session.steps.length - 1);
      _finish();
    }, onError: (Object _) {});

    _player.currentIndexStream.listen((index) {
      if (index == null) return;
      _publishItem(index);
      notifyListeners();
    }, onError: (Object _) {});

    _player.playingStream.listen((_) => notifyListeners());
  }

  final AudioPlayer _player = AudioPlayer();

  AdhkarSession? _session;
  DuaProgressService? _progress;
  MuhassanService? _muhassan;
  String _setTitle = '';
  String _reciter = '';
  String Function(Dua dua)? _titleOf;

  /// The set currently loaded, or null when nothing is playing.
  AdhkarSession? get session => _session;

  bool get isPlaying => _player.playing;

  /// Where playback is in the current session's step list.
  int get currentIndex => _player.currentIndex ?? 0;

  /// The step being recited, or null between sessions.
  AdhkarStep? get currentStep {
    final steps = _session?.steps;
    if (steps == null || steps.isEmpty) return null;
    final i = currentIndex;
    return i >= 0 && i < steps.length ? steps[i] : null;
  }

  /// The dua being recited — the last real one, so a pause between
  /// repetitions doesn't blank the screen.
  Dua? get currentDua => _lastDua;
  Dua? _lastDua;

  /// How far through the position stream is, for the screen's own meter.
  Stream<Duration> get positionStream => _player.positionStream;

  /// Loads [duas] as a session and starts reciting.
  ///
  /// [progress] and [muhassan] are handed in rather than held for the life of
  /// the app because the provider tree is thrown away and rebuilt when a
  /// backup is restored (see `AppReload`); taking them per session means this
  /// always writes to the instances the app is actually showing.
  ///
  /// [titleOf] and [setTitle] arrive already localized — the handler has no
  /// `BuildContext` to look a language up with.
  Future<void> start({
    required String categoryId,
    required List<Dua> duas,
    required AdhkarAudioLibrary library,
    required DuaProgressService progress,
    required MuhassanService muhassan,
    required String setTitle,
    required String Function(Dua dua) titleOf,
    int gapSteps = 1,
    bool includeAppendix = false,
    bool resume = true,
  }) async {
    final session = AdhkarSession.build(
      categoryId: categoryId,
      categoryDuas: duas,
      library: library,
      gapSteps: gapSteps,
      includeAppendix: includeAppendix,
    );
    if (session.isEmpty) return;

    _session = session;
    _progress = progress;
    _muhassan = muhassan;
    _setTitle = setTitle;
    _reciter = library.reciterName;
    _titleOf = titleOf;
    _lastDua = null;

    final start = resume ? session.startIndex(progress.countOf) : 0;

    await _player.stop();
    await _player.setAudioSource(
      ConcatenatingAudioSource(
        children: [
          for (final step in session.steps) AudioSource.asset(step.asset),
        ],
      ),
      initialIndex: start,
      initialPosition: Duration.zero,
    );
    _publishItem(start);
    notifyListeners();
    await _player.play();
  }

  // ---- transport ----

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> stop() async {
    await _player.stop();
    _finish();
    await super.stop();
  }

  /// The next *dhikr*, not the next repetition.
  ///
  /// A steering-wheel or headset button should move you on to the next
  /// supplication; nudging through the repetitions of one is a fine-grained
  /// thing that belongs on the screen, where you can see what you're doing.
  @override
  Future<void> skipToNext() async {
    final session = _session;
    final step = currentStep;
    if (session == null || step == null) return;
    final ordinal = step.isPause ? _lastOrdinal : step.duaOrdinal;
    if (ordinal + 1 >= session.duas.length) return stop();
    await _seekToDua(session.indexOfDua(ordinal + 1));
  }

  /// Back to the start of this dhikr, or to the previous one if we only just
  /// began — the behaviour every music player has, and the one a thumb on a
  /// lock screen expects.
  @override
  Future<void> skipToPrevious() async {
    final session = _session;
    final step = currentStep;
    if (session == null || step == null) return;
    final ordinal = step.isPause ? _lastOrdinal : step.duaOrdinal;
    final atStart = _player.position < const Duration(seconds: 3) &&
        currentIndex <= session.indexOfDua(ordinal);
    final target = atStart && ordinal > 0 ? ordinal - 1 : ordinal;
    await _seekToDua(session.indexOfDua(target));
  }

  /// Restart the current repetition (in-app only — the lock screen has no
  /// button for it).
  Future<void> replayStep() => _player.seek(Duration.zero);

  Future<void> _seekToDua(int index) async {
    await _player.seek(Duration.zero, index: index);
    _publishItem(index);
    notifyListeners();
  }

  // ---- progress ----

  int _lastOrdinal = 0;

  /// Records that the step at [index] was recited in full.
  ///
  /// The rule itself lives on [AdhkarSession.creditStep], where it can be
  /// tested without a player underneath it.
  void _credit(int index) {
    final session = _session;
    final progress = _progress;
    final muhassan = _muhassan;
    if (session == null || progress == null || muhassan == null) return;
    session.creditStep(index, progress: progress, muhassan: muhassan);
  }

  /// Publishes what the lock screen shows for the step at [index].
  void _publishItem(int index) {
    final session = _session;
    if (session == null || index < 0 || index >= session.steps.length) return;
    final step = session.steps[index];
    // A pause keeps the previous dua on screen: blanking the notification for
    // a second of silence between repetitions reads as a fault.
    if (step.isPause) return;

    _lastDua = step.dua;
    _lastOrdinal = step.duaOrdinal;
    final dua = step.dua!;
    final total = session.duas.length;

    // Numerals and separators only — correct in every language without the
    // handler needing to know which one is on.
    final counter = '${step.duaOrdinal + 1} / $total';
    final line = dua.repeat > 1
        ? '$counter  ·  ${step.repIndex + 1}/${dua.repeat}'
        : counter;

    mediaItem.add(MediaItem(
      id: '${dua.id}#${step.repIndex}',
      title: _titleOf?.call(dua) ?? dua.title,
      artist: line,
      album: _reciter.isEmpty ? _setTitle : '$_setTitle · $_reciter',
      duration: _player.duration,
      displayDescription: dua.arabic,
    ));
  }

  void _finish() {
    _session = null;
    _progress = null;
    _muhassan = null;
    _lastDua = null;
    mediaItem.add(null);
    notifyListeners();
  }

  /// Mirrors just_audio's state onto the media session so the lock screen,
  /// the notification and any connected car head unit all show the truth.
  void _broadcast(PlaybackEvent event) {
    final playing = _player.playing;
    playbackState.add(playbackState.value.copyWith(
      controls: [
        MediaControl.skipToPrevious,
        if (playing) MediaControl.pause else MediaControl.play,
        MediaControl.skipToNext,
        MediaControl.stop,
      ],
      systemActions: const {MediaAction.seek},
      androidCompactActionIndices: const [0, 1, 2],
      processingState: switch (_player.processingState) {
        ProcessingState.idle => AudioProcessingState.idle,
        ProcessingState.loading => AudioProcessingState.loading,
        ProcessingState.buffering => AudioProcessingState.buffering,
        ProcessingState.ready => AudioProcessingState.ready,
        ProcessingState.completed => AudioProcessingState.completed,
      },
      playing: playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
      queueIndex: event.currentIndex,
    ));
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}
