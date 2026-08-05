import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';

/// About the app — name, version, and a short description.
class AboutSettingsScreen extends StatelessWidget {
  const AboutSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(s.secAbout)),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Hisn  ·  v$kAppVersion'),
            subtitle: Text(s.aboutBody, style: theme.textTheme.bodySmall),
            isThreeLine: true,
          ),
        ],
      ),
    );
  }
}
