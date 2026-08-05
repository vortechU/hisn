import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Which device volume controls the adhan. Mirrors both the in-app player
/// (via the audio session usage) and the notification channel (via its
/// audio-attributes usage), so the physical volume rocker for that stream
/// adjusts the adhan.
enum AdhanVolumeStream { media, ring, alarm }

/// Owns the adhan-sound preference and the in-app player used to preview it.
///
/// At prayer time the adhan is played by the scheduled notification's sound
/// (so it works when the app is closed) — see [NotificationService]. This
/// service is the single source of truth for whether the adhan is enabled and
/// which volume stream it uses, plus a foreground preview/stop control.
class AdhanAudioService extends ChangeNotifier {
  AdhanAudioService(this._prefs) {
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
  AudioPlayer? _player;
  StreamSubscription<PlayerState>? _stateSub;

  static const _kEnabled = 'adhan_sound_enabled';
  static const _kStream = 'adhan_sound_stream';

  /// Bundled asset path (relative to `assets/`, as audioplayers expects).
  static const assetPath = 'audio/adhan1.mp3';

  /// The dedicated Fajr adhan (same muezzin, with the Fajr-specific call).
  static const assetPathFajr = 'audio/adhan_fajr.ogg';

  /// Android raw resource names (no extension) used for the notification sound.
  static const rawResourceName = 'adhan1';
  static const rawResourceNameFajr = 'adhan_fajr';

  bool _enabled = false;
  AdhanVolumeStream _stream = AdhanVolumeStream.ring;
  bool _isPlaying = false;

  bool get enabled => _enabled;
  AdhanVolumeStream get stream => _stream;
  bool get isPlaying => _isPlaying;

  Future<void> setEnabled(bool value) async {
    if (value == _enabled) return;
    _enabled = value;
    await _prefs.setBool(_kEnabled, value);
    if (!value) await stop();
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

  /// Play the adhan once through the chosen volume stream (foreground preview).
  Future<void> playPreview() async {
    final player = _player;
    if (player == null) return;
    await player.stop();
    await player.setAudioContext(_contextFor(_stream));
    await player.play(AssetSource(assetPath));
  }

  Future<void> stop() async {
    await _player?.stop();
    if (_isPlaying) {
      _isPlaying = false;
      notifyListeners();
    }
  }

  AudioContext _contextFor(AdhanVolumeStream s) {
    final (usage, content) = switch (s) {
      AdhanVolumeStream.media => (
          AndroidUsageType.media,
          AndroidContentType.music
        ),
      AdhanVolumeStream.ring => (
          AndroidUsageType.notification,
          AndroidContentType.sonification
        ),
      AdhanVolumeStream.alarm => (
          AndroidUsageType.alarm,
          AndroidContentType.sonification
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
