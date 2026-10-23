import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:file_selector/file_selector.dart' show XFile;
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'adhan_scheduler.dart';

enum CustomAdhanResult { imported, unreadable, tooLarge }

/// Which device volume controls the adhan. Mirrors both the in-app player
/// (via the audio session usage) and the notification channel (via its
/// audio-attributes usage), so the physical volume rocker for that stream
/// adjusts the adhan.
enum AdhanVolumeStream { media, ring, alarm }

/// A recording bundled with the app. [id] is what's stored in preferences and
/// read by the native player at prayer time, so it must never be renamed.
@immutable
class AdhanVoice {
  const AdhanVoice({
    required this.id,
    required this.asset,
    required this.fajrAsset,
  });

  final String id;

  /// Asset paths relative to `assets/`, as audioplayers expects.
  final String asset;
  final String fajrAsset;
}

/// Owns the adhan-sound preference and the in-app player used to preview it.
///
/// At prayer time the adhan is played by the scheduled notification's sound
/// (so it works when the app is closed) — see [NotificationService]. This
/// service is the single source of truth for whether the adhan is enabled and
/// which volume stream it uses, plus a foreground preview/stop control.
class AdhanAudioService extends ChangeNotifier {
  AdhanAudioService(this._prefs, {Future<Directory> Function()? storageDir})
    : _storageDir = storageDir ?? getApplicationSupportDirectory {
    _enabled = _prefs.getBool(_kEnabled) ?? false;
    final streamName = _prefs.getString(_kStream);
    _stream = AdhanVolumeStream.values.firstWhere(
      (s) => s.name == streamName,
      orElse: () => AdhanVolumeStream.ring,
    );

    if (!kIsWeb) {
      _player = AudioPlayer()..setReleaseMode(ReleaseMode.stop);
      _stateSub = _player!.onPlayerStateChanged.listen((state) {
        final playing = state == PlayerState.playing;
        if (playing != _isPlaying) {
          _isPlaying = playing;
          notifyListeners();
        }
      });
    }
  }

  final SharedPreferences _prefs;

  /// Where imported files are kept; replaceable in tests.
  final Future<Directory> Function() _storageDir;
  AudioPlayer? _player;
  StreamSubscription<PlayerState>? _stateSub;

  static const _kEnabled = 'adhan_sound_enabled';
  static const _kStream = 'adhan_sound_stream';

  /// Whether turning the phone face down stops a playing adhan. Read natively
  /// by AdhanPlayerService; on unless turned off.
  static const _kFlip = 'adhan_sound_flip';

  /// The chosen voice: a [bundledVoices] id or [customVoiceId]. Under the
  /// backed-up `adhan_sound_` prefix, and read natively by AdhanPlayerService.
  static const _kVoice = 'adhan_sound_voice';

  /// The imported file's path and original name. Deliberately *outside* the
  /// backed-up prefix: the file itself isn't in a backup, so a restored path
  /// would point at nothing. A restored "custom" choice with no file plays the
  /// default voice until the user picks a file again.
  static const _kCustomPath = 'adhan_custom_file';
  static const _kCustomName = 'adhan_custom_name';

  static const customVoiceId = 'custom';

  /// Imports larger than this are refused: a full adhan is a few megabytes,
  /// and anything far bigger is more likely a video or a whole album.
  static const maxCustomBytes = 20 * 1024 * 1024;

  /// Recordings that ship with the app, in picker order. Each needs a matching
  /// entry in AdhanPlayerService's `rawFor` (static R.raw references keep the
  /// shrinker from stripping the audio).
  static const bundledVoices = <AdhanVoice>[
    AdhanVoice(
      id: 'default',
      asset: 'audio/adhan1.mp3',
      fajrAsset: 'audio/adhan_fajr.ogg',
    ),
  ];

  static AdhanVoice get defaultVoice => bundledVoices.first;

  /// Bundled asset path of the default voice (relative to `assets/`).
  static String get assetPath => defaultVoice.asset;

  /// The default voice's dedicated Fajr adhan.
  static String get assetPathFajr => defaultVoice.fajrAsset;

  bool _enabled = false;
  AdhanVolumeStream _stream = AdhanVolumeStream.ring;
  bool _isPlaying = false;

  bool get enabled => _enabled;
  AdhanVolumeStream get stream => _stream;
  bool get isPlaying => _isPlaying;

  /// The stored choice, which may be [customVoiceId] even when no file is
  /// there (restored from a backup, or the file was cleared).
  String get voiceId => _prefs.getString(_kVoice) ?? defaultVoice.id;

  /// The imported file's absolute path, if one exists on this device.
  String? get customFilePath {
    final path = _prefs.getString(_kCustomPath);
    if (path == null || kIsWeb || !File(path).existsSync()) return null;
    return path;
  }

  String? get customFileName =>
      customFilePath == null ? null : _prefs.getString(_kCustomName);

  /// What will actually play: the custom file only when it exists, an unknown
  /// bundled id (removed in an update) falls back to the default.
  String get effectiveVoiceId {
    final id = voiceId;
    if (id == customVoiceId) {
      return customFilePath != null ? id : defaultVoice.id;
    }
    return bundledVoices.any((v) => v.id == id) ? id : defaultVoice.id;
  }

  Future<void> setVoice(String id) async {
    if (id == voiceId) return;
    await _prefs.setString(_kVoice, id);
    notifyListeners();
    if (_isPlaying) await playPreview();
  }

  /// Copies [file] into app storage and selects it. The copy matters: a picked
  /// file is usually a content URI the app may lose access to, and the native
  /// player must be able to open it at Fajr with the app closed.
  Future<CustomAdhanResult> importCustom(XFile file) async {
    final Uint8List bytes;
    try {
      bytes = await file.readAsBytes();
    } catch (_) {
      return CustomAdhanResult.unreadable;
    }
    if (bytes.isEmpty) return CustomAdhanResult.unreadable;
    if (bytes.length > maxCustomBytes) return CustomAdhanResult.tooLarge;

    final dir = Directory('${(await _storageDir()).path}/adhan');
    await dir.create(recursive: true);
    final ext = _extensionOf(file.name);
    // A fresh name per import, so a player still holding the old file isn't
    // handed half-written bytes; earlier imports are removed afterwards.
    final name = 'custom_${DateTime.now().millisecondsSinceEpoch}$ext';
    final target = File('${dir.path}/$name');
    await target.writeAsBytes(bytes, flush: true);
    for (final old in dir.listSync().whereType<File>()) {
      // By name, not path: a listing may spell the separator differently.
      if (old.uri.pathSegments.last != name) {
        try {
          old.deleteSync();
        } catch (_) {}
      }
    }

    await _prefs.setString(_kCustomPath, target.path);
    if (file.name.isEmpty) {
      await _prefs.remove(_kCustomName);
    } else {
      await _prefs.setString(_kCustomName, file.name);
    }
    await _prefs.setString(_kVoice, customVoiceId);
    notifyListeners();
    return CustomAdhanResult.imported;
  }

  static String _extensionOf(String name) {
    final dot = name.lastIndexOf('.');
    if (dot < 0 || name.length - dot > 6) return '';
    return name.substring(dot).toLowerCase();
  }

  Future<void> setEnabled(bool value) async {
    if (value == _enabled) return;
    _enabled = value;
    await _prefs.setBool(_kEnabled, value);
    if (!value) await stop();
    notifyListeners();
  }

  bool get flipToSilence => _prefs.getBool(_kFlip) ?? true;

  Future<void> setFlipToSilence(bool value) async {
    await _prefs.setBool(_kFlip, value);
    notifyListeners();
  }

  Future<void> setStream(AdhanVolumeStream value) async {
    if (value == _stream) return;
    _stream = value;
    await _prefs.setString(_kStream, value.name);
    notifyListeners();
    // If a preview is playing, restart it on the new stream so the change is
    // immediately audible.
    if (_isPlaying) await playPreview();
  }

  /// Play the chosen voice once through the chosen volume stream (foreground
  /// preview). Returns false if the file couldn't be played — an imported
  /// file that isn't audio, say — so the screen can say so.
  Future<bool> playPreview() async {
    final player = _player;
    if (player == null) return true;
    await player.stop();
    await player.setAudioContext(_contextFor(_stream));
    final id = effectiveVoiceId;
    final Source source = id == customVoiceId
        ? DeviceFileSource(customFilePath!)
        : AssetSource(bundledVoices.firstWhere((v) => v.id == id).asset);
    try {
      await player.play(source);
      return true;
    } catch (e) {
      debugPrint('Adhan preview failed: $e');
      return false;
    }
  }

  Future<void> stop() async {
    await _player?.stop();
    await AdhanScheduler.stop();
    if (_isPlaying) {
      _isPlaying = false;
      notifyListeners();
    }
  }

  AudioContext _contextFor(AdhanVolumeStream s) {
    final (usage, content) = switch (s) {
      AdhanVolumeStream.media => (
        AndroidUsageType.media,
        AndroidContentType.music,
      ),
      AdhanVolumeStream.ring => (
        AndroidUsageType.notification,
        AndroidContentType.sonification,
      ),
      AdhanVolumeStream.alarm => (
        AndroidUsageType.alarm,
        AndroidContentType.sonification,
      ),
    };
    return AudioContext(
      android: AudioContextAndroid(
        isSpeakerphoneOn: false,
        stayAwake: false,
        contentType: content,
        usageType: usage,
        audioFocus: AndroidAudioFocus.gainTransientMayDuck,
      ),
      iOS: AudioContextIOS(
        category: AVAudioSessionCategory.playback,
        options: const {AVAudioSessionOptions.mixWithOthers},
      ),
    );
  }

  @override
  void dispose() {
    _stateSub?.cancel();
    _player?.dispose();
    super.dispose();
  }
}
