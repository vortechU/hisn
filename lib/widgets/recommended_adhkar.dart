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
import '../services/prayer_service.dart';
import '../theme/app_theme.dart';
import '../theme/category_visuals.dart';
import 'arabic_text.dart';
import 'ornament.dart';

/// A time-aware pointer to the set of adhkar most relevant to the current part
/// of the day.
///
/// Set as a *rubric* — an instruction ruled into the page rather than boxed —
/// so it reads differently from the framed category entries below it and gives
/// the screen an asymmetric moment instead of a third identical panel.
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

    final visuals = CategoryVisuals.of(category.id);
    final duas = repo.duasForCategory(category.id);
    final count = duas.length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(Ms.margin, 18, Ms.margin, 2),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => CategoryDuasScreen(category: category),
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              // Ruled top and bottom only — the band runs to the page margins
              // instead of sitting in a box of its own.
              border: Border(
                top: BorderSide(color: ms.gilt.withValues(alpha: 0.7), width: Ms.stroke),
                bottom: BorderSide(color: ms.rule),
              ),
            ),
            padding: const EdgeInsets.only(top: 11, bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(s.recommendedNow.toUpperCase(),
                        style: theme.textTheme.labelSmall
                            ?.copyWith(color: ms.gilt)),
                    const SizedBox(width: 8),
                    Rosette(size: 12, color: ms.gilt, lobes: visuals.lobes),
                    const Spacer(),
                    // Listening is the other way into the same set, so it sits
                    // on the rubric rather than replacing the tap that opens
                    // it — the band still reads as one instruction.
                    _ListenMark(category: category, duas: duas),
                  ],
                ),
                const SizedBox(height: 8),
                // The Arabic name is the dominant element here — in a book,
                // the rubric names the chapter you are being sent to.
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: s.ar
                          ? ArabicText(
                              category.titleArabic,
                              fontSize: 27,
                              fontWeight: FontWeight.w600,
                              textAlign: TextAlign.start,
                              height: 1.45,
                              maxLines: 1,
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ArabicText(category.titleArabic,
                                    fontSize: 24,
                                    textAlign: TextAlign.start,
                                    height: 1.5,
                                    maxLines: 1),
                                Text(category.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.titleMedium),
                              ],
                            ),
                    ),
                    const SizedBox(width: 12),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Row(
                        children: [
                          Text(
                            s.readNow(count),
                            style: theme.textTheme.labelMedium
                                ?.copyWith(color: ms.rubric),
                          ),
                          const SizedBox(width: 5),
                          Icon(
                            s.ar
                                ? Icons.arrow_back_rounded
                                : Icons.arrow_forward_rounded,
                            size: 15,
                            color: ms.rubric,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  category.subtitleFor(s.ar),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The headphone mark on the rubric: have this set recited aloud instead of
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
      icon: const Icon(Icons.headset_outlined, size: 19),
      color: ms.rubric,
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 34, minHeight: 26),
      tooltip: AppStrings.of(context).listenAction,
      onPressed: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => AdhkarPlayerScreen(category: category, duas: duas),
        ),
      ),
    );
  }
}
