import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../l10n/app_strings.dart';
import '../models/dua.dart';
import '../services/custom_dua_service.dart';
import '../services/display_settings.dart';
import '../theme/app_theme.dart';

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
  final _repeatInput = TextEditingController(text: '1');
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
      _reference.text = dua.reference == _defaultPlaceholder
          ? ''
          : dua.reference;
      _repeatInput.text = dua.repeat.toString();
    }
  }

  @override
  void dispose() {
    _arabic.dispose();
    _title.dispose();
    _transliteration.dispose();
    _translation.dispose();
    _reference.dispose();
    _repeatInput.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final repeat = _parseRepeat(_repeatInput.text)!;
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
        repeat: repeat,
      );
    } else {
      await service.add(
        arabic: _arabic.text,
        title: _title.text,
        transliteration: _transliteration.text,
        translation: _translation.text,
        reference: _reference.text,
        repeat: repeat,
      );
    }
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final theme = Theme.of(context);
    final arabicFamily = context.select<DisplaySettings, String>(
      (d) => d.arabicFontFamily,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? s.editDua : s.newDua),
        actions: [
          TextButton(onPressed: _saving ? null : _save, child: Text(s.save)),
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
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? s.fieldArabicRequired
                  : null,
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
              style: theme.textTheme.bodyLarge?.copyWith(
                fontStyle: FontStyle.italic,
              ),
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
              controller: _repeatInput,
              label: s.fieldRepeat,
              onChanged: () => setState(() {}),
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
        Flexible(
          child: Text(text.toUpperCase(), style: theme.textTheme.labelSmall),
        ),
        if (required) ...[
          const SizedBox(width: 4),
          Text(
            '*',
            style: theme.textTheme.labelSmall?.copyWith(color: ms.rubric),
          ),
        ],
      ],
    );
  }
}

/// Parse Western, Arabic-Indic and Persian digits without changing the input.
int? _parseRepeat(String text) {
  if (!RegExp(r'^[0-9٠-٩۰-۹]+$').hasMatch(text)) return null;
  final normalized = String.fromCharCodes(
    text.runes.map((code) {
      if (code >= 0x0660 && code <= 0x0669) return code - 0x0660 + 0x30;
      if (code >= 0x06f0 && code <= 0x06f9) return code - 0x06f0 + 0x30;
      return code;
    }),
  );
  final value = int.tryParse(normalized);
  return value != null && value >= 1 ? value : null;
}

/// Direct numeric entry for large targets, with steppers for small adjustments.
class _RepeatStepper extends StatelessWidget {
  const _RepeatStepper({
    required this.controller,
    required this.label,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ms = ManuscriptTheme.of(context);
    final s = AppStrings.of(context);
    final value = _parseRepeat(controller.text);

    void step(int next) {
      controller.value = TextEditingValue(
        text: '$next',
        selection: TextSelection.collapsed(offset: '$next'.length),
      );
      onChanged();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Label(label),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IconButton(
              key: const ValueKey('custom_repeat_decrement'),
              tooltip: '$label: −1',
              color: ms.rubric,
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              onPressed: value != null && value > 1
                  ? () => step(value - 1)
                  : null,
              icon: const Icon(Icons.remove),
            ),
            Expanded(
              child: TextFormField(
                key: const ValueKey('custom_repeat_count'),
                controller: controller,
                keyboardType: TextInputType.number,
                textDirection: TextDirection.ltr,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium,
                decoration: InputDecoration(hintText: '1', errorMaxLines: 2),
                autovalidateMode: AutovalidateMode.onUserInteraction,
                inputFormatters: [
                  TextInputFormatter.withFunction(
                    (oldValue, newValue) =>
                        RegExp(r'^[0-9٠-٩۰-۹]*$').hasMatch(newValue.text)
                        ? newValue
                        : oldValue,
                  ),
                ],
                validator: (text) => _parseRepeat(text ?? '') == null
                    ? s.fieldRepeatPositiveRequired
                    : null,
                onChanged: (_) => onChanged(),
              ),
            ),
            IconButton(
              key: const ValueKey('custom_repeat_increment'),
              tooltip: '$label: +1',
              color: ms.rubric,
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              onPressed: () => step((value ?? 0) + 1),
              icon: const Icon(Icons.add),
            ),
          ],
        ),
      ],
    );
  }
}
