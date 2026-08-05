import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../l10n/app_strings.dart';
import '../models/dua.dart';
import '../services/display_settings.dart';
import '../services/favorites_service.dart';
import '../theme/app_theme.dart';
import '../theme/reading_theme.dart';
import '../util/arabic.dart';
import 'arabic_text.dart';
import 'ornament.dart';

/// One dua, set as a text block in a ruled frame.
///
/// The block follows the order a critical edition uses: heading, then the
/// Arabic, then the transliteration and translation, then the apparatus —
/// virtue, source, and the actions. Nothing that belongs to the apparatus is
/// allowed to sit above the text it annotates.
///
/// When [onCount] is provided the card enters "read & count" mode: the whole
/// card becomes a tap target that advances [count] toward the dua's repetition
/// target, and the head mark fills as the target is reached.
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
    // Arabic, translation, rules and paper all pick it up. `system` is a no-op.
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
    final ms = ManuscriptTheme.of(context);
    final display = context.watch<DisplaySettings>();
    final s = AppStrings.of(context);
    final showArabicTitle = s.ar && dua.titleArabic != null;
    final virtue = dua.virtueFor(s.lang.name);

    final card = Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: JadwalFrame(
        onTap: onCount,
        accent: _complete ? ms.gilt : null,
        emphasis: _complete,
        padding: const EdgeInsets.fromLTRB(16, 13, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Heading: the mark, the title, and the tally.
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Rosette(
                  size: 20,
                  color: _complete ? ms.gilt : ms.rubric,
                  lobes: 8,
                  filled: _complete,
                ),
                const SizedBox(width: 10),
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
                          style: theme.textTheme.titleMedium,
                        ),
                ),
                if (_counting) ...[
                  const SizedBox(width: 8),
                  Cartouche(
                    label: _complete
                        ? s.done
                        : '${count ?? 0} / ${dua.repeat}',
                    color: _complete ? ms.gilt : ms.rubric,
                    filled: _complete,
                  ),
                ] else if (dua.repeat > 1) ...[
                  const SizedBox(width: 8),
                  Cartouche(label: '×${dua.repeat}', color: ms.gilt),
                ],
              ],
            ),
            const SizedBox(height: 11),
            Container(height: Ms.hair, color: ms.rule),
            const SizedBox(height: 16),

            // The text itself.
            ArabicText(dua.arabic, block: true),

            if (display.showTransliteration) ...[
              const SizedBox(height: 14),
              Text(
                dua.transliteration,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: scheme.onSurfaceVariant,
                  height: 1.55,
                ),
              ),
            ],
            if (display.showTranslation) ...[
              const SizedBox(height: 10),
              Text(dua.translationFor(s.lang.name),
                  style: theme.textTheme.bodyLarge),
            ],

            // Apparatus.
            if (virtue != null) ...[
              const SizedBox(height: 16),
              _VirtueNote(text: virtue),
            ],
            const SizedBox(height: 14),
            _Colophon(
              reference: dua.reference,
              onCopy: () => _copy(context),
              onEdit: onEdit,
              onDelete: onDelete,
              duaId: dua.id,
            ),
          ],
        ),
      ),
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

/// The note on a dua's virtue, set the way a manuscript sets a gloss: smaller,
/// in the second ink, inside its own light rule — not hung off an accent bar.
class _VirtueNote extends StatelessWidget {
  const _VirtueNote({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ms = ManuscriptTheme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 11),
      decoration: BoxDecoration(
        color: ms.gilt.withValues(alpha: 0.06),
        border: Border.all(color: ms.gilt.withValues(alpha: 0.32)),
        borderRadius: BorderRadius.circular(Ms.rSmall),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Rosette(size: 14, color: ms.gilt, lobes: 6),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontStyle: FontStyle.italic,
                height: 1.45,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.88),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The foot of the block: the source on the left, the actions on the right —
/// the apparatus kept below the text rather than crowding its heading.
class _Colophon extends StatelessWidget {
  const _Colophon({
    required this.reference,
    required this.onCopy,
    required this.duaId,
    this.onEdit,
    this.onDelete,
  });

  final String reference;
  final VoidCallback onCopy;
  final String duaId;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ms = ManuscriptTheme.of(context);
    final s = AppStrings.of(context);
    final isFavorite = context.watch<FavoritesService>().isFavorite(duaId);

    return Column(
      children: [
        Container(height: Ms.hair, color: ms.rule),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: Text(
                reference,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall,
              ),
            ),
            const SizedBox(width: 6),
            _Action(
              icon: isFavorite ? Icons.bookmark : Icons.bookmark_border,
              tooltip: isFavorite ? s.removeBookmark : s.bookmark,
              color: isFavorite ? ms.gilt : null,
              onPressed: () => context.read<FavoritesService>().toggle(duaId),
            ),
            _Action(
              icon: Icons.content_copy_outlined,
              tooltip: s.copy,
              onPressed: onCopy,
            ),
            if (onEdit != null)
              _Action(
                icon: Icons.edit_outlined,
                tooltip: s.edit,
                onPressed: onEdit!,
              ),
            if (onDelete != null)
              _Action(
                icon: Icons.delete_outline,
                tooltip: s.deleteDua,
                color: theme.colorScheme.error,
                onPressed: onDelete!,
              ),
          ],
        ),
      ],
    );
  }
}

class _Action extends StatelessWidget {
  const _Action({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.color,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final Color? color;

  @override
  Widget build(BuildContext context) => IconButton(
        icon: Icon(icon, size: 19),
        color: color,
        tooltip: tooltip,
        visualDensity: VisualDensity.compact,
        constraints: const BoxConstraints.tightFor(width: 38, height: 38),
        padding: EdgeInsets.zero,
        onPressed: onPressed,
      );
}
