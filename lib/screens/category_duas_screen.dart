import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../data/dua_repository.dart';
import '../l10n/app_strings.dart';
import '../models/dua.dart';
import '../models/dua_category.dart';
import '../services/dua_progress_service.dart';
import '../services/muhassan_service.dart';
import '../theme/category_visuals.dart';
import '../widgets/arabic_text.dart';
import '../widgets/dua_card.dart';

/// Lists every dua within a single category as an interactive "read & count"
/// session: tap a dua to advance through its repetitions, with a progress bar
/// for the whole set. Progress persists for the rest of the day (via
/// [DuaProgressService]) so leaving and returning keeps your place.
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

  void _resetAll() {
    _progress.resetDuas(_duas.map((d) => d.id));
  }

  @override
  Widget build(BuildContext context) {
    // Subscribe so the list + progress bar rebuild whenever a count changes.
    context.watch<DuaProgressService>();
    final visuals = CategoryVisuals.of(widget.category.id);
    final allDone = _completedCount == _duas.length && _duas.isNotEmpty;
    final s = AppStrings.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.category.titleFor(s.ar)),
            Text(
              widget.category.subtitleFor(s.ar),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
        actions: [
          if (_completedCount > 0)
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: s.resetProgress,
              onPressed: _resetAll,
            ),
          if (!s.ar)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 12),
              child: ArabicText(widget.category.titleArabic,
                  fontSize: 20, color: visuals.color),
            ),
        ],
      ),
      body: Column(
        children: [
          _ProgressHeader(
            completed: _completedCount,
            total: _duas.length,
            color: visuals.color,
            allDone: allDone,
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
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

class _ProgressHeader extends StatelessWidget {
  const _ProgressHeader({
    required this.completed,
    required this.total,
    required this.color,
    required this.allDone,
  });

  final int completed;
  final int total;
  final Color color;
  final bool allDone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = AppStrings.of(context);
    final progress = total == 0 ? 0.0 : completed / total;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                allDone ? Icons.check_circle : Icons.touch_app_outlined,
                size: 18,
                color: allDone ? color : theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  allDone ? s.setComplete : s.tapEachDua,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: allDone ? color : theme.colorScheme.onSurface,
                  ),
                ),
              ),
              Text(
                '$completed / $total',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
              tween: Tween(begin: 0, end: progress),
              builder: (context, value, _) => LinearProgressIndicator(
                value: value,
                minHeight: 6,
                backgroundColor: color.withValues(alpha: 0.14),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
