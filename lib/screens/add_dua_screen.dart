import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_strings.dart';
import '../models/dua.dart';
import '../services/custom_dua_service.dart';
import '../services/display_settings.dart';
import '../theme/app_theme.dart';
import '../widgets/ornament.dart';

/// A form for adding — or, when [existing] is provided, editing — a custom dua.
/// Only the Arabic text is required.
class AddDuaScreen extends StatefulWidget {
  const AddDuaScreen({super.key, this.existing});

  /// The dua being edited, or null when creating a new one.
  final Dua? existing;

  @override
  State<AddDuaScreen> createState() => _AddDuaScreenState();
}

class _AddDuaScreenState extends State<AddDuaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _arabic = TextEditingController();
  final _title = TextEditingController();
  final _transliteration = TextEditingController();
  final _translation = TextEditingController();
  final _reference = TextEditingController();
  int _repeat = 1;
  bool _saving = false;

  bool get _isEditing => widget.existing != null;

  // The defaults [CustomDuaService] substitutes for empty fields — shown back as
  // blank so the user edits their own text, not a placeholder.
  static const _defaultPlaceholder = 'My dua';

  @override
  void initState() {
    super.initState();
    final dua = widget.existing;
    if (dua != null) {
      _arabic.text = dua.arabic;
      _title.text = dua.title == _defaultPlaceholder ? '' : dua.title;
      _transliteration.text = dua.transliteration;
      _translation.text = dua.translation;
      _reference.text =
          dua.reference == _defaultPlaceholder ? '' : dua.reference;
      _repeat = dua.repeat;
    }
  }

  @override
  void dispose() {
    _arabic.dispose();
    _title.dispose();
    _transliteration.dispose();
    _translation.dispose();
    _reference.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final service = context.read<CustomDuaService>();
    if (_isEditing) {
      await service.update(
        id: widget.existing!.id,
        arabic: _arabic.text,
        title: _title.text,
        transliteration: _transliteration.text,
        translation: _translation.text,
        reference: _reference.text,
        repeat: _repeat,
      );
    } else {
      await service.add(
        arabic: _arabic.text,
        title: _title.text,
        transliteration: _transliteration.text,
        translation: _translation.text,
        reference: _reference.text,
        repeat: _repeat,
      );
    }
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final theme = Theme.of(context);
    final arabicFamily =
        context.select<DisplaySettings, String>((d) => d.arabicFontFamily);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? s.editDua : s.newDua),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: Text(s.save),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(Ms.margin, 4, Ms.margin, 34),
          children: [
            // The Arabic is the dua; everything else annotates it. So it gets
            // the framed block and the rest are plain fields beneath.
            _Label(s.fieldArabic, required: true),
            const SizedBox(height: 6),
            TextFormField(
              controller: _arabic,
              autofocus: true,
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.right,
              minLines: 2,
              maxLines: 6,
              style: TextStyle(
                fontFamily: arabicFamily,
                fontSize: 23,
                height: 1.85,
                color: theme.colorScheme.onSurface,
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? s.fieldArabicRequired : null,
            ),
            const SizedBox(height: 18),
            _Label(s.fieldTitle),
            const SizedBox(height: 6),
            TextFormField(controller: _title),
            const SizedBox(height: 18),
            _Label(s.fieldTransliteration),
            const SizedBox(height: 6),
            TextFormField(
              controller: _transliteration,
              style: theme.textTheme.bodyLarge
                  ?.copyWith(fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 18),
            _Label(s.fieldTranslation),
            const SizedBox(height: 6),
            TextFormField(controller: _translation, maxLines: 3),
            const SizedBox(height: 18),
            _Label(s.fieldReference),
            const SizedBox(height: 6),
            TextFormField(controller: _reference),
            const SizedBox(height: 22),
            _RepeatStepper(
              value: _repeat,
              label: s.fieldRepeat,
              onChanged: (v) => setState(() => _repeat = v),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: const Icon(Icons.check, size: 18),
              label: Text(s.save),
            ),
          ],
        ),
      ),
    );
  }
}

/// A field label in the apparatus face, with the required marker as a rubric
/// asterisk rather than as a colour-only cue.
class _Label extends StatelessWidget {
  const _Label(this.text, {this.required = false});

  final String text;
  final bool required;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ms = ManuscriptTheme.of(context);
    return Row(
      children: [
        Text(text.toUpperCase(), style: theme.textTheme.labelSmall),
        if (required) ...[
          const SizedBox(width: 4),
          Text('*',
              style: theme.textTheme.labelSmall?.copyWith(color: ms.rubric)),
        ],
      ],
    );
  }
}

/// The repetition count, as a numeral between two ruled steppers.
class _RepeatStepper extends StatelessWidget {
  const _RepeatStepper({
    required this.value,
    required this.label,
    required this.onChanged,
  });

  final int value;
  final String label;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ms = ManuscriptTheme.of(context);

    Widget step(IconData icon, String tooltip, VoidCallback? onTap) => Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onTap,
            child: Tooltip(
              message: tooltip,
              child: SizedBox(
                width: 44,
                height: 44,
                child: Icon(
                  icon,
                  size: 19,
                  color: onTap == null
                      ? theme.colorScheme.onSurfaceVariant
                          .withValues(alpha: 0.4)
                      : ms.rubric,
                ),
              ),
            ),
          ),
        );

    return Row(
      children: [
        Expanded(
          child: Text(label.toUpperCase(), style: theme.textTheme.labelSmall),
        ),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: ms.rule),
            borderRadius: BorderRadius.circular(Ms.rSmall),
          ),
          clipBehavior: Clip.antiAlias,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                step(Icons.remove, '−',
                    value > 1 ? () => onChanged(value - 1) : null),
                VerticalDivider(width: 1, color: ms.rule),
                SizedBox(
                  width: 56,
                  child: Center(child: Numeral('$value', size: 19)),
                ),
                VerticalDivider(width: 1, color: ms.rule),
                step(Icons.add, '+',
                    value < 1000 ? () => onChanged(value + 1) : null),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
