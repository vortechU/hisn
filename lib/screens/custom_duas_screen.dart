import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../l10n/app_strings.dart';
import '../models/dua.dart';
import '../services/custom_dua_service.dart';
import '../services/dua_progress_service.dart';
import '../widgets/dua_card.dart';
import 'add_dua_screen.dart';

/// The "My Duas" section: lists the user's own duas with add, edit, and delete.
///
/// Each card is also an interactive "read & count" target — tap it to advance
/// through its repetition target (the count set when adding/editing the dua).
/// Progress persists for the rest of the day via [DuaProgressService], the same
/// as the built-in categories.
class CustomDuasScreen extends StatelessWidget {
  const CustomDuasScreen({super.key});

  Future<void> _add(BuildContext context) async {
    final added = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const AddDuaScreen()),
    );
    if (added == true && context.mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
            SnackBar(content: Text(AppStrings.read(context).duaSaved)));
    }
  }

  Future<void> _edit(BuildContext context, Dua dua) async {
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => AddDuaScreen(existing: dua)),
    );
    if (updated == true && context.mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
            SnackBar(content: Text(AppStrings.read(context).duaUpdated)));
    }
  }

  Future<void> _confirmDelete(BuildContext context, Dua dua) async {
    final s = AppStrings.read(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(s.deleteDua),
        content: Text(s.deleteDuaConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(s.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(s.delete),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await context.read<CustomDuaService>().remove(dua.id);
    }
  }

  /// Advance [dua]'s repetition count by one tap. Tapping a finished dua
  /// restarts it, mirroring the built-in category sessions.
  void _tap(BuildContext context, Dua dua) {
    final progress = context.read<DuaProgressService>();
    final current = progress.countOf(dua.id);
    final wasComplete = current >= dua.repeat;
    final next = wasComplete ? 0 : current + 1;
    progress.setCount(dua.id, next);

    if (!wasComplete && next >= dua.repeat) {
      HapticFeedback.mediumImpact(); // completed this dua
    } else {
      HapticFeedback.selectionClick();
    }
  }

  @override
  Widget build(BuildContext context) {
    final custom = context.watch<CustomDuaService>();
    // Subscribe so cards rebuild whenever a count changes.
    final progress = context.watch<DuaProgressService>();
    final s = AppStrings.of(context);
    final duas = custom.duas;

    final inProgress =
        duas.any((d) => progress.countOf(d.id) > 0);

    return Scaffold(
      appBar: AppBar(
        title: Text(s.myDuas),
        actions: [
          if (inProgress)
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: s.resetProgress,
              onPressed: () => context
                  .read<DuaProgressService>()
                  .resetDuas(duas.map((d) => d.id)),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _add(context),
        icon: const Icon(Icons.add),
        label: Text(s.addDua),
      ),
      body: duas.isEmpty
          ? _EmptyState(s: s)
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              itemCount: duas.length,
              itemBuilder: (context, index) {
                final dua = duas[index];
                return DuaCard(
                  dua: dua,
                  count: progress.countOf(dua.id),
                  onCount: () => _tap(context, dua),
                  onEdit: () => _edit(context, dua),
                  onDelete: () => _confirmDelete(context, dua),
                );
              },
            ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.s});
  final AppStrings s;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.volunteer_activism_outlined,
                size: 64, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 16),
            Text(s.noCustomTitle, style: theme.textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(
              s.noCustomBody,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
