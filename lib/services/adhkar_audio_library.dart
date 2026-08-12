import 'dart:convert';

import 'package:flutter/services.dart' show AssetManifest, rootBundle;

import '../models/dua.dart';

/// What recitation the app actually ships, and which dua each recording belongs
/// to.
///
/// Audio is deliberately kept out of `duas.json`: the Arabic text of a dua is
/// content, a recording of it is one reciter's rendering of that content. Held
/// apart, a second reciter is a data change — another entry in
/// `assets/data/adhkar_audio.json` — rather than a second field on every dua.
///
/// The mapping is many ids to one file. Eleven of the thirty-six morning and
/// evening entries are the same Arabic word for word, so they share a
/// recording; the near-misses that differ only by *aṣbaḥtu* / *amsaytu* do not.
///
/// Coverage is checked against the real asset manifest at load, so an entry
/// naming a file that was never added is dropped rather than left to fail
/// halfway through a session. With nothing covered, [hasAnyAudio] is false and
/// every listening affordance in the app hides itself — which is how the
/// feature ships before the recordings do.
class AdhkarAudioLibrary {
  AdhkarAudioLibrary._(this._files, this.reciterName, this.reciterNameArabic);

  /// An empty library — nothing recorded. Used as the default and in tests.
  AdhkarAudioLibrary.empty()
      : _files = const {},
        reciterName = '',
        reciterNameArabic = '';

  /// Visible for testing: build a library from an explicit id → asset map.
  AdhkarAudioLibrary.forTest(
    Map<String, String> files, {
    String reciter = '',
    bool silence = true,
  })  : _files = Map.unmodifiable(files),
        reciterName = reciter,
        reciterNameArabic = reciter {
    _hasSilence = silence;
  }

  /// Dua id → full asset path (`assets/audio/adhkar/…`).
  final Map<String, String> _files;

  /// Who is reciting, for the media notification and the player screen. Empty
  /// when the manifest doesn't name anyone.
  final String reciterName;
  final String reciterNameArabic;

  static const _manifestPath = 'assets/data/adhkar_audio.json';
  static const _audioDir = 'assets/audio/adhkar/';

  /// A short pause, played between repetitions and between duas.
  ///
  /// A silent *track* rather than a timer: once the screen is off and the app
  /// is backgrounded Android is free to defer a `Timer`, and a gap that
  /// sometimes lasts four seconds and sometimes forty is worse than no gap at
  /// all. Handing the silence to the player keeps the pause exactly as long as
  /// it is meant to be, and keeps the notification's progress bar honest.
  static const silenceAsset = '${_audioDir}silence_1s.m4a';

  /// Whether the bundled silence used for pauses is present. Without it the
  /// session simply runs its steps back to back.
  bool get hasSilence => _hasSilence;
  bool _hasSilence = false;

  /// Reads the manifest and keeps only the entries whose file is really
  /// bundled. A missing or malformed manifest yields an empty library — the
  /// app runs exactly as it did before the feature existed.
  static Future<AdhkarAudioLibrary> load() async {
    try {
      final raw = await rootBundle.loadString(_manifestPath);
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final reciters = (decoded['reciters'] as List?) ?? const [];
      if (reciters.isEmpty) return AdhkarAudioLibrary.empty();

      // One reciter for now. The list is the shape a second one slots into.
      final reciter = reciters.first as Map<String, dynamic>;
      final declared = (reciter['files'] as Map?)?.cast<String, dynamic>() ??
          const <String, dynamic>{};

      final bundled = await _bundledAssets();
      final files = <String, String>{};
      declared.forEach((duaId, name) {
        if (name is! String || name.isEmpty) return;
        final path = '$_audioDir$name';
        if (bundled.contains(path)) files[duaId] = path;
      });

      final library = AdhkarAudioLibrary._(
        Map.unmodifiable(files),
        (reciter['name'] as String?) ?? '',
        (reciter['nameArabic'] as String?) ?? '',
      );
      library._hasSilence = bundled.contains(silenceAsset);
      return library;
    } catch (_) {
      return AdhkarAudioLibrary.empty();
    }
  }

  /// The set of asset paths actually in the bundle.
  ///
  /// [AssetManifest] can itself be absent in a stripped-down test harness, in
  /// which case nothing is claimed to exist and the library comes back empty.
  static Future<Set<String>> _bundledAssets() async {
    try {
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      return manifest.listAssets().toSet();
    } catch (_) {
      return const {};
    }
  }

  /// The asset for [duaId], or null when it has no recording.
  String? assetFor(String duaId) => _files[duaId];

  bool covers(String duaId) => _files.containsKey(duaId);

  /// Whether anything at all is recorded.
  bool get hasAnyAudio => _files.isNotEmpty;

  /// How many of [duas] can be recited.
  int coverageOf(Iterable<Dua> duas) =>
      duas.where((d) => covers(d.id)).length;

  /// Whether a set is worth offering to listen to.
  ///
  /// Any coverage will do rather than full coverage: a set that is missing one
  /// late recording should still be listenable, and the session marks what it
  /// could not recite instead of refusing to start.
  bool canPlay(Iterable<Dua> duas) => duas.any((d) => covers(d.id));
}
