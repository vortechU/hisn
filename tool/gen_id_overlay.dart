// Throwaway generator: builds the Indonesian translation-overlay TEMPLATE from
// the base duas.json, with empty values to be filled from an authored source.
import 'dart:convert';
import 'dart:io';

void main() {
  final base = jsonDecode(File('assets/data/duas.json').readAsStringSync())
      as List<dynamic>;
  final out = <String, dynamic>{};
  for (final raw in base) {
    final dua = raw as Map<String, dynamic>;
    final entry = <String, String>{'translation': ''};
    if (dua.containsKey('virtue')) entry['virtue'] = '';
    out[dua['id'] as String] = entry;
  }
  const encoder = JsonEncoder.withIndent('  ');
  File('assets/data/duas.id.json').writeAsStringSync('${encoder.convert(out)}\n');
  stdout.writeln('Wrote ${out.length} entries to assets/data/duas.id.json');
}
