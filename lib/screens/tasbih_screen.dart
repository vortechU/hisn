import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../data/dua_repository.dart';
import '../l10n/app_strings.dart';
import '../models/dhikr.dart';
import '../services/tasbih_controller.dart';
import '../theme/app_theme.dart';
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
class TasbihScreen extends StatefulWidget {
  const TasbihScreen({super.key});

  @override
  State<TasbihScreen> createState() => _TasbihScreenState();
}

class _TasbihScreenState extends State<TasbihScreen> {
  int _selected = 0;

  Future<void> _count(Dhikr dhikr) async {
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
    final dhikr = dhikrList[_selected];
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
            selected: _selected,
            onSelect: (i) => setState(() => _selected = i),
          ),
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _count(dhikr),
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
                    ProgressRosette(
                      fraction: dhikr.target == 0 ? 0 : count / dhikr.target,
                      size: 244,
                      lobes: 11,
                      color: ms.gilt,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Numeral('$count',
                              size: 62, weight: FontWeight.w600),
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
