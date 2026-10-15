import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../data/dua_repository.dart';
import '../l10n/app_strings.dart';
import '../models/dua.dart';
import '../services/dua_progress_service.dart';
import '../theme/app_theme.dart';
import '../util/arabic.dart';
import '../widgets/arabic_text.dart';
import '../widgets/ornament.dart';

/// The 33 + 33 + 33 + 1 sequence in Muslim 597, using the category's own
/// daily progress. Card taps, session taps and saved progress share these IDs.
class AfterPrayerTasbihScreen extends StatefulWidget {
  const AfterPrayerTasbihScreen({super.key});

  static const duaIds = [
    'salah_subhanallah',
    'salah_alhamdulillah',
    'salah_allahu_akbar',
    'salah_tasbih_tahlil_final',
  ];

  @override
  State<AfterPrayerTasbihScreen> createState() =>
      _AfterPrayerTasbihScreenState();
}

class _AfterPrayerTasbihScreenState extends State<AfterPrayerTasbihScreen> {
  late final List<Dua> _duas;
  int _stage = 0;

  DuaProgressService get _progress => context.read<DuaProgressService>();

  @override
  void initState() {
    super.initState();
    final repo = context.read<DuaRepository>();
    _duas = AfterPrayerTasbihScreen.duaIds
        .map((id) => repo.duaById(id)!)
        .toList();
    final first = _duas.indexWhere((d) => _progress.countOf(d.id) < d.repeat);
    _stage = first < 0 ? _duas.length - 1 : first;
  }

  /// A daily rollover or a reset elsewhere must also restart earlier stages.
  int get _activeStage {
    for (var i = 0; i < _stage; i++) {
      if (_progress.countOf(_duas[i].id) < _duas[i].repeat) return i;
    }
    return _stage;
  }

  bool get _complete => _duas.every((d) => _progress.countOf(d.id) >= d.repeat);

  void _tap() {
    if (_complete) return;
    var index = _activeStage;
    if (_progress.countOf(_duas[index].id) >= _duas[index].repeat) {
      index = _duas.indexWhere(
        (d) => _progress.countOf(d.id) < d.repeat,
        index + 1,
      );
      if (index < 0) return;
    }
    _stage = index;
    final dua = _duas[index];
    final next = _progress.countOf(dua.id) + 1;
    _progress.setCount(dua.id, next);
    if (next >= dua.repeat) {
      HapticFeedback.mediumImpact();
    } else {
      HapticFeedback.selectionClick();
    }
  }

  void _reset() {
    setState(() => _stage = 0);
    _progress.resetDuas(AfterPrayerTasbihScreen.duaIds);
  }

  @override
  Widget build(BuildContext context) {
    final progress = context.watch<DuaProgressService>();
    final s = AppStrings.of(context);
    final ms = ManuscriptTheme.of(context);
    final theme = Theme.of(context);
    final index = _activeStage;
    final dua = _duas[index];
    final count = progress.countOf(dua.id).clamp(0, dua.repeat);
    final completed = _complete;
    String number(int value) => s.ar ? toArabicDigits(value) : '$value';

    return Scaffold(
      appBar: AppBar(
        title: Text(s.afterPrayerTasbih),
        actions: [
          IconButton(
            key: const ValueKey('after_prayer_reset'),
            icon: const Icon(Icons.restart_alt),
            tooltip: s.resetProgress,
            onPressed: _reset,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(Ms.margin),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '${s.currentPhrase} ${number(index + 1)} / ${number(_duas.length)}',
              textAlign: TextAlign.center,
              style: theme.textTheme.labelLarge,
            ),
            const SizedBox(height: 20),
            Semantics(
              button: true,
              label: s.tapToCount,
              child: InkWell(
                key: const ValueKey('after_prayer_counter'),
                onTap: completed ? null : _tap,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Column(
                    children: [
                      ArabicText(
                        dua.arabic,
                        fontSize: 30,
                        textAlign: TextAlign.center,
                        color: ms.rubric,
                      ),
                      const SizedBox(height: 26),
                      ProgressRosette(
                        fraction: count / dua.repeat,
                        size: 220,
                        lobes: 11,
                        color: ms.gilt,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Numeral(
                              '$count',
                              key: const ValueKey('after_prayer_count'),
                              size: 58,
                              weight: FontWeight.w600,
                            ),
                            Text(
                              s.ofTarget(dua.repeat),
                              style: theme.textTheme.labelMedium,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              completed
                  ? s.afterPrayerComplete
                  : count >= dua.repeat
                  ? s.nextPhraseOnTap
                  : s.tapToCount,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 18),
            if (!s.ar) ...[
              Text(
                dua.transliteration,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                dua.translationFor(s.lang.name),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
            ],
            Text(
              dua.referenceFor(s.lang.name),
              textAlign: TextAlign.center,
              style: theme.textTheme.labelSmall,
            ),
          ],
        ),
      ),
    );
  }
}
