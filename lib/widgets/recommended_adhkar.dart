import 'dart:async';

import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/dua_repository.dart';
import '../l10n/app_strings.dart';
import '../models/dua.dart';
import '../models/dua_category.dart';
import '../screens/adhkar_player_screen.dart';
import '../screens/category_duas_screen.dart';
import '../services/adhkar_audio_library.dart';
import '../services/dua_progress_service.dart';
import '../services/prayer_service.dart';
import '../theme/app_theme.dart';
import 'arabic_text.dart';
import 'ornament.dart';

/// A time-aware pointer to the set of adhkar most relevant to the current part
/// of the day.
///
/// It sits at the foot of the mihrab, under the countdown, as the screen's one
/// expanded entry: every other set is a compact row below. Its progress and
/// its button are the shortest way from opening the app to reading.
///
/// The choice follows the current prayer period (more meaningful than the wall
/// clock — morning adhkar are tied to Fajr, evening to Asr), with an hour-based
/// fallback if prayer times aren't available.
class RecommendedAdhkar extends StatefulWidget {
  const RecommendedAdhkar({super.key});

  @override
  State<RecommendedAdhkar> createState() => _RecommendedAdhkarState();
}

class _RecommendedAdhkarState extends State<RecommendedAdhkar> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    // The recommendation only changes at prayer boundaries; a minute is plenty.
    _ticker = Timer.periodic(
      const Duration(minutes: 1),
      (_) => setState(() {}),
    );
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  String _recommendedCategoryId(Prayer? current, DateTime now) {
    switch (current) {
      case Prayer.fajr:
      case Prayer.sunrise:
      case Prayer.dhuhr:
        return 'morning';
      case Prayer.asr:
      case Prayer.maghrib:
        return 'evening';
      case Prayer.isha:
        return 'sleep';
      case Prayer.none:
      case null:
        final hour = now.hour;
        if (hour >= 3 && hour < 12) return 'morning';
        if (hour >= 12 && hour < 19) return 'evening';
        return 'sleep';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ms = ManuscriptTheme.of(context);
    final repo = context.read<DuaRepository>();
    final prayer = context.watch<PrayerService>();
    final s = AppStrings.of(context);

    final now = DateTime.now();
    final current = prayer.currentPrayer(now)?.prayer;
    final category = repo.categoryById(_recommendedCategoryId(current, now));
    if (category == null) return const SizedBox.shrink();

    final duas = repo.duasForCategory(category.id);
    final count = duas.length;
    final completed = context.select<DuaProgressService, int>(
      (p) => duas.where((d) => p.countOf(d.id) >= d.repeat).length,
    );
    final done = count > 0 && completed == count;
    final quiet = ms.onField.withValues(alpha: 0.88);
    final lamp = Color.lerp(ms.gilt, ms.onField, 0.7)!;

    void open() => Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => CategoryDuasScreen(category: category)),
    );

    return InkWell(
      onTap: open,
      borderRadius: BorderRadius.circular(Ms.rSmall),
      child: Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: Ms.hair,
              color: ms.onField.withValues(alpha: 0.16),
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ArabicText(
                        s.ar
                            ? category.titleForLang(s.lang.name)
                            : category.titleArabic,
                        fontSize: 23,
                        color: ms.onField,
                        textAlign: TextAlign.start,
                        height: 1.5,
                        maxLines: 1,
                      ),
                      if (!s.ar)
                        Text(
                          category.titleForLang(s.lang.name),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: ms.onField,
                          ),
                        ),
                      const SizedBox(height: 2),
                      Text(
                        category.subtitleForLang(s.lang.name),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: quiet,
                        ),
                      ),
                    ],
                  ),
                ),
                // Listening is the other way into the same set, so it sits
                // beside the title rather than replacing the tap that opens
                // it.
                _ListenMark(category: category, duas: duas),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: ProgressRule(
                    value: count == 0 ? 0 : completed / count,
                    color: done ? lamp : ms.onField,
                    track: ms.onField.withValues(alpha: 0.18),
                  ),
                ),
                const SizedBox(width: 12),
                if (done) ...[
                  Icon(Icons.check_rounded, size: 16, color: lamp),
                  const SizedBox(width: 4),
                ],
                Text(
                  // Isolated so the tally keeps its order in RTL text.
                  '\u2066$completed / $count\u2069',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: done ? lamp : ms.onField,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            FilledButton(
              key: const ValueKey('recommended_read_now'),
              style: FilledButton.styleFrom(
                backgroundColor: ms.onField,
                foregroundColor: ms.field,
              ),
              onPressed: open,
              child: Text(s.readNow(count)),
            ),
          ],
        ),
      ),
    );
  }
}

/// The headphone mark beside the title: have this set recited aloud instead of
/// reading it. Hidden when nothing in the set is recorded.
class _ListenMark extends StatelessWidget {
  const _ListenMark({required this.category, required this.duas});

  final DuaCategory category;
  final List<Dua> duas;

  @override
  Widget build(BuildContext context) {
    if (!context.read<AdhkarAudioLibrary>().canPlay(duas)) {
      return const SizedBox.shrink();
    }
    final ms = ManuscriptTheme.of(context);
    return IconButton(
      icon: const Icon(Icons.headset_outlined, size: 22),
      color: ms.onField,
      tooltip: AppStrings.of(context).listenAction,
      onPressed: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => AdhkarPlayerScreen(category: category, duas: duas),
        ),
      ),
    );
  }
}
