import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../widgets/ornament.dart';

/// The section header used within the settings sub-screens — the same ruled
/// mark the rest of the app uses, so settings don't drift into their own
/// visual dialect.
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
                padding: const EdgeInsets.fromLTRB(Ms.margin, 0, Ms.margin, 4),
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(title, style: theme.textTheme.titleMedium),
                ),
              ),
              const RuleDivider(indent: Ms.margin),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: options.map((option) {
                    final isSelected = option == current;
                    return Container(
                      decoration: BoxDecoration(
                        border: Border(bottom: BorderSide(color: ms.rule)),
                      ),
                      child: ListTile(
                        title: Text(labelOf(option)),
                        subtitle: hintOf != null ? Text(hintOf(option)) : null,
                        leading: SizedBox(
                          width: 20,
                          child: isSelected
                              ? Rosette(
                                  size: 16, color: ms.gilt, filled: true)
                              : null,
                        ),
                        selected: isSelected,
                        onTap: () => Navigator.of(context).pop(option),
                      ),
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
