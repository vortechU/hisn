import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../data/dua_repository.dart';
import '../l10n/app_strings.dart';
import '../models/dhikr.dart';
import '../services/tasbih_controller.dart';
import '../widgets/arabic_text.dart';
import '../widgets/islamic_pattern.dart';

/// The Tasbih (dhikr counter): pick a phrase, then tap anywhere to count.
/// Light haptics on each tap, a stronger pulse when a full set completes.
class TasbihScreen extends StatefulWidget {
  const TasbihScreen({super.key});

  @override
  State<TasbihScreen> createState() => _TasbihScreenState();
}

class _TasbihScreenState extends State<TasbihScreen> {
  int _selected = 0;

  Future<void> _count(Dhikr dhikr) async {
    final completed =
        await context.read<TasbihController>().increment(dhikr.id, dhikr.target);
    if (completed) {
      HapticFeedback.heavyImpact();
    } else {
      HapticFeedback.lightImpact();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
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
            icon: const Icon(Icons.refresh),
            tooltip: s.resetCount,
            onPressed: () => context.read<TasbihController>().reset(dhikr.id),
          ),
        ],
      ),
      body: Column(
        children: [
          SizedBox(
            height: 52,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: dhikrList.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                return ChoiceChip(
                  label: Text(dhikrList[index].transliteration),
                  selected: index == _selected,
                  onSelected: (_) => setState(() => _selected = index),
                );
              },
            ),
          ),
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _count(dhikr),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ArabicText(
                      dhikr.arabic,
                      fontSize: 34,
                      textAlign: TextAlign.center,
                      color: scheme.primary,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      dhikr.transliteration,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontStyle: FontStyle.italic),
                    ),
                    Text(
                      dhikr.translation,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 32),
                    _CounterRing(
                      count: count,
                      target: dhikr.target,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      laps == 0 ? s.tapToCount : s.setsCompleted(laps),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
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

class _CounterRing extends StatelessWidget {
  const _CounterRing({required this.count, required this.target});

  final int count;
  final int target;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final s = AppStrings.of(context);

    return SizedBox(
      width: 240,
      height: 240,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: ClipOval(
              child: IslamicPattern(
                  color: scheme.primary, opacity: 0.06, cell: 34),
            ),
          ),
          SizedBox(
            width: 240,
            height: 240,
            child: TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
              tween: Tween(begin: 0, end: count / target),
              builder: (context, value, _) => CircularProgressIndicator(
                value: value,
                strokeWidth: 12,
                strokeCap: StrokeCap.round,
                backgroundColor: scheme.primary.withValues(alpha: 0.12),
              ),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$count',
                style: theme.textTheme.displayMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: scheme.primary,
                ),
              ),
              Text(
                s.ofTarget(target),
                style: theme.textTheme.titleSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
