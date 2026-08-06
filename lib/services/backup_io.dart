import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' show Rect;

import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'backup_service.dart';

/// Moves backup files in and out of the app.
///
/// Kept apart from [BackupService] so the format — what a backup contains and
/// how it is written back — stays testable without a platform channel behind
/// it. This half is the part that needs a real device.
///
/// Android has no save-file dialog through `file_selector` (only `openFile` is
/// implemented there), so a backup leaves through the system share sheet
/// instead. That is the better fit anyway: it reaches Drive, Files, and
/// send-to-self in one step, where a save dialog only reaches local storage.
class BackupIo {
  const BackupIo({this.service = const BackupService()});

  final BackupService service;

  /// Builds the backup and hands it to the system share sheet.
  ///
  /// [origin] anchors the sheet's popover on iPad; it is ignored elsewhere.
  ///
  /// Returns true if the file reached somewhere, false if the user dismissed
  /// the sheet without choosing a destination.
  Future<bool> share(
    SharedPreferences prefs, {
    required String appVersion,
    Rect? origin,
  }) async {
    final now = DateTime.now();
    final name = service.fileName(now: now);
    final bytes = Uint8List.fromList(
      service.encode(prefs, appVersion: appVersion, now: now),
    );

    final result = await SharePlus.instance.share(
      ShareParams(
        files: [
          // From bytes rather than a path: share_plus stages the temp file
          // itself, which keeps `dart:io` out of this file so the web preview
          // still compiles.
          XFile.fromData(bytes, mimeType: 'application/json', name: name),
        ],
        // XFile.fromData drops the name on some platforms; this pins it.
        fileNameOverrides: [name],
        sharePositionOrigin: origin,
      ),
    );

    return result.status == ShareResultStatus.success;
  }

  /// Asks the user for a backup file and parses it.
  ///
  /// Returns `(null, null)` if the picker was dismissed.
  ///
  /// No type filter is applied. Android reports the MIME type of a file
  /// differently depending on where it came from — Drive, Downloads, a
  /// messaging app — and a filter that guesses wrong hides the very file the
  /// user is looking for. Better to accept anything and explain clearly when
  /// it isn't a backup, which [BackupService.parse] already does.
  Future<(Backup?, BackupError?)> pick() async {
    final file = await openFile();
    if (file == null) return (null, null);
    return read(file);
  }

  /// Decode an already-picked file and parse it.
  ///
  /// Split out from [pick] so the decoding can be tested against the kind of
  /// [XFile] the Android picker actually returns — a byte-backed one, which is
  /// where this went wrong before.
  @visibleForTesting
  Future<(Backup?, BackupError?)> read(XFile file) async {
    final String raw;
    try {
      // Bytes, then decode here — NOT `readAsString(encoding: utf8)`.
      //
      // On Android the picker hands back an `XFile.fromData`, and cross_file's
      // `readAsString` takes a shortcut for byte-backed files: it calls
      // `String.fromCharCodes`, which reads each byte as a UTF-16 code unit
      // and *silently ignores the encoding argument*. Every non-ASCII
      // character then comes back as mojibake — Arabic worst of all, since
      // none of it is ASCII. Decoding the bytes ourselves is the only way to
      // be sure which encoding was actually applied.
      raw = utf8.decode(await file.readAsBytes());
    } catch (_) {
      // Binary, or not UTF-8 — a picked image, say. (utf8.decode throws on
      // malformed input, which is the point: the shortcut above never could,
      // so a wrong file used to sail through and produce nonsense.)
      return (null, BackupError.malformed);
    }
    return service.parse(raw);
  }
}
