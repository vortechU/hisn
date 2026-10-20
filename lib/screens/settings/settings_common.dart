import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../widgets/ornament.dart';

/// The section header used within the settings sub-screens — the same heading
/// the rest of the app uses, so settings don't drift into their own visual
/// dialect.
class SettingsSectionHeader extends StatelessWidget {
  const SettingsSectionHeader(this.label, {super.key});
  final String label;

  @override
  Widget build(BuildContext context) => SectionMark(label: label);
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
      final ms = ManuscriptTheme.of(context);
      return SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(Ms.margin + 4, 0, Ms.margin, 10),
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(title, style: theme.textTheme.titleLarge),
                ),
              ),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  children: options.map((option) {
                    final isSelected = option == current;
                    return ListTile(
                      title: Text(labelOf(option)),
                      subtitle: hintOf != null ? Text(hintOf(option)) : null,
                      trailing: isSelected
                          ? Icon(Icons.check_rounded, color: ms.rubric)
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
