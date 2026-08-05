import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/dua_repository.dart';
import '../l10n/app_strings.dart';
import '../services/custom_dua_service.dart';
import '../widgets/dua_card.dart';

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
              icon: const Icon(Icons.clear),
              tooltip: s.clear,
              onPressed: () {
                _controller.clear();
                setState(() => _query = '');
              },
            ),
        ],
      ),
      body: !hasQuery
          ? _Hint(
              icon: Icons.search,
              text: s.searchPrompt,
            )
          : results.isEmpty
              ? _Hint(
                  icon: Icons.sentiment_dissatisfied_outlined,
                  text: s.noResults(_query.trim()),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  itemCount: results.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return Padding(
                        padding: const EdgeInsetsDirectional.only(
                            start: 4, bottom: 12),
                        child: Text(
                          s.resultsCount(results.length),
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      );
                    }
                    return DuaCard(dua: results[index - 1]);
                  },
                ),
    );
  }
}

class _Hint extends StatelessWidget {
  const _Hint({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 14),
            Text(
              text,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
