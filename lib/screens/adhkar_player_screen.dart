import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../l10n/app_strings.dart';
import '../models/dua.dart';
import '../models/dua_category.dart';
import '../services/adhkar_audio_handler.dart';
import '../services/adhkar_audio_library.dart';
import '../services/adhkar_session.dart';
import '../services/display_settings.dart';
import '../services/dua_progress_service.dart';
import '../services/listen_settings.dart';
import '../services/muhassan_service.dart';
import '../theme/app_theme.dart';
import '../theme/category_visuals.dart';
import '../widgets/arabic_text.dart';
import '../widgets/ornament.dart';

/// The set being recited aloud.
///
/// A reading surface, not a music player: the Arabic of the dhikr being said
/// is the page, and the transport is a single ruled strip under it. Everything
/// here is a mirror — the counters, the streak and the progress rule advance
/// whether or not this screen is open, or the phone is even awake. Closing it
/// does not stop the recitation; that is the point of the feature.
class AdhkarPlayerScreen extends StatefulWidget {
  const AdhkarPlayerScreen({
    super.key,
    required this.category,
    required this.duas,
  });

  final DuaCategory category;
  final List<Dua> duas;

  @override
  State<AdhkarPlayerScreen> createState() => _AdhkarPlayerScreenState();
}

class _AdhkarPlayerScreenState extends State<AdhkarPlayerScreen> {
  bool _wakelock = false;

  @override
  void initState() {
    super.initState();
    // Start on open. Arriving at a player and having to press play again is a
    // step too many for something meant to be used with your hands full.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && context.read<AdhkarAudioHandler>().session == null) {
        _start();
      }
    });
  }

  @override
  void dispose() {
    if (_wakelock) WakelockPlus.disable();
    super.dispose();
  }

  /// Holds the screen awake only if asked to. The opposite of the mushaf,
  /// deliberately: a recitation you listen to should let the phone sleep.
  ///
  /// Deferred to after the frame — this is decided during `build`, and a
  /// platform channel is not something to reach for while laying out.
  void _syncWakelock(bool keepOn) {
    if (keepOn == _wakelock) return;
    _wakelock = keepOn;
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => keepOn ? WakelockPlus.enable() : WakelockPlus.disable(),
    );
  }

  Future<void> _start({bool resume = true}) async {
    final s = AppStrings.read(context);
    final settings = context.read<ListenSettings>();
    await context.read<AdhkarAudioHandler>().start(
          categoryId: widget.category.id,
          duas: widget.duas,
          library: context.read<AdhkarAudioLibrary>(),
          progress: context.read<DuaProgressService>(),
          muhassan: context.read<MuhassanService>(),
          setTitle: widget.category.titleFor(s.ar),
          titleOf: (dua) =>
              s.ar ? (dua.titleArabic ?? dua.title) : dua.title,
          gapSteps: settings.gapSteps,
          includeAppendix: settings.includeAppendix,
          resume: resume,
        );
  }

  @override
  Widget build(BuildContext context) {
    final audio = context.watch<AdhkarAudioHandler>();
    final s = AppStrings.of(context);
    final tint = CategoryVisuals.of(widget.category.id).color(context);

    _syncWakelock(
        context.select<ListenSettings, bool>((l) => l.keepScreenOn));

    final session = audio.session;
    final dua = audio.currentDua;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category.titleFor(s.ar)),
        actions: [
          IconButton(
            icon: const Icon(Icons.replay),
            tooltip: s.listenRestart,
            onPressed: () => _start(resume: false),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            _Head(session: session, tint: tint),
            Expanded(
              child: dua == null
                  ? EmptyPage(
                      icon: Icons.headset_outlined,
                      title: s.listenIdleTitle,
                      body: s.listenIdleBody,
                      action: FilledButton.icon(
                        icon: const Icon(Icons.play_arrow),
                        label: Text(s.listenStart),
                        onPressed: _start,
                      ),
                    )
                  : _Recitation(dua: dua, step: audio.currentStep, tint: tint),
            ),
            _Transport(audio: audio, tint: tint),
          ],
        ),
      ),
    );
  }
}

/// The set's progress, ruled across the head of the page — the same tally the
/// reading screen shows, so the two never look like different sessions.
class _Head extends StatelessWidget {
  const _Head({required this.session, required this.tint});

  final AdhkarSession? session;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ms = ManuscriptTheme.of(context);
    final s = AppStrings.of(context);

    final duas = session?.duas.length ?? 0;
    final done = context.select<DuaProgressService, int>((p) =>
        session == null
            ? 0
            : session!.duas.where((d) => p.countOf(d.id) >= d.repeat).length);
    final allDone = duas > 0 && done == duas;
    final missing = session?.missing.length ?? 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(Ms.margin, 0, Ms.margin, 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: ms.rule)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(allDone ? Icons.check : Icons.graphic_eq,
                  size: 22, color: allDone ? ms.gilt : tint),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  allDone
                      ? s.setComplete
                      : (missing > 0 ? s.listenMissing(missing) : s.listenHint),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall,
                ),
              ),
              const SizedBox(width: 10),
              Cartouche(
                label: '$done / $duas',
                color: allDone ? ms.gilt : tint,
                filled: allDone,
              ),
            ],
          ),
          const SizedBox(height: 11),
          ProgressRule(
            value: duas == 0 ? 0 : done / duas,
            color: allDone ? ms.gilt : tint,
          ),
        ],
      ),
    );
  }
}

/// The dhikr being said: its Arabic, set large, with the meaning under it and
/// the repetition told in beads.
class _Recitation extends StatelessWidget {
  const _Recitation({required this.dua, required this.step, required this.tint});

  final Dua dua;
  final AdhkarStep? step;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ms = ManuscriptTheme.of(context);
    final s = AppStrings.of(context);
    final display = context.watch<DisplaySettings>();
    final count = context.select<DuaProgressService, int>(
        (p) => p.countOf(dua.id));

    final page = ListView(
      padding: const EdgeInsets.fromLTRB(Ms.margin, 20, Ms.margin, 24),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                s.ar ? (dua.titleArabic ?? dua.title) : dua.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(color: ms.rubric),
              ),
            ),
            if (dua.repeat > 1) ...[
              const SizedBox(width: 10),
              _Beads(count: count, target: dua.repeat, tint: tint),
            ],
          ],
        ),
        const RuleDivider(),
        // Set larger than a dua card's: this is the only text on the page, and
        // it is being read across a room or over a shoulder as often as held.
        ArabicText(dua.arabic, block: true, fontSize: 30),
        if (display.showTranslation && !s.ar) ...[
          const SizedBox(height: 18),
          Text(
            dua.translationFor(s.lang.name),
            style: theme.textTheme.bodyLarge,
          ),
        ],
        const SizedBox(height: 16),
        Text(
          dua.referenceFor(s.lang.name),
          style: theme.textTheme.labelSmall,
        ),
      ],
    );

    // The text-size preference is applied the way [DuaCard] applies it — as a
    // scaler over the subtree rather than multiplied into each font size, so
    // the Arabic and the meaning grow together.
    return MediaQuery(
      data: MediaQuery.of(context)
          .copyWith(textScaler: TextScaler.linear(display.fontScale)),
      child: page,
    );
  }
}

/// The repetition, told as beads — a row of rosettes that ink in one at a
/// time. Past a dozen the beads stop being countable at a glance, so the long
/// dhikr fall back to a plain tally.
class _Beads extends StatelessWidget {
  const _Beads({required this.count, required this.target, required this.tint});

  final int count;
  final int target;
  final Color tint;

  static const _maxBeads = 12;

  @override
  Widget build(BuildContext context) {
    if (target > _maxBeads) {
      return Cartouche(label: '$count / $target', color: tint);
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < target; i++)
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Rosette(
              size: 13,
              lobes: 6,
              color: i < count
                  ? tint
                  : ManuscriptTheme.of(context).rule,
              filled: i < count,
            ),
          ),
      ],
    );
  }
}

/// The transport, on one ruled strip: back a dhikr, play or pause, on a
/// dhikr — the same three the lock screen shows, in the same order.
class _Transport extends StatelessWidget {
  const _Transport({required this.audio, required this.tint});

  final AdhkarAudioHandler audio;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    final ms = ManuscriptTheme.of(context);
    final s = AppStrings.of(context);
    final playing = audio.isPlaying;
    final live = audio.session != null;

    return Container(
      padding: const EdgeInsets.fromLTRB(Ms.margin, 10, Ms.margin, 14),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: ms.rule)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            icon: const Icon(Icons.skip_previous),
            iconSize: 30,
            tooltip: s.listenPrevious,
            onPressed: live ? audio.skipToPrevious : null,
          ),
          IconButton.filled(
            icon: Icon(playing ? Icons.pause : Icons.play_arrow),
            iconSize: 34,
            tooltip: playing ? s.listenPause : s.listenResume,
            onPressed:
                live ? (playing ? audio.pause : audio.play) : null,
            style: IconButton.styleFrom(
              backgroundColor: tint,
              padding: const EdgeInsets.all(14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(Ms.rPanel),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.skip_next),
            iconSize: 30,
            tooltip: s.listenNext,
            onPressed: live ? audio.skipToNext : null,
          ),
        ],
      ),
    );
  }
}
