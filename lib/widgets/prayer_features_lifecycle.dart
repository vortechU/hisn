import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../services/prayer_countdown_settings.dart';
import '../services/prayer_silence_settings.dart';

/// Reconciles permission changes made in Android settings on return to Hisn.
class PrayerFeaturesLifecycle extends StatefulWidget {
  const PrayerFeaturesLifecycle({super.key, required this.child});

  final Widget child;

  @override
  State<PrayerFeaturesLifecycle> createState() =>
      _PrayerFeaturesLifecycleState();
}

class _PrayerFeaturesLifecycleState extends State<PrayerFeaturesLifecycle>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      unawaited(context.read<PrayerCountdownSettings>().refresh());
      unawaited(context.read<PrayerSilenceSettings>().refreshStatus());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
