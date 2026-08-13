import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../data/dua_repository.dart';
import '../l10n/app_strings.dart';
import '../models/dhikr.dart';
import '../services/tasbih_controller.dart';
import '../theme/app_theme.dart';
import '../theme/motion.dart';
import '../util/arabic.dart';
import '../widgets/arabic_text.dart';
import '../widgets/ornament.dart';

/// The Tasbih: pick a phrase, then tap anywhere to count.
///
/// The counter is a rosette that illuminates lobe by lobe as the set fills, so
/// a glance tells you roughly where you are without reading the numeral —
/// which is what a hand on a string of beads gives you.
///
/// Light haptics on each tap, a stronger pulse when a full set completes.
///
/// Which phrase is being counted lives in [TasbihController] rather than here,
/// because the home-screen tasbih widget shows it too — and because a counter
/// that forgot your dhikr between visits was a small unkindness.
class TasbihScreen extends StatelessWidget {
  const TasbihScreen({super.key});

  Future<void> _count(BuildContext context, Dhikr dhikr) async {
    final completed = await context
        .read<TasbihController>()
        .increment(dhikr.id, dhikr.target);
    if (completed) {
      HapticFeedback.heavyImpact();
    } else {
      HapticFeedback.lightImpact();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ms = ManuscriptTheme.of(context);
    final dhikrList = context.read<DuaRepository>().dhikr;
    final controller = context.watch<TasbihController>();
    final s = AppStrings.of(context);
    // Falls back to the first preset when nothing has been chosen yet, or when
    // a stored choice no longer matches anything in the collection.
    final selected = dhikrList.indexWhere((d) => d.id == controller.selectedId);
    final index = selected < 0 ? 0 : selected;
    final dhikr = dhikrList[index];
    final count = controller.countFor(dhikr.id);
    final laps = controller.lapsFor(dhikr.id);

    return Scaffold(
      appBar: AppBar(
        title: Text(s.navTasbih),
        actions: [
          IconButton(
            icon: const Icon(Icons.restart_alt),
            tooltip: s.resetCount,
            onPressed: () => context.read<TasbihController>().reset(dhikr.id),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: Column(
        children: [
          _PhraseSelector(
            phrases: dhikrList,
            selected: index,
            onSelect: (i) =>
                context.read<TasbihController>().select(dhikrList[i]),
          ),
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _count(context, dhikr),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(Ms.margin, 20, Ms.margin, 28),
                child: Column(
                  children: [
                    ArabicText(
                      dhikr.arabic,
                      fontSize: 34,
                      textAlign: TextAlign.center,
                      color: ms.rubric,
                    ),
                    // Both lines render the phrase for someone who can't read
                    // it; in Arabic the phrase above them already did.
                    if (!s.ar) ...[
                      const SizedBox(height: 6),
                      Text(
                        dhikr.transliteration,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontStyle: FontStyle.italic,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        dhikr.translation,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                    const SizedBox(height: 26),
                    _Beat(
                      id: dhikr.id,
                      count: count,
                      laps: laps,
                      child: ProgressRosette(
                        fraction: dhikr.target == 0 ? 0 : count / dhikr.target,
                        size: 244,
                        lobes: 11,
                        color: ms.gilt,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _RollingNumeral('$count'),
                            const SizedBox(height: 2),
                            Text(
                              s.ofTarget(dhikr.target),
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (laps > 0) ...[
                      _LapTally(laps: laps),
                      const SizedBox(height: 10),
                    ],
                    Text(
                      laps == 0 ? s.tapToCount : s.setsCompleted(laps),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The tally figure, rolling as it changes: the new number rises into place as
/// the one it replaces sinks away.
///
/// A bead moving under the thumb is the whole of what a tasbih gives back, and
/// a numeral that simply swapped gave the tap nothing to land on — the haptic
/// was doing all the work on its own.
class _RollingNumeral extends StatelessWidget {
  const _RollingNumeral(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
        duration: Motion.of(context, Motion.quick),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween(begin: const Offset(0, 0.34), end: Offset.zero)
                .animate(animation),
            child: child,
          ),
        ),
        // Keyed on the figure itself: that is what makes a new number a new
        // child, and so what the switch is triggered by.
        child: Numeral(text, key: ValueKey(text), size: 62,
            weight: FontWeight.w600),
      );
}

/// A short swell through whatever it wraps, each time the count moves.
///
/// Scale only, so nothing around it shifts: the plate holds still and the mark
/// answers the finger. Completing a set is the one moment given a longer,
/// deeper beat — [Motion.flourish] exists for exactly this.
class _Beat extends StatefulWidget {
  const _Beat({
    required this.id,
    required this.count,
    required this.laps,
    required this.child,
  });

  /// Which phrase is being counted. Switching phrases changes the numbers
  /// below without anything having been counted, and must not read as a tap.
  final String id;

  final int count;
  final int laps;
  final Widget child;

  @override
  State<_Beat> createState() => _BeatState();
}

class _BeatState extends State<_Beat> with SingleTickerProviderStateMixin {
  // Built in initState rather than lazily: under reduced motion nothing ever
  // reads it, and a lazy field would then be constructed by `dispose` itself —
  // creating a ticker against an element already on its way out.
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: Motion.quick * 2);
  }

  /// Out and back: the swell is over before the next bead, even at speed.
  static final _swell = TweenSequence<double>([
    TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 40),
    TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 60),
  ]);

  /// How far the swell reaches. A set completing earns nearly three times the
  /// light tap's rise, alongside the heavier haptic.
  double _peak = 0.035;

  @override
  void didUpdateWidget(_Beat old) {
    super.didUpdateWidget(old);
    // Nothing to drive if the reader has asked for stillness — the ticker
    // would run for a frame-perfect nothing sixty times a set.
    if (widget.id != old.id || Motion.reduced(context)) return;
    if (widget.laps != old.laps) {
      _peak = 0.09;
      _controller.duration = Motion.flourish;
      _controller.forward(from: 0);
    } else if (widget.count != old.count) {
      _peak = 0.035;
      _controller.duration = Motion.quick * 2;
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (Motion.reduced(context)) return widget.child;
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) => Transform.scale(
        scale: 1 + _swell.evaluate(_controller) * _peak,
        child: child,
      ),
    );
  }
}

/// Completed sets, marked the way a count is kept on paper: one rosette per
/// set, up to a point, then a numeral.
class _LapTally extends StatelessWidget {
  const _LapTally({required this.laps});

  final int laps;

  @override
  Widget build(BuildContext context) {
    final ms = ManuscriptTheme.of(context);
    const shown = 8;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < (laps > shown ? shown : laps); i++)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: Rosette(size: 13, color: ms.gilt, lobes: 6, filled: true),
          ),
        if (laps > shown) ...[
          const SizedBox(width: 5),
          Numeral('+${laps - shown}',
              size: 12, serif: false, weight: FontWeight.w700,
              color: ms.gilt),
        ],
      ],
    );
  }
}

/// The phrase selector: a ruled strip of names, the active one marked by a
/// rule beneath it. A tab register, not a row of pills.
class _PhraseSelector extends StatelessWidget {
  const _PhraseSelector({
    required this.phrases,
    required this.selected,
    required this.onSelect,
  });

  final List<Dhikr> phrases;
  final int selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ms = ManuscriptTheme.of(context);
    final s = AppStrings.of(context);

    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: ms.rule)),
      ),
      child: SizedBox(
        height: 48,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: Ms.margin - 6),
          itemCount: phrases.length,
          itemBuilder: (context, index) {
            final active = index == selected;
            return Material(
              type: MaterialType.transparency,
              child: InkWell(
                onTap: () => onSelect(index),
                child: Container(
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: active ? ms.rubric : Colors.transparent,
                        width: 2,
                      ),
                    ),
                  ),
                  child: Text(
                    // In Arabic the tab is the phrase itself (bare, so the
                    // harakat don't crowd a 48px strip) rather than a Latin
                    // spelling of it.
                    s.ar
                        ? stripHarakat(phrases[index].arabic)
                        : phrases[index].transliteration,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: active
                          ? ms.rubric
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
