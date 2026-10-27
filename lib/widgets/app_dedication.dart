import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'arabic_text.dart';

/// The family's dedication, kept in its original Arabic in every language.
class AppDedication extends StatelessWidget {
  const AppDedication({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Ms.margin, vertical: 24),
      child: ArabicText(
        'صدقة جارية عن روح جدِّي سعيد المرقطن',
        fontSize: 18,
        height: 1.8,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        textAlign: TextAlign.center,
        block: true,
      ),
    );
  }
}
