import 'package:flutter/material.dart';

/// A small uppercase section header used within the settings sub-screens.
class SettingsSectionHeader extends StatelessWidget {
  const SettingsSectionHeader(this.label, {super.key});
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        label.toUpperCase(),
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

/// A bottom-sheet single-choice picker (no deprecated Radio API).
Future<T?> showSettingsPicker<T>({
  required BuildContext context,
  required String title,
  required List<T> options,
  required T current,
  required String Function(T) labelOf,
  String Function(T)? hintOf,
}) {
  return showModalBottomSheet<T>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) {
      final theme = Theme.of(context);
      return SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(title, style: theme.textTheme.titleMedium),
                ),
              ),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: options.map((option) {
                    final isSelected = option == current;
                    return ListTile(
                      title: Text(labelOf(option)),
                      subtitle: hintOf != null ? Text(hintOf(option)) : null,
                      trailing: isSelected
                          ? Icon(Icons.check, color: theme.colorScheme.primary)
                          : null,
                      selected: isSelected,
                      onTap: () => Navigator.of(context).pop(option),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      );
    },
  );
}
