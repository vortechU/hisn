import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_strings.dart';
import '../models/dua.dart';
import '../services/custom_dua_service.dart';
import '../services/display_settings.dart';

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
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            // Arabic — required, RTL, larger.
            TextFormField(
              controller: _arabic,
              autofocus: true,
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.right,
              minLines: 2,
              maxLines: 6,
              style: TextStyle(
                fontFamily: arabicFamily,
                fontSize: 22,
                height: 1.8,
              ),
              decoration: InputDecoration(
                labelText: s.fieldArabic,
                alignLabelWithHint: true,
                border: const OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? s.fieldArabicRequired : null,
            ),
            const SizedBox(height: 16),
            _field(_title, s.fieldTitle),
            const SizedBox(height: 16),
            _field(_transliteration, s.fieldTransliteration),
            const SizedBox(height: 16),
            _field(_translation, s.fieldTranslation, maxLines: 3),
            const SizedBox(height: 16),
            _field(_reference, s.fieldReference),
            const SizedBox(height: 20),
            // Repetitions stepper.
            Row(
              children: [
                Expanded(
                  child: Text(s.fieldRepeat,
                      style: theme.textTheme.bodyLarge),
                ),
                IconButton.outlined(
                  onPressed: _repeat > 1
                      ? () => setState(() => _repeat--)
                      : null,
                  icon: const Icon(Icons.remove),
                  tooltip: '−',
                ),
                SizedBox(
                  width: 48,
                  child: Text(
                    '$_repeat',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleLarge,
                  ),
                ),
                IconButton.outlined(
                  onPressed: _repeat < 1000
                      ? () => setState(() => _repeat++)
                      : null,
                  icon: const Icon(Icons.add),
                  tooltip: '+',
                ),
              ],
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: const Icon(Icons.check),
              label: Text(s.save),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(TextEditingController c, String label, {int maxLines = 1}) {
    return TextFormField(
      controller: c,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }
}
