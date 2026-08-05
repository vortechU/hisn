import 'dart:async';

import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/dua_repository.dart';
import '../l10n/app_strings.dart';
import '../screens/category_duas_screen.dart';
import '../services/prayer_service.dart';
import '../theme/category_visuals.dart';
import 'arabic_text.dart';

/// A time-aware suggestion shown above the category grid: it points to the set
/// of adhkar most relevant to the current part of the day.
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
    final repo = context.read<DuaRepository>();
    final prayer = context.watch<PrayerService>();
    final s = AppStrings.of(context);

    final now = DateTime.now();
    final current = prayer.currentPrayer(now)?.prayer;
    final category = repo.categoryById(_recommendedCategoryId(current, now));
    if (category == null) return const SizedBox.shrink();

    final visuals = CategoryVisuals.of(category.id);
    final count = repo.countForCategory(category.id);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              s.recommendedNow,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
          ),
          Material(
            color: visuals.color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => CategoryDuasScreen(category: category),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: visuals.color.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(visuals.icon, color: visuals.color, size: 28),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: s.ar
                                    ? ArabicText(
                                        category.titleArabic,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                        textAlign: TextAlign.start,
                                        height: 1.4,
                                        maxLines: 1,
                                      )
                                    : Text(
                                        category.title,
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                              ),
                              if (!s.ar) ...[
                                const SizedBox(width: 8),
                                ArabicText(category.titleArabic,
                                    fontSize: 17, color: visuals.color),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            category.subtitleFor(s.ar),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Text(
                                s.readNow(count),
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: visuals.color,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                s.ar
                                    ? Icons.arrow_back
                                    : Icons.arrow_forward,
                                size: 15,
                                color: visuals.color,
                              ),
                            ],
                          ),
                        ],
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
