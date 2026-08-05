import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/dua_repository.dart';
import '../l10n/app_strings.dart';
import '../services/custom_dua_service.dart';
import '../theme/app_theme.dart';
import '../widgets/dua_card.dart';
import '../widgets/ornament.dart';

/// Full-text search across every dua (title, transliteration, translation,
/// reference, and Arabic).
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final results = [
      ...context.read<DuaRepository>().search(_query),
      ...DuaRepository.searchIn(
          context.read<CustomDuaService>().duas, _query),
    ];
    final hasQuery = _query.trim().isNotEmpty;
    final s = AppStrings.of(context);

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: true,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: s.searchHint,
            border: InputBorder.none,
          ),
          style: theme.textTheme.titleMedium,
          onChanged: (value) => setState(() => _query = value),
        ),
        actions: [
          if (hasQuery)
            IconButton(
              icon: const Icon(Icons.close),
              tooltip: s.clear,
              onPressed: () {
                _controller.clear();
                setState(() => _query = '');
              },
            ),
          const SizedBox(width: 6),
        ],
      ),
      body: !hasQuery
          ? EmptyPage(icon: Icons.search, body: s.searchPrompt)
          : results.isEmpty
              ? EmptyPage(
                  icon: Icons.search_off,
                  body: s.noResults(_query.trim()),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(
                      Ms.margin, 10, Ms.margin, 34),
                  itemCount: results.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: Row(
                          children: [
                            Text(
                              s.resultsCount(results.length).toUpperCase(),
                              style: theme.textTheme.labelSmall,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Container(
                                height: Ms.hair,
                                color: ManuscriptTheme.of(context).rule,
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    return DuaCard(dua: results[index - 1]);
                  },
                ),
    );
  }
}
