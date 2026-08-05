import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/dua_repository.dart';
import '../l10n/app_strings.dart';
import '../services/favorites_service.dart';
import '../theme/app_theme.dart';
import '../widgets/dua_card.dart';
import '../widgets/ornament.dart';

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
          ? EmptyPage(
              icon: Icons.bookmark_border,
              title: s.noSavedTitle,
              body: s.noSavedBody,
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(
                  Ms.margin, Ms.margin, Ms.margin, 34),
              itemCount: duas.length,
              itemBuilder: (context, index) => DuaCard(dua: duas[index]),
            ),
    );
  }
}
