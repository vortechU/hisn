import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dua_app/services/backup_io.dart';
import 'package:dua_app/services/backup_service.dart';

/// Arabic with harakat — every character is multi-byte in UTF-8, which is what
/// makes it the thing that breaks when an encoding is guessed rather than
/// applied.
const _arabic = 'أَسْتَغْفِرُ اللَّهَ الْعَظِيمَ الَّذِي لَا إِلَهَ إِلَّا هُوَ';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// A backup file holding a custom dua in Arabic, as bytes on disk.
  Future<List<int>> backupBytes() async {
    SharedPreferences.setMockInitialValues({
      'custom_duas': jsonEncode([
        {'id': 'mine', 'arabic': _arabic, 'title': 'حصن', 'reference': 'x'}
      ]),
      'app_language': 'ar',
    });
    final prefs = await SharedPreferences.getInstance();
    return const BackupService().encode(prefs, appVersion: '1.0.0');
  }

  test('Arabic survives a byte-backed file, as Android hands one back',
      () async {
    // The Android picker returns `XFile.fromData`, and cross_file's
    // readAsString takes a shortcut for those: it calls String.fromCharCodes
    // and ignores the encoding it was given, so every multi-byte character
    // came back as mojibake. This is that exact file.
    final file = XFile.fromData(
      Uint8List.fromList(await backupBytes()),
      mimeType: 'application/json',
      name: 'hisn-backup.json',
    );

    final (backup, error) = await const BackupIo().read(file);
    expect(error, isNull);
    expect(backup, isNotNull);

    final custom = backup!.values['custom_duas'] as String;
    expect(custom, contains(_arabic));
    // The signature of the old failure: UTF-8 bytes shown as Latin-1.
    expect(custom, isNot(contains('Ø')));
    expect(custom, isNot(contains('Ù')));

    final decoded = jsonDecode(custom) as List;
    expect((decoded.first as Map)['arabic'], _arabic);
    expect((decoded.first as Map)['title'], 'حصن');
  });

  test('a path-backed file decodes the same way', () async {
    // The other implementation cross_file can hand back. Both must agree, or
    // a backup would restore differently depending on where it was picked.
    final dir = await Directory.systemTemp.createTemp('hisn_backup_test');
    addTearDown(() => dir.delete(recursive: true));
    final path = '${dir.path}/hisn-backup.json';
    await File(path).writeAsBytes(await backupBytes());

    final (backup, error) = await const BackupIo().read(XFile(path));
    expect(error, isNull);
    expect(backup!.values['custom_duas'] as String, contains(_arabic));
  });

  test('a file that is not UTF-8 is refused, not silently mangled', () async {
    // 0xFF 0xFE is not valid UTF-8. The old shortcut could never throw, so a
    // picked image used to sail through and produce nonsense; now it is caught
    // and reported as what it is.
    final file = XFile.fromData(
      Uint8List.fromList([0xFF, 0xFE, 0x00, 0x01, 0x02]),
      name: 'photo.jpg',
    );
    final (backup, error) = await const BackupIo().read(file);
    expect(backup, isNull);
    expect(error, BackupError.malformed);
  });

  test('valid UTF-8 that is not a backup is told apart from broken bytes',
      () async {
    final file = XFile.fromData(
      Uint8List.fromList(utf8.encode('{"hello": "عالم"}')),
      name: 'other.json',
    );
    final (backup, error) = await const BackupIo().read(file);
    expect(backup, isNull);
    expect(error, BackupError.notABackup);
  });
}
