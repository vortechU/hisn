import 'package:flutter/material.dart';

import 'arabic_text.dart';

/// Practical guidance kept separate from both the recitation and its virtue.
class DuaInstruction extends StatelessWidget {
  const DuaInstruction({super.key, required this.text, required this.arabic});

  final String text;
  final bool arabic;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return arabic
        ? ArabicText(
            text,
            block: true,
            fontSize: 17,
            height: 1.65,
            color: theme.colorScheme.onSurfaceVariant,
          )
        : Text(
            text,
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.55,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          );
  }
}
