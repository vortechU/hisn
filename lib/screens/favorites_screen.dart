import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/dua_repository.dart';
import '../l10n/app_strings.dart';
import '../services/favorites_service.dart';
import '../widgets/dua_card.dart';

/// Shows the duas the user has bookmarked.
class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final favorites = context.watch<FavoritesService>();
    final duas = context.read<DuaRepository>().duasByIds(favorites.ids);
    final s = AppStrings.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(s.navSaved)),
      body: duas.isEmpty
          ? const _EmptyState()
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              itemCount: duas.length,
              itemBuilder: (context, index) => DuaCard(dua: duas[index]),
            ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = AppStrings.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bookmark_border,
                size: 64, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 16),
            Text(s.noSavedTitle, style: theme.textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(
              s.noSavedBody,
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
