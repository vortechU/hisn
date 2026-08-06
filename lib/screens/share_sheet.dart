import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/shareable.dart';
import '../services/share_io.dart';
import '../theme/app_theme.dart';
import '../widgets/share_card.dart';

/// Shows the share preview for [passage].
Future<void> showSharePreview(
  BuildContext context,
  Shareable passage, {
  ShareIo io = const ShareIo(),
}) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => SharePreviewSheet(passage: passage, io: io),
    );

/// The card as it will be sent, above the two ways of sending it.
///
/// The preview is not decoration. Capture reads back what is actually on
/// screen, so showing the card first is what makes the image reliable — the
/// Arabic typeface is lazily loaded, and a card rasterised before its font
/// arrived would go out in the fallback face. By the time this is on screen
/// and a button has been pressed, it has painted.
///
/// Public so the layout harness can render it without driving a share sheet.
class SharePreviewSheet extends StatefulWidget {
  const SharePreviewSheet({
    super.key,
    required this.passage,
    this.io = const ShareIo(),
  });

  final Shareable passage;
  final ShareIo io;

  @override
  State<SharePreviewSheet> createState() => _SharePreviewSheetState();
}

class _SharePreviewSheetState extends State<SharePreviewSheet> {
  final GlobalKey _cardKey = GlobalKey();
  bool _busy = false;

  /// Run [action] with the buttons disabled, always re-enabling them.
  ///
  /// The `finally` is the point. A spinner that never stops is the worst
  /// failure this sheet can have — it looks like the app hung, and it hides
  /// whatever actually went wrong. Whatever throws, the buttons come back.
  Future<void> _guard(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _shareImage() => _guard(() async {
        final s = AppStrings.read(context);
        final messenger = ScaffoldMessenger.of(context);
        final navigator = Navigator.of(context);

        final (png, error) = await widget.io.capture(_cardKey);
        if (!mounted) return;

        if (png == null) {
          // Falling back to text rather than dead-ending: the passage is still
          // shareable, only the picture of it isn't.
          messenger
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(s.shareImageFailed(error!))));
          await widget.io.shareText(widget.passage);
          if (mounted) navigator.pop();
          return;
        }

        await widget.io.shareImage(png, passage: widget.passage);
        if (mounted) navigator.pop();
      });

  Future<void> _shareText() => _guard(() async {
        final navigator = Navigator.of(context);
        await widget.io.shareText(widget.passage);
        if (mounted) navigator.pop();
      });

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final media = MediaQuery.of(context);

    return SafeArea(
      child: ConstrainedBox(
        // Leave the sheet room to breathe on a short screen; the card scrolls
        // inside whatever is left.
        constraints: BoxConstraints(maxHeight: media.size.height * 0.85),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                    Ms.margin, 0, Ms.margin, Ms.margin),
                child: Center(
                  // The boundary wraps the card alone, so nothing of the
                  // sheet — padding, ground colour, drag handle — is caught
                  // in the image.
                  child: RepaintBoundary(
                    key: _cardKey,
                    child: ShareCard(passage: widget.passage),
                  ),
                ),
              ),
            ),
            const RuleDividerSpacer(),
            Padding(
              padding: const EdgeInsets.fromLTRB(Ms.margin, 4, Ms.margin, 12),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _busy ? null : _shareText,
                      icon: const Icon(Icons.notes_outlined, size: 18),
                      label: Text(s.shareAsText),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _busy ? null : _shareImage,
                      icon: _busy
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.image_outlined, size: 18),
                      label: Text(s.shareAsImage),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A hairline between the preview and its actions.
class RuleDividerSpacer extends StatelessWidget {
  const RuleDividerSpacer({super.key});

  @override
  Widget build(BuildContext context) => Container(
        height: Ms.hair,
        color: ManuscriptTheme.of(context).rule,
      );
}
