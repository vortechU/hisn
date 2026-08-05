import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/display_settings.dart';

/// Renders Arabic script using the user's chosen Arabic font (Display
/// settings), forced right-to-left and with generous line height so harakat
/// (diacritics) aren't clipped.
class ArabicText extends StatelessWidget {
  const ArabicText(
    this.text, {
    super.key,
    this.fontSize = 26,
    this.color,
    this.fontWeight = FontWeight.w400,
    this.textAlign = TextAlign.right,
    this.height = 1.9,
    this.maxLines,
    this.block = false,
  });

  final String text;
  final double fontSize;
  final Color? color;
  final FontWeight fontWeight;
  final TextAlign textAlign;
  final double height;

  /// When set, the text is clipped to this many lines with an ellipsis.
  final int? maxLines;

  /// When true, the text fills the available width so [textAlign] (right)
  /// actually anchors short lines (e.g. "الله أكبر") to the right edge instead
  /// of leaving them at the start. Don't use inside a [FittedBox].
  final bool block;

  @override
  Widget build(BuildContext context) {
    final family =
        context.select<DisplaySettings, String>((d) => d.arabicFontFamily);
    final widget = Text(
      text,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: maxLines == null ? null : TextOverflow.ellipsis,
      style: TextStyle(
        fontFamily: family,
        fontSize: fontSize,
        fontWeight: fontWeight,
        height: height,
        color: color ?? Theme.of(context).colorScheme.onSurface,
      ),
    );
    return Directionality(
      textDirection: TextDirection.rtl,
      child: block ? SizedBox(width: double.infinity, child: widget) : widget,
    );
  }
}
