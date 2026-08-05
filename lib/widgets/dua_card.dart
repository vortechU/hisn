import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../l10n/app_strings.dart';
import '../models/dua.dart';
import '../services/display_settings.dart';
import '../services/favorites_service.dart';
import '../theme/reading_theme.dart';
import '../util/arabic.dart';
import 'arabic_text.dart';

/// Displays one dua: Arabic, transliteration, translation, source, and any
/// reward, with bookmark and copy actions.
///
/// When [onCount] is provided the card enters "read & count" mode: the whole
/// card becomes a tap target that advances [count] toward the dua's repetition
/// target, and it shows a live counter (and a completed state at the target).
class DuaCard extends StatelessWidget {
  const DuaCard({
    super.key,
    required this.dua,
    this.count,
    this.onCount,
    this.onEdit,
    this.onDelete,
  });

  final Dua dua;

  /// Current repetition count. `null` outside of counting mode.
  final int? count;

  /// Advances the count by one tap. `null` disables counting (static card).
  final VoidCallback? onCount;

  /// When provided, shows an edit action (used for the user's custom duas).
  final VoidCallback? onEdit;

  /// When provided, shows a delete action (used for the user's custom duas).
  final VoidCallback? onDelete;

  bool get _counting => onCount != null;
  bool get _complete => _counting && (count ?? 0) >= dua.repeat;

  void _copy(BuildContext context) {
    final lang = AppStrings.read(context).lang.name;
    final text = '${dua.arabic}\n\n${dua.transliteration}\n\n'
        '${dua.translationFor(lang)}\n\n— ${dua.reference}';
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
          SnackBar(content: Text(AppStrings.read(context).duaCopied)));
  }

  @override
  Widget build(BuildContext context) {
    // Apply the reading-surface tint (sepia / night) above the card so the
    // Arabic, translation, and card colours all pick it up. `system` is a no-op.
    final reading =
        context.select<DisplaySettings, ReadingTheme>((d) => d.readingTheme);
    return Theme(
      data: reading.apply(Theme.of(context)),
      child: Builder(builder: _buildCard),
    );
  }

  Widget _buildCard(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final favorites = context.watch<FavoritesService>();
    final isFavorite = favorites.isFavorite(dua.id);
    final display = context.watch<DisplaySettings>();
    final s = AppStrings.of(context);
    final showArabicTitle = s.ar && dua.titleArabic != null;

    final content = Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
            Row(
              children: [
                Expanded(
                  child: showArabicTitle
                      ? ArabicText(
                          stripHarakat(dua.titleArabic!),
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          textAlign: TextAlign.start,
                          height: 1.5,
                          maxLines: 2,
                        )
                      : Text(
                          dua.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
                if (_counting)
                  _CounterBadge(
                    count: count ?? 0,
                    target: dua.repeat,
                    complete: _complete,
                  )
                else if (dua.repeat > 1)
                  _RepeatBadge(count: dua.repeat),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: Icon(
                    isFavorite ? Icons.bookmark : Icons.bookmark_border,
                    color: isFavorite ? scheme.secondary : scheme.onSurfaceVariant,
                  ),
                  tooltip: isFavorite ? s.removeBookmark : s.bookmark,
                  onPressed: () => context.read<FavoritesService>().toggle(dua.id),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: Icon(Icons.copy_rounded, color: scheme.onSurfaceVariant),
                  tooltip: s.copy,
                  onPressed: () => _copy(context),
                ),
                if (onEdit != null)
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: Icon(Icons.edit_outlined,
                        color: scheme.onSurfaceVariant),
                    tooltip: s.edit,
                    onPressed: onEdit,
                  ),
                if (onDelete != null)
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: Icon(Icons.delete_outline, color: scheme.error),
                    tooltip: s.deleteDua,
                    onPressed: onDelete,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            ArabicText(dua.arabic, block: true),
            if (display.showTransliteration) ...[
              const SizedBox(height: 16),
              Text(
                dua.transliteration,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
            if (display.showTranslation) ...[
              const SizedBox(height: 10),
              Text(dua.translationFor(s.lang.name),
                  style: theme.textTheme.bodyLarge),
            ],
            if (dua.virtueFor(s.lang.name) != null) ...[
              const SizedBox(height: 14),
              _VirtueNote(text: dua.virtueFor(s.lang.name)!),
            ],
            const SizedBox(height: 14),
            Row(
              children: [
                Icon(Icons.menu_book_outlined,
                    size: 15, color: scheme.onSurfaceVariant),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    dua.reference,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );

    final card = Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      shape: _complete
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: scheme.primary, width: 1.5),
            )
          : null,
      child: _counting ? InkWell(onTap: onCount, child: content) : content,
    );

    // Apply the user's text-size preference to everything inside the card.
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: TextScaler.linear(display.fontScale),
      ),
      child: card,
    );
  }
}

class _CounterBadge extends StatelessWidget {
  const _CounterBadge({
    required this.count,
    required this.target,
    required this.complete,
  });

  final int count;
  final int target;
  final bool complete;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = complete ? scheme.primary : scheme.secondary;
    return Container(
      margin: const EdgeInsetsDirectional.only(end: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: complete ? 0.18 : 0.16),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(complete ? Icons.check_circle : Icons.touch_app_outlined,
              size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            complete ? AppStrings.of(context).done : '$count / $target',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _RepeatBadge extends StatelessWidget {
  const _RepeatBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsetsDirectional.only(end: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: scheme.secondary.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '×$count',
        style: TextStyle(
          color: scheme.secondary,
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
      ),
    );
  }
}

class _VirtueNote extends StatelessWidget {
  const _VirtueNote({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: BorderDirectional(
          start:
              BorderSide(color: scheme.primary.withValues(alpha: 0.5), width: 3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lightbulb_outline, size: 16, color: scheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurface.withValues(alpha: 0.85),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
