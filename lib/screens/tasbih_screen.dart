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
/// The counter is a ring of beads that fill one by one as the set does, so a
/// glance tells you roughly where you are without reading the numeral — which
/// is what a hand on a string of beads gives you.
///
/// Light haptics on each tap, a stronger pulse when a full set completes.
///
/// Which phrase is being counted lives in [TasbihController] rather than here,
/// because the home-screen tasbih widget shows it too — and because a counter
/// that forgot your dhikr between visits was a small unkindness.
class TasbihScreen extends StatelessWidget {
  const TasbihScreen({super.key});

  Future<void> _editCustom(BuildContext context, {Dhikr? existing}) async {
    final dhikr = await showDialog<Dhikr>(
      context: context,
      builder: (_) => _CustomDhikrDialog(existing: existing),
    );
    if (dhikr != null && context.mounted) {
      await context.read<TasbihController>().select(dhikr);
    }
  }

  Future<void> _deleteCustom(BuildContext context, Dhikr dhikr) async {
    final s = AppStrings.read(context);
    final remove = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(s.deleteDhikr),
        content: Text(s.deleteDhikrConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(s.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(s.delete),
          ),
        ],
      ),
    );
    if (remove == true && context.mounted) {
      final controller = context.read<TasbihController>();
      final fallback = context.read<DuaRepository>().dhikr.first;
      await controller.removeCustom(dhikr.id);
      await controller.select(fallback);
    }
  }

  Future<void> _count(BuildContext context, Dhikr dhikr) async {
    final completed = await context.read<TasbihController>().increment(
      dhikr.id,
      dhikr.target,
    );
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
    final controller = context.watch<TasbihController>();
    final dhikrList = [
      ...context.read<DuaRepository>().dhikr,
      ...controller.customDhikr,
    ];
    final s = AppStrings.of(context);
    // Falls back to the first preset when nothing has been chosen yet, or when
    // a stored choice no longer matches anything in the collection.
    final selected = dhikrList.indexWhere((d) => d.id == controller.selectedId);
    final index = selected < 0 ? 0 : selected;
    final dhikr = dhikrList[index];
    final count = controller.countFor(dhikr.id);
    final laps = controller.lapsFor(dhikr.id);
    final lamp = Color.lerp(ms.gilt, ms.onField, 0.65)!;
    final quiet = ms.onField.withValues(alpha: 0.88);

    return Scaffold(
      appBar: AppBar(
        title: Text(s.navTasbih),
        actions: [
          IconButton(
            key: const ValueKey('add_custom_dhikr'),
            icon: const Icon(Icons.add),
            tooltip: s.addDhikr,
            onPressed: () => _editCustom(context),
          ),
          if (controller.isCustom(dhikr.id))
            PopupMenuButton<String>(
              key: const ValueKey('custom_dhikr_actions'),
              onSelected: (action) {
                if (action == 'edit') {
                  _editCustom(context, existing: dhikr);
                } else {
                  _deleteCustom(context, dhikr);
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(value: 'edit', child: Text(s.editDhikr)),
                PopupMenuItem(value: 'delete', child: Text(s.deleteDhikr)),
              ],
            ),
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
              child: LayoutBuilder(
                builder: (context, viewport) => SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    Ms.margin,
                    20,
                    Ms.margin,
                    28,
                  ),
                  // At least as tall as the screen and centred in it, so the
                  // counter sits where the eye rests rather than sunk to the
                  // foot with empty space above it.
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: viewport.maxHeight - 48,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Column(
                          children: [
                            ArabicText(
                              dhikr.arabic,
                              fontSize: 34,
                              textAlign: TextAlign.center,
                            ),
                            // Both lines render the phrase for someone who can't read
                            // it; in Arabic the phrase above them already did.
                            if (!s.ar) ...[
                              const SizedBox(height: 6),
                              Text(
                                dhikr.transliteration,
                                textAlign: TextAlign.center,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  color: ms.rubric,
                                ),
                              ),
                              if (dhikr.translation.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  dhikr.translationFor(s.lang.name),
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ],
                            const SizedBox(height: 24),
                          ],
                        ),
                        // The counter stands in the screen's one niche: the beads
                        // are the lamp on the qibla ink.
                        MihrabField(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 22),
                          child: Column(
                            children: [
                              _Beat(
                                id: dhikr.id,
                                count: count,
                                laps: laps,
                                child: ProgressRosette(
                                  fraction: dhikr.target == 0
                                      ? 0
                                      : (count / dhikr.target).clamp(0, 1),
                                  size: 244,
                                  lobes: 11,
                                  color: count >= dhikr.target
                                      ? lamp
                                      : ms.onField.withValues(alpha: 0.9),
                                  track: ms.onField.withValues(alpha: 0.16),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      _RollingNumeral(
                                        '$count',
                                        color: ms.onField,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        s.ofTarget(dhikr.target),
                                        style: theme.textTheme.labelMedium
                                            ?.copyWith(color: quiet),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              if (laps > 0) ...[
                                _LapTally(laps: laps, color: lamp),
                                const SizedBox(height: 10),
                              ],
                              Text(
                                count >= dhikr.target
                                    ? s.nextSetOnTap
                                    : laps == 0
                                    ? s.tapToCount
                                    : s.setsCompleted(laps),
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: quiet,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A user's name and phrase, with a target chosen for their own session.
class _CustomDhikrDialog extends StatefulWidget {
  const _CustomDhikrDialog({this.existing});
  final Dhikr? existing;

  @override
  State<_CustomDhikrDialog> createState() => _CustomDhikrDialogState();
}

class _CustomDhikrDialogState extends State<_CustomDhikrDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _arabic;
  late final TextEditingController _target;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.existing?.transliteration ?? '');
    _arabic = TextEditingController(text: widget.existing?.arabic ?? '');
    _target = TextEditingController(text: '${widget.existing?.target ?? 100}');
  }

  @override
  void dispose() {
    _name.dispose();
    _arabic.dispose();
    _target.dispose();
    super.dispose();
  }

  int? _targetValue(String text) {
    if (!RegExp(r'^[0-9٠-٩۰-۹]+$').hasMatch(text)) return null;
    final normalized = String.fromCharCodes(
      text.runes.map((code) {
        if (code >= 0x0660 && code <= 0x0669) return code - 0x0660 + 0x30;
        if (code >= 0x06f0 && code <= 0x06f9) return code - 0x06f0 + 0x30;
        return code;
      }),
    );
    final value = int.tryParse(normalized);
    return value != null &&
            value >= 1 &&
            value <= TasbihController.maxCustomTarget
        ? value
        : null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final controller = context.read<TasbihController>();
    final Dhikr saved;
    if (widget.existing == null) {
      saved = await controller.addCustom(
        name: _name.text,
        arabic: _arabic.text,
        target: _targetValue(_target.text)!,
      );
    } else {
      saved = await controller.updateCustom(
        id: widget.existing!.id,
        name: _name.text,
        arabic: _arabic.text,
        target: _targetValue(_target.text)!,
      );
    }
    if (mounted) Navigator.pop(context, saved);
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return AlertDialog(
      title: Text(widget.existing == null ? s.addDhikr : s.editDhikr),
      scrollable: true,
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              key: const ValueKey('custom_dhikr_name'),
              controller: _name,
              autofocus: true,
              decoration: InputDecoration(labelText: s.fieldDhikrName),
              validator: (text) => text == null || text.trim().isEmpty
                  ? s.fieldDhikrNameRequired
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const ValueKey('custom_dhikr_arabic'),
              controller: _arabic,
              textDirection: TextDirection.rtl,
              minLines: 2,
              maxLines: 4,
              decoration: InputDecoration(labelText: s.fieldArabic),
              validator: (text) => text == null || text.trim().isEmpty
                  ? s.fieldArabicRequired
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const ValueKey('custom_dhikr_target'),
              controller: _target,
              keyboardType: TextInputType.number,
              textDirection: TextDirection.ltr,
              decoration: InputDecoration(
                labelText: s.fieldRepeat,
                errorMaxLines: 3,
              ),
              inputFormatters: [
                TextInputFormatter.withFunction(
                  (oldValue, newValue) =>
                      RegExp(r'^[0-9٠-٩۰-۹]*$').hasMatch(newValue.text)
                      ? newValue
                      : oldValue,
                ),
              ],
              validator: (text) => _targetValue(text ?? '') == null
                  ? s.fieldDhikrTargetRequired
                  : null,
            ),
            const SizedBox(height: 12),
            Text(
              s.customDhikrTargetNote,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: Text(s.cancel),
        ),
        FilledButton(onPressed: _saving ? null : _save, child: Text(s.save)),
      ],
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
  const _RollingNumeral(this.text, {this.color});

  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
    duration: Motion.of(context, Motion.quick),
    switchInCurve: Curves.easeOut,
    switchOutCurve: Curves.easeIn,
    transitionBuilder: (child, animation) => FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween(
          begin: const Offset(0, 0.34),
          end: Offset.zero,
        ).animate(animation),
        child: child,
      ),
    ),
    // Keyed on the figure itself: that is what makes a new number a new
    // child, and so what the switch is triggered by.
    child: Numeral(
      text,
      key: ValueKey(text),
      size: 68,
      weight: FontWeight.w500,
      color: color,
    ),
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
    _controller = AnimationController(vsync: this, duration: Motion.quick * 2);
  }

  /// Out and back: the swell is over before the next bead, even at speed.
  static final _swell = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween(
        begin: 0.0,
        end: 1.0,
      ).chain(CurveTween(curve: Curves.easeOut)),
      weight: 40,
    ),
    TweenSequenceItem(
      tween: Tween(
        begin: 1.0,
        end: 0.0,
      ).chain(CurveTween(curve: Curves.easeIn)),
      weight: 60,
    ),
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

/// Completed sets, marked the way a count is kept: one bead per set, up to a
/// point, then a numeral.
class _LapTally extends StatelessWidget {
  const _LapTally({required this.laps, required this.color});

  final int laps;
  final Color color;

  @override
  Widget build(BuildContext context) {
    const shown = 8;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < (laps > shown ? shown : laps); i++)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
          ),
        if (laps > shown) ...[
          const SizedBox(width: 5),
          Numeral(
            '+${laps - shown}',
            size: 12,
            serif: false,
            weight: FontWeight.w700,
            color: color,
          ),
        ],
      ],
    );
  }
}

/// The phrase selector: a scrolling row of chips, the active one tinted.
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

    return SizedBox(
      height: 60,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(Ms.margin, 4, Ms.margin, 8),
        itemCount: phrases.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final active = index == selected;
          return ChoiceChip(
            selected: active,
            onSelected: (_) => onSelect(index),
            label: Text(
              // Built-ins show their Arabic phrase in RTL; custom phrases
              // retain the user's name so identical texts stay distinct.
              s.rtl &&
                      !context.read<TasbihController>().isCustom(
                        phrases[index].id,
                      )
                  ? stripHarakat(phrases[index].arabic)
                  : phrases[index].transliteration,
            ),
            labelStyle: theme.textTheme.labelLarge?.copyWith(
              color: active ? ms.rubric : theme.colorScheme.onSurfaceVariant,
            ),
          );
        },
      ),
    );
  }
}
