import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../data/dua_repository.dart';
import '../l10n/app_strings.dart';
import '../models/dua.dart';
import '../models/dua_category.dart';
import '../services/adhkar_audio_library.dart';
import '../services/dua_progress_service.dart';
import '../services/muhassan_service.dart';
import '../theme/app_theme.dart';
import '../theme/category_visuals.dart';
import '../widgets/arabic_text.dart';
import '../widgets/dua_card.dart';
import '../widgets/ornament.dart';
import 'adhkar_player_screen.dart';

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
    // Deliberately *not* watching [DuaProgressService] here. A tap would then
    // rebuild the whole page — the head, the list, and with it every card
    // currently on screen — when the only things that actually changed are the
    // tally and the one block that was tapped. Those two subscribe for
    // themselves, just below, so a tap costs two small rebuilds instead of a
    // screenful.
    final visuals = CategoryVisuals.of(widget.category.id);
    final tint = visuals.color(context);
    final s = AppStrings.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category.titleFor(s.ar)),
        actions: [
          _ListenAction(category: widget.category, duas: _duas),
          _ResetAction(duas: _duas, onReset: _resetAll),
          const SizedBox(width: 6),
        ],
      ),
      body: Column(
        children: [
          _SessionHead(
            category: widget.category,
            duas: _duas,
            icon: visuals.icon,
            tint: tint,
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(
                  Ms.margin, Ms.margin, Ms.margin, 34),
              itemCount: _duas.length,
              itemBuilder: (context, index) {
                final dua = _duas[index];
                return _CountedDuaCard(dua: dua, onCount: () => _tap(dua));
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// How many of [duas] are finished, subscribing the caller to that number
/// alone.
///
/// A tap that leaves the tally where it was — the second of a dua's ten
/// repetitions, say — rebuilds nothing here.
int _completedCount(BuildContext context, List<Dua> duas) =>
    context.select<DuaProgressService, int>(
        (p) => duas.where((d) => p.countOf(d.id) >= d.repeat).length);

/// The head of the session: the set's name in Arabic, its mark, and the tally
/// of blocks finished — the page's one dominant element.
class _SessionHead extends StatelessWidget {
  const _SessionHead({
    required this.category,
    required this.duas,
    required this.icon,
    required this.tint,
  });

  final DuaCategory category;
  final List<Dua> duas;
  final IconData icon;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ms = ManuscriptTheme.of(context);
    final s = AppStrings.of(context);
    final completed = _completedCount(context, duas);
    final allDone = completed == duas.length && duas.isNotEmpty;

    return Container(
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
              Icon(allDone ? Icons.check : icon,
                  size: 24, color: allDone ? ms.gilt : tint),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!s.ar)
                      ArabicText(category.titleArabic,
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
                label: '$completed / ${duas.length}',
                color: allDone ? ms.gilt : tint,
                filled: allDone,
              ),
            ],
          ),
          const SizedBox(height: 11),
          ProgressRule(
            value: duas.isEmpty ? 0 : completed / duas.length,
            color: allDone ? ms.gilt : tint,
          ),
        ],
      ),
    );
  }
}

/// Hands the set over to be recited aloud.
///
/// Absent unless something in this category is actually recorded, which is
/// what keeps the feature invisible in a build that ships without the audio.
class _ListenAction extends StatelessWidget {
  const _ListenAction({required this.category, required this.duas});

  final DuaCategory category;
  final List<Dua> duas;

  @override
  Widget build(BuildContext context) {
    if (!context.read<AdhkarAudioLibrary>().canPlay(duas)) {
      return const SizedBox.shrink();
    }
    return IconButton(
      icon: const Icon(Icons.headset_outlined),
      tooltip: AppStrings.of(context).listenAction,
      onPressed: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => AdhkarPlayerScreen(category: category, duas: duas),
        ),
      ),
    );
  }
}

/// The "start the set again" action, shown once anything has been finished.
class _ResetAction extends StatelessWidget {
  const _ResetAction({required this.duas, required this.onReset});

  final List<Dua> duas;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    if (_completedCount(context, duas) == 0) return const SizedBox.shrink();
    return IconButton(
      icon: const Icon(Icons.restart_alt),
      tooltip: AppStrings.of(context).resetProgress,
      onPressed: onReset,
    );
  }
}

/// One block in the session, subscribed to its own count and nothing else.
class _CountedDuaCard extends StatelessWidget {
  const _CountedDuaCard({required this.dua, required this.onCount});

  final Dua dua;
  final VoidCallback onCount;

  @override
  Widget build(BuildContext context) {
    final count =
        context.select<DuaProgressService, int>((p) => p.countOf(dua.id));
    return DuaCard(dua: dua, count: count, onCount: onCount);
  }
}
