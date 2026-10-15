import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../services/adhan_scheduler.dart';

/// App-wide control for the native adhan, including playback begun while locked.
/// Place below the navigator in MaterialApp.builder so every route can stop it.
class AdhanPlaybackBanner extends StatefulWidget {
  const AdhanPlaybackBanner({super.key});

  @override
  State<AdhanPlaybackBanner> createState() => _AdhanPlaybackBannerState();
}

class _AdhanPlaybackBannerState extends State<AdhanPlaybackBanner>
    with WidgetsBindingObserver {
  StreamSubscription<bool>? _sub;
  bool _playing = false;
  int _revision = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _sub = AdhanScheduler.playback.listen((playing) {
      _revision++;
      if (mounted) setState(() => _playing = playing);
    }, onError: (_) => _refresh());
    _refresh();
  }

  Future<void> _refresh() async {
    final revision = _revision;
    final playing = await AdhanScheduler.isPlaying();
    if (mounted && revision == _revision) setState(() => _playing = playing);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _stop() async {
    await AdhanScheduler.stop();
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    if (!_playing) return const SizedBox.shrink();
    final s = AppStrings.of(context);
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainer,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsetsDirectional.only(
            start: 16,
            end: 12,
            top: 4,
            bottom: 4,
          ),
          child: Row(
            children: [
              const Icon(Icons.volume_up_outlined, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(s.adhanPlaying, style: theme.textTheme.bodyMedium),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: _stop,
                icon: const Icon(Icons.stop),
                label: Text(s.stopAdhan),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
