import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../data/dua_repository.dart';
import '../l10n/app_strings.dart';
import '../models/dua.dart';
import '../models/dua_category.dart';
import '../services/dua_progress_service.dart';
import '../services/muhassan_service.dart';
import '../theme/app_theme.dart';
import '../theme/category_visuals.dart';
import '../widgets/arabic_text.dart';
import '../widgets/dua_card.dart';
import '../widgets/ornament.dart';

/// Every dua in a category, read as a session: tap a block to advance through
/// its repetitions, with the set's progress ruled across the head of the page.
/// Progress persists for the rest of the day (via [DuaProgressService]) so
/// leaving and returning keeps your place.
class CategoryDuasScreen extends StatefulWidget {
  const CategoryDuasScreen({super.key, required this.category});

  final DuaCategory category;

  @override
  State<CategoryDuasScreen> createState() => _CategoryDuasScreenState();
}

class _CategoryDuasScreenState extends State<CategoryDuasScreen> {
  late final List<Dua> _duas;

  @override
  void initState() {
    super.initState();
    _duas = context.read<DuaRepository>().duasForCategory(widget.category.id);
  }

  DuaProgressService get _progress => context.read<DuaProgressService>();

  int _countOf(Dua dua) => _progress.countOf(dua.id);
  bool _isComplete(Dua dua) => _countOf(dua) >= dua.repeat;
  int get _completedCount => _duas.where(_isComplete).length;

  void _tap(Dua dua) {
    final current = _countOf(dua);
    final wasComplete = current >= dua.repeat;
    // Tapping a finished dua restarts it; otherwise advance by one.
    final next = wasComplete ? 0 : current + 1;
    _progress.setCount(dua.id, next);

    if (!wasComplete && next >= dua.repeat) {
      HapticFeedback.mediumImpact(); // completed this dua
      // Count it toward today's muhassan meter (ignored for non morning/evening).
      context.read<MuhassanService>().markCompleted(widget.category.id, dua.id);
    } else {
      HapticFeedback.selectionClick();
    }
  }

  void _resetAll() => _progress.resetDuas(_duas.map((d) => d.id));

  @override
  Widget build(BuildContext context) {
    // Subscribe so the list + progress rule rebuild whenever a count changes.
    context.watch<DuaProgressService>();
    final theme = Theme.of(context);
    final ms = ManuscriptTheme.of(context);
    final visuals = CategoryVisuals.of(widget.category.id);
    final tint = visuals.color(context);
    final allDone = _completedCount == _duas.length && _duas.isNotEmpty;
    final s = AppStrings.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category.titleFor(s.ar)),
        actions: [
          if (_completedCount > 0)
            IconButton(
              icon: const Icon(Icons.restart_alt),
              tooltip: s.resetProgress,
              onPressed: _resetAll,
            ),
          const SizedBox(width: 6),
        ],
      ),
      body: Column(
        children: [
          // The head of the session: the set's name in Arabic, its mark, and
          // the tally of blocks finished — the page's one dominant element.
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(Ms.margin, 0, Ms.margin, 12),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: ms.rule)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(allDone ? Icons.check : visuals.icon,
                        size: 24, color: allDone ? ms.gilt : tint),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (!s.ar)
                            ArabicText(widget.category.titleArabic,
                                fontSize: 21,
                                color: tint,
                                textAlign: TextAlign.start,
                                height: 1.5,
                                maxLines: 1),
                          Text(
                            allDone ? s.setComplete : s.tapEachDua,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Cartouche(
                      label: '$_completedCount / ${_duas.length}',
                      color: allDone ? ms.gilt : tint,
                      filled: allDone,
                    ),
                  ],
                ),
                const SizedBox(height: 11),
                ProgressRule(
                  value: _duas.isEmpty ? 0 : _completedCount / _duas.length,
                  color: allDone ? ms.gilt : tint,
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(
                  Ms.margin, Ms.margin, Ms.margin, 34),
              itemCount: _duas.length,
              itemBuilder: (context, index) {
                final dua = _duas[index];
                return DuaCard(
                  dua: dua,
                  count: _countOf(dua),
                  onCount: () => _tap(dua),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
