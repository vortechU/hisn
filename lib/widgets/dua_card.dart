import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../l10n/app_strings.dart';
import '../models/dua.dart';
import '../models/shareable.dart';
import '../screens/share_sheet.dart';
import '../services/display_settings.dart';
import '../services/favorites_service.dart';
import '../theme/app_theme.dart';
import '../theme/reading_theme.dart';
import '../util/arabic.dart';
import 'arabic_text.dart';
import 'dua_instruction.dart';
import 'ornament.dart';

/// One dua, set as a text block on a soft panel.
///
/// The block follows the order a critical edition uses: heading, then the
/// practical guidance when needed, the Arabic, then its transliteration and
/// translation, followed by the virtue, source, and actions.
///
/// In an Arabic interface the transliteration and translation drop out
/// regardless of the display settings: both exist to render the Arabic for
/// someone who can't read it, and the Arabic is already set above them.
///
/// When [onCount] is provided the card enters "read & count" mode: the whole
/// card becomes a tap target that advances [count] toward the dua's repetition
/// target, and the panel takes the lamp colour as the target is reached.
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
    // Same body the share sheet sends, so what is copied and what is shared
    // can't drift apart — including which rendering lines the language keeps.
    Clipboard.setData(ClipboardData(text: Shareable.dua(dua, lang).asText()));
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(AppStrings.read(context).duaCopied)),
      );
  }

  @override
  Widget build(BuildContext context) {
    // Apply the reading-surface tint (sepia / night) above the card so the
    // Arabic, translation, rules and paper all pick it up. `system` is a no-op.
    final reading = context.select<DisplaySettings, ReadingTheme>(
      (d) => d.readingTheme,
    );
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
    final showArabicTitle = s.rtl;
    final virtue = dua.virtueFor(s.lang.name);

    final instruction = dua.instructionFor(s.lang.name);

    final card = Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: JadwalFrame(
        onTap: onCount,
        accent: _complete ? ms.gilt : null,
        emphasis: _complete,
        padding: const EdgeInsets.fromLTRB(20, 16, 12, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Heading: the title and the tally.
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: showArabicTitle
                        ? ArabicText(
                            s.ar
                                ? stripHarakat(dua.titleForLang(s.lang.name))
                                : dua.titleForLang(s.lang.name),
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            textAlign: TextAlign.start,
                            height: 1.5,
                            maxLines: 2,
                          )
                        : Text(
                            dua.titleForLang(s.lang.name),
                            style: theme.textTheme.titleMedium,
                          ),
                  ),
                  if (_counting) ...[
                    const SizedBox(width: 10),
                    _Tally(
                      count: count ?? 0,
                      repeat: dua.repeat,
                      complete: _complete,
                    ),
                  ] else if (dua.repeat > 1) ...[
                    const SizedBox(width: 10),
                    Cartouche(label: '×${dua.repeat}', color: ms.rubric),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 18),

            Padding(
              padding: const EdgeInsetsDirectional.only(end: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (instruction != null && instruction.trim().isNotEmpty) ...[
                    DuaInstruction(text: instruction, arabic: s.rtl),
                    const SizedBox(height: 16),
                  ],

                  // The text itself.
                  ArabicText(dua.arabic, block: true),

                  if (display.showTransliteration && !s.ar) ...[
                    const SizedBox(height: 16),
                    Text(
                      dua.transliteration,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                        height: 1.6,
                      ),
                    ),
                  ],
                  if (display.showTranslation && !s.ar) ...[
                    const SizedBox(height: 12),
                    Text(
                      dua.translationFor(s.lang.name),
                      style: theme.textTheme.bodyLarge,
                    ),
                  ],

                  // Apparatus.
                  if (virtue != null) ...[
                    const SizedBox(height: 16),
                    _VirtueNote(text: virtue),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 10),
            _Colophon(
              reference: dua.referenceFor(s.lang.name),
              onCopy: () => _copy(context),
              onShare: () =>
                  showSharePreview(context, Shareable.dua(dua, s.lang.name)),
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
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(display.fontScale)),
      child: card,
    );
  }
}

/// The counter in a dua's heading, held at the width of its widest state.
///
/// "Done" and "7 / 10" are not the same size, and the title sits right
/// beside it in an [Expanded]: letting the counter resize as it fills takes
/// room away from the heading, which then wraps to a second line — the card
/// growing under the reader's thumb at the very moment they finish it. Both
/// ends it can reach are laid out here and never painted, so the box is as
/// wide as it will ever need to be from the first tap onwards.
class _Tally extends StatelessWidget {
  const _Tally({
    required this.count,
    required this.repeat,
    required this.complete,
  });

  final int count;
  final int repeat;
  final bool complete;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final ms = ManuscriptTheme.of(context);
    final tint = complete ? ms.gilt : ms.rubric;

    Widget sizer(String label) => Visibility(
      visible: false,
      maintainSize: true,
      maintainAnimation: true,
      maintainState: true,
      child: Cartouche(label: label, color: tint),
    );

    return Stack(
      alignment: Alignment.center,
      children: [
        sizer(s.done),
        // The longest the tally itself gets: the count never passes the target,
        // so it never carries more digits than this.
        sizer('$repeat / $repeat'),
        Cartouche(
          label: complete ? s.done : '$count / $repeat',
          color: tint,
          filled: complete,
        ),
      ],
    );
  }
}

/// The note on a dua's virtue: a warm, lamp-tinted aside under the text — set
/// apart by its fill, not hung off an accent bar.
class _VirtueNote extends StatelessWidget {
  const _VirtueNote({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ms = ManuscriptTheme.of(context);
    final dark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 13),
      decoration: BoxDecoration(
        color: ms.gilt.withValues(alpha: dark ? 0.14 : 0.09),
        borderRadius: BorderRadius.circular(Ms.rSmall + 4),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(Icons.auto_awesome_outlined, size: 17, color: ms.gilt),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(
                height: 1.5,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.86),
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
    required this.onShare,
    required this.duaId,
    this.onEdit,
    this.onDelete,
  });

  final String reference;
  final VoidCallback onCopy;
  final VoidCallback onShare;
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
        Row(
          children: [
            Expanded(
              child: Text(
                reference,
                style: theme.textTheme.bodySmall,
              ),
            ),
            const SizedBox(width: 6),
            _Action(
              icon: isFavorite ? Icons.bookmark : Icons.bookmark_border,
              tooltip: isFavorite ? s.removeBookmark : s.bookmark,
              color: isFavorite ? ms.rubric : null,
              onPressed: () => context.read<FavoritesService>().toggle(duaId),
            ),
            _Action(
              icon: Icons.content_copy_outlined,
              tooltip: s.copy,
              onPressed: onCopy,
            ),
            _Action(
              icon: Icons.ios_share,
              tooltip: s.share,
              onPressed: onShare,
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
    constraints: const BoxConstraints.tightFor(width: 44, height: 44),
    padding: EdgeInsets.zero,
    onPressed: onPressed,
  );
}
