import 'dart:convert';

/// Decodes a content overlay without accepting malformed fields as translations.
/// Runtime loading can fall back; validation uses the same parser and fails.
Map<String, Map<String, String>> decodeContentOverlay(
  String raw, {
  required Set<String> allowedFields,
}) {
  final decoded = jsonDecode(raw);
  if (decoded is! Map<String, dynamic>) {
    throw const FormatException('Content overlay must be an object');
  }
  final result = <String, Map<String, String>>{};
  for (final entry in decoded.entries) {
    if (entry.key == '_meta') {
      if (entry.value is! Map) {
        throw const FormatException('Overlay metadata must be an object');
      }
      continue;
    }
    final fields = entry.value;
    if (fields is! Map<String, dynamic> || fields.isEmpty) {
      throw FormatException('Invalid overlay entry: ${entry.key}');
    }
    final values = <String, String>{};
    for (final field in fields.entries) {
      final value = field.value;
      if (!allowedFields.contains(field.key) ||
          value is! String ||
          value.trim().isEmpty) {
        throw FormatException(
          'Invalid overlay field: ${entry.key}.${field.key}',
        );
      }
      values[field.key] = value;
    }
    result[entry.key] = values;
  }
  return result;
}
